from pred import ShiftCreator
from shifting_operator import ShiftOperator
from datetime import date, timedelta
import pandas as pd
import os
from pprint import pprint
def shift():
    #data = request.get_json()
    start_date = date.today().strftime("%Y-%m-%d")  # Default to today
    end_date = (date.today() + timedelta(days=14)).strftime("%Y-%m-%d") 
    #end_date = data.get("end_date")
    #latitude = 35.8362
    #longitude = 139.5801

    # Step 1: Use ShiftCreator to predict staff level needed
    creator = ShiftCreator(start_date, end_date)

    # Get start/end date objects
    start, end = creator.date_data_from_user()
    if not start or not end:
        return ({"error": "Invalid date range"})
    # Get external data
    festivals = creator.check_festival_range(start, end)  # Check if each day has a festival
    weather_df = creator.weather_data(start, end)         # Get weather data for each day

    # Predict sales and required staff levels
    pred_df = creator.pred_from_model(start, end, festivals, weather_df)
    result_df = creator.pred_staff_count(pred_df)
    # Get required staff level by hour for each day
    print("----------------------------pred_df----------------------------")
    pprint(type(result_df))
    # --- Step 2: Load staff preferences and staff profile info ---
  
    base_dir = os.path.dirname(os.path.dirname(__file__))  # one folder up from flask_back
    data_path_preferences = os.path.join(base_dir, "../data", "shift_preferences.csv")
    data_path_staff_db = os.path.join(base_dir, "../data", "staff_database.csv")
    #result_df["predicted_staff_level"] = result_df[result_df["predicted_staff_level"]].astype(int)
    # Check if files exist
    if not os.path.exists(data_path_preferences) or not os.path.exists(data_path_staff_db):
        return {"error": "Required data files not found."}
    
    # Load CSVs
    shift_preferences_df = pd.read_csv(data_path_preferences)
    staff_database_df = pd.read_csv(data_path_staff_db)
      # Convert to DataFrame for easier manipulation
    required_level_dict = {}
    # list of dicts → DataFrame に変換
    result_df = pd.DataFrame(result_df)

# これで iterrows が使える
    for _, row in result_df.iterrows():
        print(row["predicted_staff_level"])

    required_level_dict[date_str] = {
        "morning": row["predicted_staff_level"],
        "afternoon": row["predicted_staff_level"],
        "night": row["predicted_staff_level"]
    }
    #pprint(result_df["predicted_staff_level"])
    # --- Step 3: Run shift optimization (LP) ---
    shift_operator = ShiftOperator(
        shift_preferences=shift_preferences_df,
        staff_dataBase=staff_database_df,
        required_level = result_df[["predicted_staff_level"]].to_dict(orient="records")

    )
    shift_schedule = shift_operator.assign_shifts()

    # Convert result to DataFrame for easier formatting
    shift_schedule = pd.DataFrame(shift_schedule)

    # --- Step 4: Return results as JSON-like dict ---
    # Convert predicted staff level (from ML model) to list of dicts
    pred_df_final_end_point = pred_df.to_dict(orient="records")
    pprint("----------------------------pred_df_final_end_point----------------------------")
    pprint(pred_df_final_end_point)
    pprint("----------------------------shift_schedule----------------------------")
    pprint(shift_schedule)
    # Return both shift schedule and prediction to frontend
    return ({
        "shift_schedule": shift_schedule.to_dict(orient="records"),  # Shift assignment result
        "prediction": pred_df_final_end_point                        # Staff requirement prediction
    })



shift()
