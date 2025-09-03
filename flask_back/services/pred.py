import os
import pandas as pd
from datetime import datetime, timedelta
import requests
import openmeteo_requests
import requests_cache
from retry_requests import retry
import joblib
from pathlib import Path
from sklearn.preprocessing import LabelEncoder
class ShiftCreator:
    """
    This class handles the prediction of daily sales and staff levels
    based on input date range, weather forecast, and festival data.
    """

    def __init__(self, start_date, end_date,  date_format="%Y-%m-%d"):
        self.start_date = start_date
        self.end_date = end_date
        self.date_format = date_format
        self.latitude = 52.52
        self.longitude = 13.41

        base_dir = os.path.dirname(os.path.abspath(__file__))  # /flask_back/services/
        self.data_path = os.path.normpath(os.path.join(base_dir, '..', '..', 'data', 'project2.csv'))
        # 正しい修正
        self.model_dir = os.path.normpath(os.path.join(base_dir, '..', '..', 'model'))

# 個別ファイルのパス
        self.sales_model_path = os.path.join(self.model_dir, 'sales_model0_1.pkl')
        self.season_encoder_path = os.path.join(self.model_dir, 'season_encoder.pkl')
        self.staff_model_path = os.path.join(self.model_dir, 'staff.pkl')


    def date_data_from_user(self):
        """Convert user input strings to Python datetime.date objects."""
        try:
            # datetime.strptime() で datetime オブジェクトを作成
            start_dt = datetime.strptime(self.start_date, self.date_format)
            end_dt = datetime.strptime(self.end_date, self.date_format)

            # datetime.date() で date オブジェクトに変換
            start_date_obj = start_dt.date()
            end_date_obj = end_dt.date()

            # timedelta(days=1) を使って1日加算
            start = start_date_obj + timedelta(days=0)
            end = end_date_obj + timedelta(days=0)
            #start_wea = start_date_obj + timedelta(days=1)
            #end_wea = start_date_obj + timedelta(day=1)
            print(start, end)
            
            return start, end 
        except ValueError as e:
            print("Date parsing error:", e)
            return None, None

    def get_festival_days(self):
        """Load festival dates from CSV and return set of 'MM-DD' strings."""
        file_path = self.data_path
        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Festival CSV not found at {file_path}")
        festival_data = pd.read_csv(file_path)
        festival_data['month_day'] = pd.to_datetime(festival_data['date']).dt.strftime("%m-%d")
        festival_md = festival_data[festival_data['is_festival'] == True]['month_day'].tolist()
        return set(festival_md)

    def check_festival_range(self, start, end):
        """Return list of 1/0 indicating if each day in the range is a festival."""
        festival_md_set = self.get_festival_days()
        current = start
        is_festival = []
        while current <= end:
            md = current.strftime("%m-%d")
            is_festival.append(1 if md in festival_md_set else 0)
            current += timedelta(days=1)
        print(is_festival)
        return is_festival

    def weather_data(self,start,end):
        """Fetch weather data using Open-Meteo API."""
        cache_session = requests_cache.CachedSession('.cache', expire_after=3600)
        retry_session = retry(cache_session, retries=5, backoff_factor=0.2)
        openmeteo = openmeteo_requests.Client(session=retry_session)
        #start,end = ShiftCreator.date_data_from_user()
        
        url = "https://api.open-meteo.com/v1/forecast"
        params = {
            "latitude": self.latitude,
            "longitude": self.longitude,
            "daily": ["rain_sum", "snowfall_sum", "weather_code", "temperature_2m_max"],
            "timezone": "Asia/Tokyo",
            "start_date": start,
            "end_date": end
        }

        responses = openmeteo.weather_api(url, params=params)
        if not responses:
            print("No data returned from Open-Meteo")
            return pd.DataFrame()

        response = responses[0]
        daily = response.Daily()
        daily_data = {
            "date": pd.date_range(
                start=pd.to_datetime(daily.Time(), unit="s", utc=True),
                end=pd.to_datetime(daily.TimeEnd(), unit="s", utc=True),
                freq=pd.Timedelta(seconds=daily.Interval()),
                inclusive="left"
            ),
            "rain_sum": daily.Variables(0).ValuesAsNumpy(),
            "snowfall_sum": daily.Variables(1).ValuesAsNumpy(),
            "weather_code": daily.Variables(2).ValuesAsNumpy(),
            "temperature": daily.Variables(3).ValuesAsNumpy()
        }

        df = pd.DataFrame(data=daily_data)
        df["date"] = df["date"].dt.tz_localize(None)  # Remove timezone
        df["date"]=df["date"].dt.normalize()
        print(df)
        return df

    def pred_from_model(self, start, end, is_festival, weather_df):
        """Predict sales using trained ML model and merged features."""
        date_range = pd.date_range(start=start, end=end)
        df = pd.DataFrame({
            "date": date_range,
            "is_festival": is_festival
        })

        df["weekday"] = df["date"].dt.weekday
        df["month"] = df["date"].dt.month
        df["day"] = df["date"].dt.day
        df["year"] = df["date"].dt.isocalendar().year
        df["weekofyear"] = df["date"].dt.isocalendar().week

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
        #print("data type of weather date",weather_df[weather_df["date"]].info())
        # Load season encoder safely
        season_encoder_path = self.season_encoder_path
        
        season_encoder = joblib.load(season_encoder_path)
        
        df["season"] = season_encoder.transform(df["season"])
        
        # Merge with weather
        df = df.merge(weather_df, on="date",how="left")
        print("学習する前のデータ")
        print(df)
        features = [
            "weekday", "month", "is_festival", "season",
            "weather_code", "temperature", "snowfall_sum", "rain_sum",
            "year", "day", "weekofyear"
        ]
        model_input = df[features]
        print("model_input")
        print(model_input)
        sales_model_path = self.sales_model_path 
        if not os.path.exists(sales_model_path):
            raise FileNotFoundError(f"Sales model not found at {sales_model_path}")
        try:
            model = joblib.load(sales_model_path)
        except FileNotFoundError as e:
            print(e)
        df["predicted_sales"] = model.predict(model_input)
        try:
            base_dir = Path(__file__).resolve().parent             
            data_dir = (base_dir / "../../data/data_for_dashboard").resolve()          
            data_dir.mkdir(parents=True, exist_ok=True)

            out_path = data_dir / "predicted_sales.csv" 

            
            df[["date","predicted_sales"]].to_csv(out_path, index=False)    
               
        except Exception as e:
            print(f"Failed to save CSV: {e}")
        
        
        print(df[["date", "predicted_sales"]])
        return df[["date", "predicted_sales"]]

    def pred_staff_count(self, sales_preds):
        """Predict required staff level from predicted sales using trained model."""
        staff_model_path = os.path.join(self.model_dir, 'staff.pkl')
        if not os.path.exists(staff_model_path):
            raise FileNotFoundError(f"Staff model not found at {staff_model_path}")
        model = joblib.load(staff_model_path)

        input_df = sales_preds[["predicted_sales"]].rename(columns={"predicted_sales": "sales"})
        staff_levels = model.predict(input_df)
        sales_preds["predicted_staff_level"] = staff_levels
        

        print(sales_preds[["date", "predicted_sales", "predicted_staff_level"]])
        return sales_preds[["date", "predicted_sales", "predicted_staff_level"]]
