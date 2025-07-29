import sys
import os
from datetime import date, timedelta
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS

# Add the parent directory to sys.path so that we can import custom modules from /services
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Import all necessary service modules
from services.staff_manager import StaffManager
from services.user_input_handler import UserInputHandler
from services.pred import ShiftCreator
from services.staff_pro import CreateStaff, DeleteStaff, EditStaff, SearchStaff, StaffProfileOperation
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
    return jsonify({"message": "Data saved successfully"}), 200

# Route for stafflist use in user input dashboard
# @app.route('/staff_list', methods=['GET'])
# def staff_list():
#     try:
#         staff_df = pd.read_csv("data/staff_dataBase.csv")
#         if "Name" in staff_df.columns:
#             names = staff_df["Name"].dropna().unique().tolist()
#             return jsonify(names)
#         else:
#             return jsonify({"error": "No 'name' column found"}), 400
#     except Exception as e:
#         return jsonify({"error": str(e)}), 500


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
    try:
        data = request.get_json()
        date_str = data.get("date")
        preferences = data.get("preferences")

        if not date_str or not preferences:
            return jsonify({"error": "Invalid data"}), 400

        # Convert preference dictionary to DataFrame
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.join(base_dir, '..', 'data', 'shift_preferences.csv')

        df = pd.DataFrame.from_dict(preferences, orient='index').reset_index()
        df.rename(columns={'index': 'staff'}, inplace=True)
        df["date"] = date_str

        # Append to CSV (create header if file doesn't exist)
        df.to_csv(csv_path, mode='a', header=not os.path.exists(csv_path), index=False, encoding='utf-8-sig')
        return jsonify({"message": "Shift preferences saved"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

# ---------------------------------------
# Predict sales and assign shifts based on input dates and location
# ---------------------------------------
@app.route('/shift', methods=['POST'])
def shift():
    data = request.get_json()
    start_date = data.get("start_date")
    end_date = data.get("end_date")
    latitude = data.get("latitude")
    longitude = data.get("longitude")

    # Step 1: Use ShiftCreator to predict staff level needed
    creator = ShiftCreator(start_date, end_date, latitude, longitude)
    start, end = creator.date_data_from_user()

    if not start or not end:
        return jsonify({"error": "Invalid date format"}), 400

    festivals = creator.check_festival_range(start, end)
    weather_df = creator.weather_data(start, end)
    pred_df = creator.pred_from_model(start, end, festivals, weather_df)
    result_df = creator.pred_staff_count(pred_df)

    # Step 2: Load staff preferences and profiles
    shift_pre_df = pd.read_csv("../data/shift_preferences.csv")
    staff_db_df = pd.read_csv("../data/staff_dataBase.csv")

    # Step 3: Assign shifts using LP optimization
    shift_operator = ShiftOperator(
        shift_preferences=shift_pre_df,
        staff_dataBase=staff_db_df,
        required_level=result_df
    )
    shift_schedule = shift_operator.assign_shifts()

    # Step 4: Return assigned schedule as JSON
    return jsonify(shift_schedule.to_dict(orient="records")), 200

# ---------------------------------------
# Predict sales and staff count for tomorrow (used in dashboard preload)
# ---------------------------------------
@app.route('/services/sale_prediction_staff_count', methods=['POST'])
def result_log():
    data = request.get_json()
    if data:
        start_date = date.today()
        end_date = start_date + timedelta(days=1)

        predator = ShiftCreator(
            start_date=start_date.strftime("%Y-%m-%d"),
            end_date=end_date.strftime("%Y-%m-%d"),
            latitude=data.get("latitude", 35.6895),  # Default: Tokyo
            longitude=data.get("longitude", 139.6917)
        )

        start, end = predator.date_data_from_user()
        festivals = predator.check_festival_range(start, end)
        weather_df = predator.weather_data(start, end)
        pred_df = predator.pred_from_model(start, end, festivals, weather_df)
        result_df = predator.pred_staff_count(pred_df)

        return jsonify(result_df.to_dict(orient="records")), 200
    else:
        return jsonify({"error": "No data provided"}), 400

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
# @app.route('/services/staff/<int:staff_id>', methods=['PUT'])
# def edit_staff(staff_id):
#     updates = request.get_json()
#     try:
#         editor = EditStaff(staff_id=staff_id, updates=updates)
#         result = editor.operate()
#         return jsonify({"message": f"Staff {result} updated successfully"}), 200
#     except Exception as e:
#         return jsonify({"error": str(e)}), 400


# ---------------------------------------
# Edit existing staff info by ID  -->kyipyar hlaing
# ---------------------------------------
@app.route('/services/staff/<int:staff_id>', methods=['PUT'])
def update_staff_by_id(staff_id):
    try:
        updates = request.get_json()

        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.abspath(os.path.join(base_dir, '..', 'data', 'staff_dataBase.csv'))

        df = pd.read_csv(csv_path)

        # Check if staff exists
        if staff_id not in df['ID'].values:
            return jsonify({'error': 'Staff not found'}), 404

        # Update the fields
        df.loc[df['ID'] == staff_id, updates.keys()] = list(updates.values())

        # Save the updated CSV
        df.to_csv(csv_path, index=False)

        return jsonify({'message': 'Staff updated successfully'}), 200

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
