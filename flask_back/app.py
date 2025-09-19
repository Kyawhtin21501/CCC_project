import sys
import os
from datetime import date, timedelta
import pandas as pd
from flask import Flask, send_from_directory, jsonify
from flask_cors import CORS
from pprint import pprint
# Get project root (one folder above flask_back)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Centralize CSV pat
# PATHS = {
#     "shift_preferences": os.path.join(BASE_DIR, "data", "shift_preferences.csv"),
#     "shift_data_base": os.path.join(BASE_DIR, "data", "shift_data_base.csv"),
#     "staff_database": os.path.join(BASE_DIR, "data", "staff_dataBase.csv"),
#     "user_input": os.path.join(BASE_DIR, "data", "user_input.csv"),
#     "project": os.path.join(BASE_DIR, "data", "project.csv")
# }


sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Import all necessary service modules
from flask_back.services.staff_manager import StaffManager
from flask_back.services.user_input_handler import UserInputHandler
from flask_back.services.pred import ShiftCreator
from flask_back.services.staff_pro import CreateStaff, DeleteStaff, EditStaff, SearchStaff, StaffProfileOperation
from flask_back.services.shifting_operator import ShiftOperator
from flask_back.services.shift_preferences import ShiftPreferences
from flask_back.services.staff_manager import StaffManager

#from services.retrain import reTrain_model
from datetime import date, timedelta
import pandas as pd
import os
APP_ROOT = os.path.dirname(os.path.abspath(__file__))
app = Flask(
    __name__,
    static_folder=os.path.join(APP_ROOT, "flutter_front/predictor_web/build/web"),
    static_url_path=""
)




CORS(app)

  # Enable CORS to allow requests from frontend (e.g. Flutter)

# ---------------------------------------
# Health check endpoint
# ---------------------------------------
@app.route('/')
def home():
    return send_from_directory(app.static_folder, "index.html")




# ---------------------------------------
# Save user input (e.g. sales, staff count)
# add retrain model start point
# --------------------------------------
#_________________________________________staff list for user list show off__________________________
@app.route('/staff_list', methods=['GET'])
def staff_list():
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.join(base_dir, '..', 'data', 'staff_dataBase.csv')
        csv_path = os.path.abspath(csv_path)
        print(f"Looking for CSV at: {csv_path}")

        staff_df = pd.read_csv(csv_path)
        print("CSV columns:", staff_df.columns.tolist())

        if "Name" in staff_df.columns:
            names = staff_df["Name"].dropna().unique().tolist()
            return jsonify(names)
        else:
            return jsonify({"error": "No 'Name' column found"}), 400
    except Exception as e:
        return jsonify({"error": str(e)}), 500


# --------------------------------------------------------------------------------------------------------------







#-------------------------------------------data end point for dashboard----------------------------------


@app.route('/user_input', methods=['POST'])
def save_data():    
    # Get the data submitted by the frontend (usually from Dashboard)
    data = request.get_json()
    
    # Use helper classes to clean/process and save the data
    staff_manager = StaffManager()
    handler = UserInputHandler(data, staff_manager)
    cleaned_names = handler.process_and_save()

    print(cleaned_names)  # For debug
    
    # Check if retraining is needed
    
    
    return jsonify({"message": "Data saved successfully"}), 200


#/////data end point for shift table in dashboard
# ---------------------------------------
"""
[
  {
    "date": "2025-08-06",
    "shift": "morning",
    "name_level": "Kyaw Htin Hein (Lv5), Lisa (Lv4)"
  },
  {
    "date": "2025-08-06",
    "shift": "afternoon",
    "name_level": "Yan Shin Shein (Lv5)"
  },
  {
    "date": "2025-08-06",
    "shift": "night",
    "name_level": "Kyaw Htin Hein (Lv5), Kyi Pyar (Lv3)"
  }
]
example response of shift assignment and sale prediction 

"""



