from sqlalchemy.orm import Session
from ..models.pred_sales_model import Pred_sales
from ..utils.db import get_db



from datetime import datetime, timedelta
import os
import json
import pandas as pd
import requests_cache
from openmeteo_requests import Client
from retry_requests import retry
import joblib

class DataPrepare:

    def __init__(self, start_date, end_date, date_format="%Y-%m-%d"):
        self.start_date = start_date
        self.end_date = end_date
        self.date_format = date_format

    
        self.latitude = 35.6895
        self.longitude = 139.6917

    # =====================
    # date properties
    # =====================
    @property
    def start_date_obj(self):
        try:
            return datetime.strptime(self.start_date, self.date_format).date() 
        except ValueError as e:
            raise ValueError(
                f"start_date format error: {self.start_date} (expected {self.date_format})"
            ) from e

    @property
    def end_date_obj(self):
        try:
            return datetime.strptime(self.end_date, self.date_format).date()
        except ValueError as e:
            raise ValueError(
                f"end_date format error: {self.end_date} (expected {self.date_format})"
            ) from e

    @property
    def file_path(self):
        try:
            return os.path.dirname(os.path.abspath(__file__))
        except NameError:
            return os.getcwd()

    # =====================
    # festival
    # =====================
    @property
    def festival_md_set(self):
        data_dir = os.path.normpath(os.path.join(self.file_path, "../data"))
        fes_path = os.path.join(data_dir, "festival_date.json")

        if not os.path.exists(fes_path):
            raise FileNotFoundError(f"{fes_path} not found")

        with open(fes_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # {"date": ["4-20", "5-9", ...]}
        return set(data["date"])

    def check_festival_range(self):
        current = self.start_date_obj
        end = self.end_date_obj

        result = []
        while current <= end:
            md = current.strftime("%m-%d")
            result.append(1 if md in self.festival_md_set else 0)
            current += timedelta(days=1)

        return result

  
    def weather_data(self):
        cache_session = requests_cache.CachedSession(".cache", expire_after=3600)
        retry_session = retry(cache_session, retries=5, backoff_factor=0.2)
        openmeteo = Client(session=retry_session)
        start = self.start_date_obj + timedelta(days=1)
        end  = self.end_date_obj+ timedelta(days=1)
        params = {
            "latitude": self.latitude,
            "longitude": self.longitude,
            "daily": [
                "rain_sum",
                "snowfall_sum",
                "weather_code",
                "temperature_2m_max",
            ],
            "timezone": "Asia/Tokyo",
            "start_date": start.strftime("%Y-%m-%d")  ,
            "end_date": end.strftime("%Y-%m-%d") 
        }
        print("params")
        print(params)
        responses = openmeteo.weather_api(
            "https://api.open-meteo.com/v1/forecast", params=params
        )
        if not responses:
            return pd.DataFrame()

        daily = responses[0].Daily()

        df = pd.DataFrame({
            "date": pd.date_range(
                start=pd.to_datetime(daily.Time(), unit="s", utc=True),
                periods=len(daily.Variables(0).ValuesAsNumpy()),
                freq=pd.Timedelta(seconds=daily.Interval()),
            ).tz_localize(None),
            "rain": daily.Variables(0).ValuesAsNumpy(),
            "snowfall": daily.Variables(1).ValuesAsNumpy(),
            "temperature": daily.Variables(3).ValuesAsNumpy(),
            "weather": [
                self.weather_code_to_str(c)
                for c in daily.Variables(2).ValuesAsNumpy()
            ],
        })
        print("weather")
        print(df)
        return df

    @staticmethod
    def weather_code_to_str(code):
        if 0 <= code < 25:
            return "Sunny"
        elif 25 <= code < 65:
            return "Cloudy"
        elif 65 <= code < 80:
            return "Rainy"
        else:
            return "Snowy"
        
        
    def pred_from_model(self,is_festival, weather_df):
        """Predict sales using trained ML model and merged features."""
        
        date_range = pd.date_range(
            
            start=self.start_date_obj,
            end=self.end_date_obj
        )

        df = pd.DataFrame({
            "date": date_range,
            "festival": is_festival
        })

        df["weekday"] = df["date"].dt.day_name()
        df["month"] = df["date"].dt.month
        df["day"] = df["date"].dt.day

        def assign_season(month):
            if month in [12, 1, 2]:
                return "winter"
            elif month in [3, 4, 5]:
                return "spring"
            elif month in [6, 7, 8]:
                return "summer"
            else:
                return "autumn"

        df["season"] = df["month"].apply(assign_season)

        # Load season encoder safely
        #season_encoder_path = os.path.join(self.model_dir, 'xgb_season_encoder.pkl')
        #if not os.path.exists(season_encoder_path):
        #    raise FileNotFoundError(f"Season encoder not found at {season_encoder_path}")
        #season_encoder = joblib.load(season_encoder_path)
        #df["season"] = season_encoder.transform(df["season"])
        df["date"] = df["date"].dt.date
        weather_df["date"] = weather_df["date"].dt.date
        # Merge with weather
        df = df.merge(weather_df, on="date", how="left")
        print("Merged DataFrame for prediction:")
        print(df)
        features = [
            "month", "day", "weekday", "temperature", "rain","weather","festival","season"
        ]
        model_input = df[features]
        print("Model input features:")
        print(model_input)
        data_dir = os.path.normpath(os.path.join(self.file_path, "../data"))
        model_path = os.path.join(data_dir, "xgb_sales_model.joblib")
        
        model = joblib.load(model_path)
        if not os.path.exists(model_path):
            raise FileNotFoundError(f"Sales model not found at {model}")
       

        df["predicted_sales"] = model.predict(model_input)
        result = df[["date", "predicted_sales"]].to_dict(orient="records")

        print(result)
        return result

    def run_prediction(self):
        is_festival = self.check_festival_range()
        weather_df = self.weather_data()
        result = self.pred_from_model(is_festival, weather_df)
        self.save_pred_sales(result)
        return result

    def save_pred_sales(self, result):
        db: Session = next(get_db())

        for row in result:
            existing = (
                db.query(Pred_sales)
                .filter(Pred_sales.date == row["date"])
                .first()
            )

            if existing:
                existing.pred_sales = row["predicted_sales"]
            else:
                db.add(Pred_sales(
                    date=row["date"],
                    pred_sales=row["predicted_sales"]
                ))

        db.commit()



        
class GetPred:
    def get_one_week_pred(start,end):
        db:Session = next(get_db())
        
        return (
            db.query(Pred_sales)
            .filter(Pred_sales.date.between(start, end))
            .distinct(Pred_sales.date)
            .order_by(Pred_sales.date)
            .all()
            )
    
    def get_all_pred():
        db:Session = next(get_db())
        
        db.query(Pred_sales).all()
