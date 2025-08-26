import pandas as pd
import joblib
import os 
from sklearn.metrics import mean_squared_error
from pred import ShiftCreator
from retry_requests import retry
from sklearn.metrics import mean_squared_error
from sklearn.metrics import mean_absolute_error
from sklearn.metrics import r2_score
import numpy as np
class ReTrainModel:
    """
    This class checks whether the model should be retrained based on accumulated user input data.
    If the number of new data rows reaches a threshold (default: 100),
    the class returns the most recent N rows for retraining.
    """

    def __init__(self,count=10):
        """
        Initialize the ReTrainModel class.

        Parameters:
        - data_path: Path to the CSV file containing user input data
        - model_path: Path to the saved model (.pkl file)
        - count: Number of new records required to trigger retraining (default is 100)
        """
      
        
        self.count = count
       
        self.base_dir = os.path.dirname(os.path.abspath(__file__))
        
        self.data_path = os.path.abspath(os.path.join(self.base_dir, '..', '..', 'data', 'user_input_test.csv'))
        self.project_path = os.path.abspath(os.path.join(self.base_dir,'..', '..', 'data', 'project.csv'))
        
    def should_retrain(self): 
        """
        Check if the number of records in the data file meets the retraining threshold.

        Returns:
        - The latest `count` rows (DataFrame) if retraining is needed and data count is divisible by count
        - False if retraining is not needed or an error occurs
        """
        try:
            # Load user input data
            df = pd.read_csv(self.data_path)
            current_count = len(df)
            #print("length of current_data" ,current_count)

            # Check if data count meets the retraining condition
            if current_count >= self.count:
                if current_count % self.count == 0:
                    recent_data = df.tail(self.count)

                    print(recent_data["date"])
                    #print("tail data for retrain", recent_data)
                    return recent_data
                else:
                    
                    return print("tail data not enough for retrain")
            else:
                print("not enough data for retrain")
                return print("tail data not enough for retrain")

        except FileNotFoundError:
            print(f"File not found: {self.data_path}")
            return False
        except Exception as e:
            print(f"Unexpected error occurred: {e}")
            return False
    
    def weather_data(self):
        df = self.should_retrain()
        #print(df)
        date_range = df["date"]
        start_date = date_range.iloc[0]
        end_date = date_range.iloc[-1]
        print("start date ---------",start_date)
        print(end_date)
        calculator = ShiftCreator(start_date=start_date ,end_date=end_date ,date_format="%Y-%m-%d")
        start,end = calculator.date_data_from_user()
        weather_df = calculator.weather_data(start,end)
        print(weather_df["date"])
        return weather_df
        
    def feacture_data_for_retarin(self):
        recent_df = self.should_retrain()
        recent_df["date"] = pd.to_datetime(recent_df['date']).dt.date
        weather_df = self.weather_data()
        weather_df['date'] = pd.to_datetime(weather_df['date']).dt.date
        main_df = pd.merge(recent_df, weather_df, on='date', how='inner')
        
        return main_df
    
    def mse_check(self):
        main_df = self.feacture_data_for_retarin()
        print(main_df)
        start = str(main_df["date"].iloc[0])
        end = str(main_df["date"].iloc[-1])
        pred = ShiftCreator(start,end)
        start,end = pred.date_data_from_user()
        festival = pred.check_festival_range(start=start,end=end)
        weat = pred.weather_data(start=start,end=end)
        pred_df = pred.pred_from_model(start,end,festival,weat)
        Y_pred = pred_df["predicted_sales"]
        y  = main_df["sales"]
        mae = mean_absolute_error(y, Y_pred)
        mse = mean_squared_error(y,Y_pred)
        r2 = r2_score(y, Y_pred)
        rmse  = np.sqrt(mse)
        print("mae ********",mae)
        print("mse ********",mse)
        print("r2 *********", r2)
        print("rmse *******",rmse)
        if r2 <= 0.8:
            project_df = pd.read_csv(self.project_path)
            #print(project_df)
            new_df = self.feacture_data_for_retarin()
            #print(new_df)
            result_data = pd.concat([project_df, new_df], axis=0, ignore_index=True)
            result_data.to_csv(self.project_path)
            print("check.....",result_data)
            try:
                import xgboost as xgb 
                from sklearn.preprocessing import LabelEncoder
                import joblib  
            
                model_path = os.path.abspath(os.path.join(self.base_dir, '..', '..', 'model', 'sales_model.pkl'))
                #project_path = os.path.abspath(os.path.join(self.base_dir, '..', '..','data','project.csv'))
                encoder_path = os.path.abspath(os.path.join(self.base_dir, '..', '..', 'model', 'season_encoder0.1.pkl'))
                result_data.dropna(inplace=True)
                result_data.fillna(result_data.mean(numeric_only=True), inplace=True)

                result_data["date"] = pd.to_datetime(result_data["date"], errors="coerce")
                result_data["year"] = result_data["date"].dt.isocalendar().year
                result_data["month"] = result_data["date"].dt.month
                result_data["day"] = result_data["date"].dt.day
                result_data["weekday"] = result_data["date"].dt.weekday
                result_data["weekofyear"] = result_data["date"].dt.isocalendar().week
                encoder = LabelEncoder()
                result_data["season"] = encoder.fit_transform(result_data["season"])
                

                X = result_data[["weekday", "month", "is_festival", "season",
                        "weather_code", "temperature",
                        "snowfall_sum", "rain_sum",
                        "year", "day", "weekofyear"]]
                y = result_data["sales"]

                model = xgb.XGBRegressor(
                    objective="reg:squarederror",
                    max_depth=4,
                    learning_rate=0.1,
                    n_estimators=100
                    )
                model.fit(X, y)
                if os.path.exists(model_path):
                    os.remove(model_path)

                if os.path.exists(encoder_path):
                    os.remove(encoder_path)
                    
                joblib.dump(model, model_path)
                joblib.dump(encoder, encoder_path)
                
                return print("no error")
            except KeyError as e:
                return print(e)
        else:
            pass
        
        
       
    
    
        
        
    
        
    
run = ReTrainModel()
if __name__ == "__main__":
    run.mse_check()
    
