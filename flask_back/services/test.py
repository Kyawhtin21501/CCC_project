from pred import ShiftCreator
from shifting_operator import ShiftOperator
from datetime import date, timedelta
import pandas as pd
import os

def shift():
    #data = request.get_json()
    start_date = date.today().strftime("%Y-%m-%d")  # Default to today
    end_date = (date.today() + timedelta(days=14)).strftime("%Y-%m-%d") 
    #end_date = data.get("end_date")
    latitude = 35.8362
    longitude = 139.5801

    # Step 1: Use ShiftCreator to predict staff level needed
    creator = ShiftCreator(start_date, end_date, latitude, longitude)
    start, end = creator.date_data_from_user()

    if not start or not end:
        return  400

    festivals = creator.check_festival_range(start, end)#festivals data from in range 14 days
    weather_df = creator.weather_data(start, end)
    pred_df = creator.pred_from_model(start, end, festivals, weather_df)#needed staff level per day
    result_df = creator.pred_staff_count(pred_df)
    #print(result_df)
    #print(type(result_df))

    # Step 2: Load staff preferences and profiles
    # Step 2: Load staff preferences and profiles
    base_dir = os.path.dirname(os.path.abspath(__file__))  # test.py のあるディレクトリ
    data_path_preferences = os.path.normpath(os.path.join(base_dir, '../../data/shift_preferences.csv'))
    data_path_staff_db = os.path.normpath(os.path.join(base_dir, '../../data/staff_database.csv'))

    # 読み込み（これが必要！）
    shift_preferences_df = pd.read_csv(data_path_preferences)
    staff_database_df = pd.read_csv(data_path_staff_db)


    

    # Step 3: Assign shifts using LP optimization
    shift_operator = ShiftOperator(
        shift_preferences= shift_preferences_df,
        staff_dataBase= staff_database_df,
        required_level=result_df
    )
    shift_schedule = shift_operator.assign_shifts()
    shift_schedule = pd.DataFrame(shift_schedule)
    #print(shift_schedule.head())
    #print(shift_schedule.columns)

    

    # --- CHANGE #1 ---
    # In your original code you had:
    # return jsonify(shift_schedule.to_dict(orient="records"), pred_df), 200
    #
    # This caused two issues:
    #   1. jsonify() only accepts ONE object, not two separate arguments.
    #   2. pred_df is a Pandas DataFrame, which is not JSON serializable.
    #
    # FIX: Convert both DataFrames to JSON-friendly Python lists.
    #shift_schedule_list = shift_schedule.to_dict(orient="records")
    #print(pred_df) # <-- CHANGED

    # --- CHANGE #2 ---
    # Wrap both results into ONE dictionary so jsonify() works.
    # This also makes it easier for Flutter to parse the API response.
    pred_df_final_end_point = pred_df.to_dict(orient="records")  # Convert to list of dicts

    return ({
        "shift_schedule": shift_schedule,  # <-- CHANGED: clean list
        "prediction": pred_df_final_end_point                # <-- CHANGED: clean list
    }), 200


try:
    shift()
except Exception as e:
    import traceback
    traceback.print_exc()
 #Call the function to execute the logic