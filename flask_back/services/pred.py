import pandas as pd
from datetime import datetime, timedelta
import requests
import openmeteo_requests
import requests_cache
from retry_requests import retry
import joblib


class ShiftCreator:
    def __init__(self, start_date, end_date, latitude, longitude, date_format="%Y-%m-%d"):
        self.start_date = start_date
        self.end_date = end_date
        self.date_format = date_format
        self.latitude = latitude
        self.longitude = longitude

    def date_data_from_user(self):
        try:
            start = datetime.strptime(self.start_date, self.date_format).date()
            end = datetime.strptime(self.end_date, self.date_format).date()
            print(start,end)
            return start, end
        
        except ValueError as e:
            print("error", e)
            return None, None

    def get_festival_days(self):
        file_path = "data/project.csv"
        festival_data = pd.read_csv(file_path)
        festival_data['month_day'] = pd.to_datetime(festival_data['date']).dt.strftime("%m-%d")
        festival_md = festival_data[festival_data['is_festival'] == True]['month_day'].tolist()
        
        return set(festival_md)

    def check_festival_range(self, start, end):
        festival_md_set = self.get_festival_days()
        current = start
        is_festival = []
        while current <= end:
            md = current.strftime("%m-%d")
            if md in festival_md_set:
                is_festival.append(1)
            else:
                is_festival.append(0)
            current += timedelta(days=1)
        print(is_festival)
        return is_festival

    def weather_data(self,start,end):
        cache_session = requests_cache.CachedSession('.cache', expire_after=3600)
        retry_session = retry(cache_session, retries=5, backoff_factor=0.2)
        openmeteo = openmeteo_requests.Client(session=retry_session)

        url = "https://api.open-meteo.com/v1/forecast"
        params = {
            "latitude": self.latitude,
            "longitude": self.longitude,
            "daily": ["rain_sum", "snowfall_sum", "weather_code", "temperature_2m_max"],
            "timezone": "Asia/Tokyo",
            "start_date": start.strftime("%Y-%m-%d"),
            "end_date": end.strftime("%Y-%m-%d")
        }

        responses = openmeteo.weather_api(url, params=params)
        if not responses:
            print("⚠️ Open-Meteoからデータが返ってきませんでした")
            print("パラメータ:", params)
            return pd.DataFrame()
        response = responses[0]

        daily = response.Daily()
        daily_rain_sum = daily.Variables(0).ValuesAsNumpy()
        daily_snowfall_sum = daily.Variables(1).ValuesAsNumpy()
        daily_weather_code = daily.Variables(2).ValuesAsNumpy()
        daily_temperature_2m_max = daily.Variables(3).ValuesAsNumpy()

   
        daily_data = {
            "date": pd.date_range(
                start=pd.to_datetime(daily.Time(), unit="s", utc=True),
                end=pd.to_datetime(daily.TimeEnd(), unit="s", utc=True),
                freq=pd.Timedelta(seconds=daily.Interval()),
                inclusive="left"
            ),
            "rain_sum": daily_rain_sum,
            "snowfall_sum": daily_snowfall_sum,
            "weather_code": daily_weather_code,
            "temperature": daily_temperature_2m_max
            }

        daily_dataframe = pd.DataFrame(data=daily_data)
        daily_dataframe["date"] = daily_dataframe["date"].dt.tz_localize(None)

        print(daily_dataframe)
        return daily_dataframe
    
    def pred_from_model(self, start, end, is_festival, weather_df):
        date_range = pd.date_range(start=start,end=end)
        df = pd.DataFrame({
            "date" :date_range,
            "is_festival" : is_festival
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
        season_encoder = joblib.load("model/season_encoder.pkl")
        df["season"] = season_encoder.transform(df["season"])
        df = df.merge(weather_df, on="date", how="left")
        
        features = ["weekday", "month", "is_festival", "season",
                "weather_code", "temperature", "snowfall_sum", "rain_sum",
                "year", "day", "weekofyear"]
        
        model_input = df[features]
        model = joblib.load("model/sales_model.pkl")
        preds = model.predict(model_input)

        df["predicted_sales"] = preds

        print(df[["date", "predicted_sales"]])
        return df[["date", "predicted_sales"]]

     
    def pred_staff_count(self, sales_preds):
        model = joblib.load("model/staff.pkl")
        input_df = sales_preds[["predicted_sales"]].rename(columns={"predicted_sales": "sales"})
        staff_levels = model.predict(input_df)
        sales_preds["predicted_staff_level"] = staff_levels
        print(sales_preds[["date", "predicted_sales", "predicted_staff_level"]])
        return sales_preds[["date", "predicted_sales", "predicted_staff_level"]]

            
    
