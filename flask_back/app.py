import sys
import os
from datetime import date, timedelta
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS
# Get project root (one folder above flask_back)
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Centralize CSV paths here
# PATHS = {
#     "shift_preferences": os.path.join(BASE_DIR, "data", "shift_preferences.csv"),
#     "shift_data_base": os.path.join(BASE_DIR, "data", "shift_data_base.csv"),
#     "staff_database": os.path.join(BASE_DIR, "data", "staff_dataBase.csv"),
#     "user_input": os.path.join(BASE_DIR, "data", "user_input.csv"),
#     "project": os.path.join(BASE_DIR, "data", "project.csv")
# }


sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Import all necessary service modules
from services.staff_manager import StaffManager
from services.user_input_handler import UserInputHandler
from services.pred import ShiftCreator
from services.staff_pro import CreateStaff, DeleteStaff, EditStaff, SearchStaff, StaffProfileOperation
from services.shifting_operator import ShiftOperator
from services.shift_preferences import ShiftPreferences
#from services.retrain import reTrain_model
from datetime import date, timedelta
import pandas as pd
app = Flask(__name__)
CORS(app)  # Enable CORS to allow requests from frontend (e.g. Flutter)

# ---------------------------------------
# Health check endpoint
# ---------------------------------------
@app.route('/')
def home():
    # This is a basic check to confirm the server is running
    return "API Server is Running"

# ---------------------------------------
# Save user input (e.g. sales, staff count)
# add retrain model start point
# ---------------------------------------
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




#updated route for stafflist use in user input dashboard  or not i cannot run --kyipyar hlaing
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

#create shift by each user with their own id --kyipyar hlaing
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
        print(f"Received date: {date_str}, preferences: {preferences}")

        # Step 2: Convert preferences dictionary into a DataFrame
        df = pd.DataFrame.from_dict(preferences, orient='index').reset_index()
        df.rename(columns={'index': 'staff'}, inplace=True)
        df["date"] = date_str

        # Debug print the first few rows of the DataFrame
        print(df)

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

@app.route('/shift', methods=['POST', 'GET'])
def shift():
    data = request.get_json()
    start_date = data.get("start_date")
    end_date = data.get("end_date")
    latitude = data.get("latitude")
    longitude = data.get("longitude")

    # --- Step 1: Predict daily required staff level ---
    creator = ShiftCreator(start_date, end_date, latitude, longitude)

    # Get start/end date objects
    start, end = creator.date_data_from_user()
    if not start or not end:
        return jsonify({"error": "Invalid date range"}), 400
    # Get external data
    festivals = creator.check_festival_range(start, end)  # Check if each day has a festival
    weather_df = creator.weather_data(start, end)         # Get weather data for each day

    # Predict sales and required staff levels
    pred_df = creator.pred_from_model(start, end, festivals, weather_df)
    result_df = creator.pred_staff_count(pred_df)  # Get required staff level by hour for each day

    # --- Step 2: Load staff preferences and staff profile info ---
    # Find the path to the CSVs relative to the current file
    # base_dir = os.path.dirname(os.path.abspath(__file__))
    # data_path_preferences = os.path.normpath(os.path.join(base_dir, '../../data/shift_preferences.csv'))
    # data_path_staff_db    = os.path.normpath(os.path.join(base_dir, '../../data/staff_database.csv'))
    base_dir = os.path.dirname(os.path.dirname(__file__))  # one folder up from flask_back
    data_path_preferences = os.path.join(base_dir, "data", "shift_preferences.csv")
    data_path_staff_db = os.path.join(base_dir, "data", "staff_database.csv")
   

    # Load CSVs
    shift_preferences_df = pd.read_csv(data_path_preferences)
    staff_database_df = pd.read_csv(data_path_staff_db)

    # --- Step 3: Run shift optimization (LP) ---
    shift_operator = ShiftOperator(
        shift_preferences=shift_preferences_df,
        staff_dataBase=staff_database_df,
        required_level=result_df
    )
    shift_schedule = shift_operator.assign_shifts()

    # Convert result to DataFrame for easier formatting
    shift_schedule = pd.DataFrame(shift_schedule)

    # --- Step 4: Return results as JSON-like dict ---
    # Convert predicted staff level (from ML model) to list of dicts
    pred_df_final_end_point = pred_df.to_dict(orient="records")

    # Return both shift schedule and prediction to frontend
    return jsonify({
        "shift_schedule": shift_schedule.to_dict(orient="records"),  # Shift assignment result
        "prediction": pred_df_final_end_point                        # Staff requirement prediction
    }), 200


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
@app.route('/services/staff/<int:staff_id>', methods=['PUT'])
def update_staff_by_id(staff_id):
    try:
        updates = request.get_json()
    
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.abspath(os.path.join(base_dir, '..', 'data', 'staff_dataBase.csv'))
        editor = EditStaff(staff_id = staff_id,updates=updates)
        result = editor.operate()
        return jsonify({"message": f"Staff {result} updated successfully"}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

# -------------------------------
# GET Route for /services/staff/<int:staff_id> kyipyar hlaing
# -------------------------------

@app.route('/services/staff/<int:staff_id>', methods=['GET'])
def get_staff_by_id(staff_id):
    try:
        # Load staff CSV path
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.abspath(os.path.join(base_dir, '..', 'data', 'staff_dataBase.csv'))

        df = pd.read_csv(csv_path)

        # Find staff by ID
        staff = df[df['ID'] == staff_id]

        if staff.empty:
            return jsonify({"error": "Staff not found"}), 404

        # Convert single-row DataFrame to dict
        staff_dict = staff.iloc[0].to_dict()
        return jsonify(staff_dict), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
    




# ---------------------------------------
# Delete staff record by ID
# ---------------------------------------
@app.route('/services/staff/<int:staff_id>', methods=['DELETE'])
      
def delete_staff(staff_id, csv_path="data/staff_dataBase.csv"):
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.join(base_dir, '..', 'data', 'staff_dataBase.csv')
        csv_path = os.path.abspath(csv_path)
        print(f"Looking for CSV at: {csv_path}")
        deleter = DeleteStaff(staff_id=staff_id, csv_path=csv_path)
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

if __name__ == '__main__':
    app.run(debug=True)
