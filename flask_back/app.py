import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from flask import Flask, request, jsonify
from flask_cors import CORS
from services.staff_manager import StaffManager
from services.user_input_handler import UserInputHandler
from services.pred import ShiftCreator
from services.staff_pro import CreateStaff, DeleteStaff, EditStaff, SearchStaff, StaffProfileOperation
from datetime import date, timedelta
import pandas as pd
app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return "API Server is Running"
#Route for datily user input dashboard
@app.route('/user_input', methods=['POST'])
def save_data():
    data = request.get_json()
    staff_manager = StaffManager()
    handler = UserInputHandler(data, staff_manager)
    cleaned_names = handler.process_and_save()
    print(cleaned_names)
    return jsonify({"message": "Data saved successfully"}), 200

# Route for stafflist use in user input dashboard
@app.route('/staff_list', methods=['GET'])
def staff_list():
    try:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.join(base_dir, '..', 'data', 'staff_dataBase.csv')
        csv_path = os.path.abspath(csv_path)
        print(f"Looking for CSV at: {csv_path}")

        # Load CSV
        staff_df = pd.read_csv(csv_path,on_bad_lines='skip')

        # # Correct the header order if necessary
        expected_columns = ['ID', 'Name', 'Level', 'Gender', 'Age', 'Email', 'status']
        if list(staff_df.columns[:7]) != expected_columns:
            print("Reassigning correct headers due to incorrect column order...")
            staff_df.columns = expected_columns

        # Strip whitespace from headers and data
        staff_df.columns = staff_df.columns.str.strip()
        staff_df["Name"] = staff_df["Name"].astype(str).str.strip()

        print("CSV columns:", staff_df.columns.tolist())
        print("First few rows of CSV:")
        print(staff_df.head())

        if "Name" in staff_df.columns:
            names = staff_df["Name"].dropna().unique().tolist()
            print("Names extracted:", names)
            return jsonify(names)
        else:
            return jsonify({"error": "No 'Name' column found"}), 400
    except Exception as e:
        print("Error in /staff_list:", str(e))
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

        # 保存先のCSVファイルパス
        base_dir = os.path.dirname(os.path.abspath(__file__))
        csv_path = os.path.join(base_dir, '..', 'data', 'shift_preferences.csv')

        # データを整形して保存
        df = pd.DataFrame.from_dict(preferences, orient='index').reset_index()
        df.rename(columns={'index': 'staff'}, inplace=True)
        df["date"] = date_str

        # 追記モードで保存
        df.to_csv(csv_path, mode='a', header=not os.path.exists(csv_path), index=False, encoding='utf-8-sig')

        return jsonify({"message": "Shift preferences saved"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    

# Route for shift prediction and create shift page
@app.route('/shift', methods=['POST'])
def shift():
    data = request.get_json()
    start_date = data.get("start_date")
    end_date = data.get("end_date")
    latitude = data.get("latitude")
    longitude = data.get("longitude")
    
    
    creator = ShiftCreator(start_date, end_date, latitude, longitude)
    start, end = creator.date_data_from_user()

    if not start or not end:
        return jsonify({"error": "Invalid date format"}), 400

    festivals = creator.check_festival_range(start, end)
    weather_df = creator.weather_data(start, end)
    pred_df = creator.pred_from_model(start, end, festivals, weather_df)
    result_df = creator.pred_staff_count(pred_df)

    result_json = result_df.to_dict(orient="records")
    return jsonify(result_json), 200



    
    
#testing stage / predict sale and staff count for dashboard/prediction_result_screen.dart
@app.route('/services/sale_prediction_staff_count', methods=['POST'])
def result_log():
    data = request.get_json()
    if data:
        start_date = date.today()
        end_date = start_date + timedelta(days=1)
        latitude = data.get("latitude", 35.6895)  # Default to Tokyo
        longitude = data.get("longitude", 139.6917) # Default to Tokyo
        predator = ShiftCreator(start_date=start_date.strftime("%Y-%m-%d"),
            end_date=end_date.strftime("%Y-%m-%d"),
            latitude=latitude,
            longitude=longitude
        )
        start ,end = predator.date_data_from_user()
        festivals = predator.check_festival_range(start, end)
        weather_df = predator.weather_data(start, end)
        pred_df = predator.pred_from_model(start, end, festivals, weather_df)
        result_df = predator.pred_staff_count(pred_df)

        result_json = result_df.to_dict(orient="records")
        print(result_json)
        
        return jsonify(result_json,pred_df), 200
    else:
        return jsonify({"error": "No data provided"}), 400


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


#testing stage/ staff profile operations
@app.route('/services/staff/<int:staff_id>', methods=['PUT'])
def edit_staff(staff_id):
    updates = request.get_json()
    try:
        editor = EditStaff(staff_id=staff_id, updates=updates)
        result = editor.operate()
        return jsonify({"message": f"Staff {result} updated successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


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


@app.route('/services/staff/search', methods=['GET'])
def search_staff():
    term = request.args.get("term")
    by = request.args.get("by", "ID")
    try:
        searcher = SearchStaff(search_term=term, by=by)
        result = searcher.operate()
        if result == "error":
            return jsonify({"message": "Not found"}), 404
        return jsonify(result), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400
if __name__ == '__main__':
    app.run(debug=True)
