import os
import pandas as pd
from datetime import datetime, timedelta
import requests
import openmeteo_requests
import requests_cache
from retry_requests import retry
import joblib

class ShiftCreator:
    """
    This class handles the prediction of daily sales and staff levels
    based on input date range, weather forecast, and festival data.
    """

    def __init__(self, start_date, end_date, latitude, longitude, date_format="%Y-%m-%d"):
        self.start_date = start_date
        self.end_date = end_date
        self.date_format = date_format
        self.latitude = latitude
        self.longitude = longitude

    def date_data_from_user(self):
        """
        Convert user input strings to Python datetime.date objects.
        """
        try:
            start = datetime.strptime(self.start_date, self.date_format).date()
            end = datetime.strptime(self.end_date, self.date_format).date()
            print(start, end)
            return start, end
        except ValueError as e:
            print("Date parsing error:", e)
            return None, None

    def get_festival_days(self):
        """
        Load festival dates from CSV and extract month-day format (MM-DD).
        Returns a set of festival MM-DD strings.
        """
        # file_path = "data/project.csv"
        # festival_data = pd.read_csv(file_path)
        #kyipyar hlaing
        base_dir = os.path.dirname(os.path.abspath(__file__))  # /flask_back/services
        file_path = os.path.join(base_dir, "../../data/project.csv")  # go up 2 levels
        file_path = os.path.normpath(file_path)

        if not os.path.exists(file_path):
            raise FileNotFoundError(f"Festival CSV not found at {file_path}")

        festival_data = pd.read_csv(file_path)
        #kyipyar hlaing
        festival_data['month_day'] = pd.to_datetime(festival_data['date']).dt.strftime("%m-%d")
        festival_md = festival_data[festival_data['is_festival'] == True]['month_day'].tolist()
        return set(festival_md)

    def check_festival_range(self, start, end):
        """
        Check which days in the range are festivals.
        Returns a list of 1 (festival) or 0 (not) for each date.
        """
        festival_md_set = self.get_festival_days()
        current = start
        is_festival = []

        while current <= end:
            md = current.strftime("%m-%d")
            is_festival.append(1 if md in festival_md_set else 0)
            current += timedelta(days=1)

        print(is_festival)
        return is_festival

    def weather_data(self, start, end):
        """
        Fetch daily weather forecast data from Open-Meteo API.
        Returns a pandas DataFrame with weather features.
        """
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
            print("No data returned from Open-Meteo")
            print("Parameters:", params)
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

        daily_dataframe = pd.DataFrame(data=daily_data)
        daily_dataframe["date"] = daily_dataframe["date"].dt.tz_localize(None)

        print(daily_dataframe)
        return daily_dataframe

    def pred_from_model(self, start, end, is_festival, weather_df):
        """
        Predict sales using pre-trained machine learning model (XGBoost or similar).
        Merge features: date, festival flag, season, weather.
        """
        date_range = pd.date_range(start=start, end=end)
        df = pd.DataFrame({
            "date": date_range,
            "is_festival": is_festival
        })

        # Feature engineering
        df["weekday"] = df["date"].dt.weekday
        df["month"] = df["date"].dt.month
        df["day"] = df["date"].dt.day
        df["year"] = df["date"].dt.isocalendar().year
        df["weekofyear"] = df["date"].dt.isocalendar().week

        # Season encoding (categorical -> numeric)
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
       # season_encoder = joblib.load("model/season_encoder.pkl")
        #kyipyar hlaing
        base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

        model_path = os.path.join(base_dir, 'model', 'season_encoder.pkl')
        season_encoder = joblib.load(model_path)
        #kyipyar hlaing
        df["season"] = season_encoder.transform(df["season"])

        # Merge with weather data
        df = df.merge(weather_df, on="date", how="left")

        # Define feature columns for model
        features = [
            "weekday", "month", "is_festival", "season",
            "weather_code", "temperature", "snowfall_sum", "rain_sum",
            "year", "day", "weekofyear"
        ]

        model_input = df[features]
        model = joblib.load("model/sales_model.pkl")
        preds = model.predict(model_input)

        df["predicted_sales"] = preds
        print(df[["date", "predicted_sales"]])
        return df[["date", "predicted_sales"]]

    def pred_staff_count(self, sales_preds):
        """
        Predict required staff level based on predicted sales using another trained model.
        """
        model = joblib.load("model/staff.pkl")
        input_df = sales_preds[["predicted_sales"]].rename(columns={"predicted_sales": "sales"})
        staff_levels = model.predict(input_df)
        sales_preds["predicted_staff_level"] = staff_levels

        print(sales_preds[["date", "predicted_sales", "predicted_staff_level"]])
        return sales_preds[["date", "predicted_sales", "predicted_staff_level"]].dict(orient="records")
