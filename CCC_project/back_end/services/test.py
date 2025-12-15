from pred import ShiftCreator
from shifting_operator import ShiftOperator

from datetime import date, timedelta
import pandas as pd
import os
from pprint import pprint
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
def shift():
    #data = request.get_json()
    start_date = "2025-9-16"
    end_date = "2025-9-22"
    
    #latitude = data.get("latitude", 35.6762) #kyipyar hlaing
    #longitude = data.get("longitude", 139.6503)#kyipyar hlaing
    #latitude = 52.52
    #longitude = 13.41
    
    # --- Step 1: Predict daily required staff level ---
    creator = ShiftCreator(start_date, end_date)

    # Get start/end date objects
    start, end = creator.date_data_from_user()
    
    print ("from user start and end " , start,end)
    if not start or not end:
        return ({"error": "Invalid date range"})
    # Get external data
    festivals = creator.check_festival_range(start, end) 
    # Check if each day has a festival
    start_wea ,end_wea= start +timedelta(days=1) , end + timedelta(days=1)
    weather_df = creator.weather_data(start_wea, end_wea)         # Get weather data for each day

    # Predict sales and required staff levels
    pred_df = creator.pred_from_model(start, end, festivals, weather_df)
    result_df = creator.pred_staff_count(pred_df)
    

    # Get required staff level by hour for each day
    print("----------------------------pred_df----------------------------")
    #pprint(type(result_df))
    # --- Step 2: Load staff preferences and staff profile info ---
    print("ここまでok")
    #base_dir = os.path.dirname(os.path.dirname(__file__))  
    #data_path_preferences = os.path.join(BASE_DIR,  "../../data", "shift_preferences.csv")
    #data_path_preferences = os.path.join(BASE_DIR, "..", "..", "data", "staff_dataBase.csv")
    #data_path_preferences = os.path.join(BASE_DIR, "..", "..", "data", "shift_preferences.csv")
    staff_database_df = pd.read_csv("/Users/khein21502/Documents/project_root/CCC_project/data/staff_dataBase.csv")
    shift_preferences_df = pd.read_csv("/Users/khein21502/Documents/project_root/CCC_project/data/shift_preferences.csv")
    #result_df["predicted_staff_level"] = result_df[result_df["predicted_staff_level"]].astype(int)
    # Check if files exist
    
    print("data colect ok")
    
    # Load CSVs
    #shift_preferences_df = pd.read_csv(shift_preferences_df)
    #staff_database_df = pd.read_csv()
      # Convert to DataFrame for easier manipulation
    
    #pprint(result_df["predicted_staff_level"])
    # --- Step 3: Run shift optimization (LP) ---
    result_df = pd.DataFrame(result_df)
    required_level_dict = result_df.set_index("date")["predicted_staff_level"].astype(int).to_dict()
    shift_preferences_df["date"] = pd.to_datetime(shift_preferences_df["date"]).dt.date
    #staff_database_df["level"] = staff_database_df["level"].astype(int)
    
    shift_preferences_df = shift_preferences_df[(shift_preferences_df["date"] >= start) & (shift_preferences_df["date"] <= end)]
    print("shift_preferences_df")
    print(shift_preferences_df)
    
    
    
    if (shift_preferences_df["date"] >= start).any() and (shift_preferences_df["date"] <= end).any():
        shift_preferences_df = (shift_preferences_df[shift_preferences_df["date"] >= start])
        if shift_preferences_df.empty:
            print("empty")
            #continue  # or handle it differently
        #match_row = filtered.iloc[0]
        
        try:
            shift_operator = ShiftOperator(
                shift_preferences=shift_preferences_df,
                staff_dataBase=staff_database_df,
                required_level=required_level_dict
            )
            for col in shift_operator.shift_preferences.columns:
                print(f"{col}: {shift_operator.shift_preferences[col].dtype}")
                print(shift_operator.shift_preferences[col].head())
                
            shift_schedule = shift_operator.assign_shifts()
        except Exception as e:
            import traceback
            print("ShiftOperator failed:", e)
            traceback.print_exc()
            return {"error": str(e)}, 500
    else:
        return None
    # --- Step 4: Return results as JSON-like dict ---
    # Convert predicted staff level (from ML model) to list of dicts
    print("----------------------------shift_schedule----------------------------")
    pprint(shift_schedule)
    pred_df_final_end_point = pred_df.to_dict(orient="records")
    pprint("----------------------------pred_df_final_end_point----------------------------")
    pprint(pred_df_final_end_point)
    

    
    # Return both shift schedule and prediction to frontend
    return ({
        "shift_schedule": shift_schedule.to_dict(orient="records"),  # Shift assignment result
        "prediction": pred_df_final_end_point                        # Staff requirement prediction
    })
        # Return both shift schedule and prediction to frontend
  

shift()
