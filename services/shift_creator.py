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
        return is_festival

    def weather_data(self):
        cache_session = requests_cache.CachedSession('.cache', expire_after=3600)
        retry_session = retry(cache_session, retries=5, backoff_factor=0.2)
        openmeteo = openmeteo_requests.Client(session=retry_session)

        url = "https://api.open-meteo.com/v1/forecast"
        params = {
            "latitude": self.latitude,
            "longitude": self.longitude,
            "daily": ["rain_sum", "snowfall_sum", "weather_code", "temperature_2m_max"],
            "timezone": "Asia/Tokyo",
            "start_date": self.start_date,  
            "end_date": self.end_date
        }

        responses = openmeteo.weather_api(url, params=params)
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
        print(daily_dataframe)
        return daily_dataframe
    
    #def data_from_model(self,start,end,is_ffestival,daily_dataframe):
        
    
        



if __name__ == "__main__":
    start_date = input("Plz enter start date (YYYY-MM-DD): ")
    end_date = input("Plz enter end date (YYYY-MM-DD): ")

    #saitama
    latitude = 35.8617
    longitude = 139.6455

    creator = ShiftCreator(start_date, end_date, latitude, longitude)
    start, end = creator.date_data_from_user()

    if start and end:
        festivals = creator.check_festival_range(start, end)
        weather_df = creator.weather_data()
        #pred_df = creator.pred_from_model(start, end, festivals, weather_df)

       