# ---------------------------------------Save shift preferences to CSV file for create shift screen ----------------------------------------
# This endpoint receives shift preferences from the frontend and saves them to a CSV file.
# The preferences are expected to be in a specific format, and the date is also provided.
# The CSV file is saved in the 'data' directory of the Flask application.
@app.route('/save_shift_preferences', methods=['POST'])
def save_shift_preferences():
    """
    Endpoint to receive shift preferences from the frontend and save them to a CSV file.
    
    """
    try:
        # Step 1: Parse JSON data from request
        data = request.get_json()
        date_str = data.get("date")
        preferences = data.get("preferences")

        # Debug print to verify incoming data
        #print(f"Received date: {date_str}, preferences: {preferences}")

        # Step 2: Convert preferences dictionary into a DataFrame
        df = pd.DataFrame.from_dict(preferences, orient='index').reset_index()
        df.rename(columns={'index': 'staff'}, inplace=True)
        df["date"] = date_str

        # Debug print the first few rows of the DataFrame
        #print(df)

        # Step 3: Save the DataFrame to CSV using the ShiftPreferences class
        save_path = os.path.join(app.root_path, '../data', 'shift_preferences.csv')
        saver = ShiftPreferences(df, save_path)
        saver.save_to_database()

        # Step 4: Return success response
        return jsonify({"message": "Shift preferences saved"}), 200

    except Exception as e:
        # Print error details for debugging
        print(e)
        return jsonify({"error": str(e)}), 500
    

# ---------------------------------------
# Predict sales and assign shifts based on input dates and location
# ---------------------------------------

@app.route('/shift', methods=['POST', 'GET'])
def shift():
    data = request.get_json()
    start_date = data.get("start_date")
    end_date = data.get("end_date")
    
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
    data_path_preferences = os.path.join(BASE_DIR, "data", "shift_preferences.csv")
    data_path_staff_db = os.path.join(BASE_DIR, "data", "staff_database.csv")
    
    #result_df["predicted_staff_level"] = result_df[result_df["predicted_staff_level"]].astype(int)
    # Check if files exist
    
    print("data colect ok")
    
    # Load CSVs
    shift_preferences_df = pd.read_csv(data_path_preferences)
    staff_database_df = pd.read_csv(data_path_staff_db)
      # Convert to DataFrame for easier manipulation
 
    #pprint(result_df["predicted_staff_level"])
    # --- Step 3: Run shift optimization (LP) ---
    result_df = pd.DataFrame(result_df)
    required_level_dict = result_df.set_index("date")["predicted_staff_level"].astype(int).to_dict()
    shift_preferences_df["date"] = pd.to_datetime(shift_preferences_df["date"]).dt.date
    dishboard_pred_path = os.path.join(BASE_DIR,"data/data_for_dashboard/" 'temporary_shift_database_for_dashboard.csv')
    print("Kyaw Htin Hein")
    shift_preferences_df = shift_preferences_df[(shift_preferences_df["date"] >= start) & (shift_preferences_df["date"] <= end)]
    if (shift_preferences_df["date"] >= start).any() and (shift_preferences_df["date"] <= end).any():
        #shift_preferences_df = shift_preferences_df["date"].between(start, end)
        print("final data check" ,shift_preferences_df)
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
            shift_schedule = shift_operator.assign_shifts()
            try:
                if os.path.exists(dishboard_pred_path):
                    #staff_database_df
                    shift_schedule.to_csv(dishboard_pred_path, index=False)
                    print("File saved successfully!")
                else:
    # ファイルが存在しないか空の場合、新規保存
                    shift_schedule.to_csv(dishboard_pred_path, index=False)
                    print("new")
            except Exception as e:
                    print(f"Failed to save CSV: {e}")

        
        except Exception as e:
            import traceback
            print("ShiftOperator failed:", e)
            traceback.print_exc()
            return {"error": str(e)}, 500
    else:
        return jsonify({"error": "No shift preferences found for the given date range"}), 400
    # --- Step 4: Return results as JSON-like dict ---
    # Convert predicted staff level (from ML model) to list of dicts
    pred_df_final_end_point = pred_df.to_dict(orient="records")
    pprint("----------------------------pred_df_final_end_point----------------------------")
    pprint(pred_df_final_end_point)
    
    
    # Return both shift schedule and prediction to frontend
    return jsonify({
        "shift_schedule": shift_schedule.to_dict(orient="records"),  # Shift assignment result
        "prediction": pred_df_final_end_point                        # Staff requirement prediction
    }),200
    




# ---------------------------------------------------------------------------------------------------------------------------------


@app.route('/shift_table/dashboard', methods=['GET' , 'POST'])
def get_shift_table_dashboard():
    """
    Endpoint to retrieve the shift table for the dashboard.
    Returns a JSON response with the shift assignments.
    """
    try:
        # Load the CSV file containing shift assignments
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.join(base_dir, '..', 'data/data_for_dashboard/', 'temporary_shift_database_for_dashboard.csv')
        csv_path_staff = os.path.join(base_dir, '..', 'data', 'staff_dataBase.csv')
        csv_path = os.path.abspath(csv_path)
        

        # Read the CSV into a DataFrame
        df = pd.read_csv(csv_path)
        #df_staff = pd.read_csv(csv_path_staff)
        
        # Convert DataFrame to a list of dictionaries for JSON response
        shift_data = df.to_dict(orient='records')
        #staff_data = pd.read_csv(csv_path_staff).to_dict(orient='records')
        #result = pd.DataFrame(shift_data).merge(pd.DataFrame(staff_data), left_on='ID', right_on='ID', how='left')
        pprint(shift_data)
        return jsonify(shift_data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500



#////data end point for pred_sale in dashboard
@app.route('/pred_sale/dashboard', methods=['GET' , 'POST'])
def get_pred_sale_dashboard():
    """
    Endpoint to retrieve the predicted sales data for the dashboard.
    Returns a JSON response with the predicted sales.
    """
    try:
        # Load the CSV file containing predicted sales
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.join(base_dir, '..', 'data/data_for_dashboard', 'predicted_sales.csv')
        csv_path = os.path.abspath(csv_path)

        # Read the CSV into a DataFrame
        df = pd.read_csv(csv_path)

        # Convert DataFrame to a list of dictionaries for JSON response
        pred_data = df.to_dict(orient='records')
        
        return jsonify(pred_data), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    


#------------------------------------------------------------------------------------------------------------------------------------









# ---------------------------------------Staff profile operations (CRUD)----------------------------------------
# ---------------------------------------
# Create a new staff profile (from StaffProfile screen)
# ---------------------------------------
@app.route('/services/staff', methods=['POST'])
def create_staff():
    data = request.get_json()
    print(f"Received JSON: {data}")  # Debug

    try:
        new_staff = CreateStaff(
            name=data["Name"],
            level=int(data["Level"]),
            gender=data["Gender"],
            age=int(data["Age"]),
            email=data["Email"],
            status=data.get("status") or data.get("Status") or "",
        )
        result = new_staff.operate()
        return jsonify({"message": f"Staff created: {result}"}), 200
    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"error": str(e)}), 400

# ---------------------------------------
# Edit existing staff info by ID
# ---------------------------------------
# Khh ok 

@app.route('/services/staff/<int:staff_id>', methods=['PUT','GET','POST'])
def update_staff_by_id(staff_id):
    try:
        if request.method == 'PUT':
            if not request.is_json:
                return jsonify({"error": "Content-Type must be application/json"}), 415
            updates = request.get_json(silent=True) or {}
            if not isinstance(updates, dict) or not updates:
                return jsonify({"error": "Request body must be a non-empty JSON object"}), 400
            if 'ID' in updates:
                return jsonify({"error": "ID cannot be updated"}), 400

            editor = EditStaff(staff_id=staff_id, updates=updates)
            ok = editor.operate()
            if not ok:
                return jsonify({"error": "Staff ID not found or no updates made"}), 404
            return jsonify({"message": f"Staff {staff_id} updated successfully"}), 200

        elif request.method in ('GET', 'POST'): 
            DATA_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                         '..', 'data', 'staff_dataBase.csv')
            csv_path = os.path.abspath(DATA_PATH)
            df = pd.read_csv(csv_path, dtype={'ID': str})
            staff = df[df['ID'] == str(staff_id)]
            if staff.empty:
                return jsonify({"error": "Staff not found"}), 404
            return jsonify(staff.iloc[0].to_dict()), 200

    
        return jsonify({"error": "Method not allowed"}), 405

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# -------------------------------




# ---------------------------------------
# Delete staff record by ID
# ---------------------------------------
@app.route('/services/staff/<int:staff_id>', methods=['DELETE'])
      
def delete_staff(staff_id):
    try:
        #base_dir = os.path.dirname(os.path.abspath(__file__))
        #csv_path = os.path.join(base_dir, '..', 'data', 'staff_dataBase.csv')
        #csv_path = os.path.abspath(csv_path)
        #print(f"Looking for CSV at: {csv_path}")
        deleter = DeleteStaff(staff_id=staff_id)
        result = deleter.operate()
        return jsonify({"message": f"Staff {result} deleted successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ---------------------------------------
# Search staff by ID or Name
# ---------------------------------------
@app.route('/services/staff/search', methods=['GET'])
def search_staff():
    
    term = request.args.get("term")
    by = request.args.get("by", "ID")  # Default search by ID
    try:
        searcher = SearchStaff(search_term=term, by=by)
        result = searcher.operate()
        if result == "error":
            return jsonify({"message": "Not found"}), 404
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# ---------------------------------------
# Run the Flask app
# ---------------------------------------


port = int(os.environ.get("PORT", 5000))
app.run(host="0.0.0.0", port=port)

