import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from flask import Flask, request, jsonify
from flask_cors import CORS
from services.staff_manager import StaffManager
from services.user_input_handler import UserInputHandler
from services.pred import ShiftCreator
from services.staff_pro import CreateStaff, DeleteStaff, EditStaff, SearchStaff, StaffProfileOperation

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
        staff_df = pd.read_csv("data/staff_dataBase.csv")
        if "Name" in staff_df.columns:
            names = staff_df["Name"].dropna().unique().tolist()
            return jsonify(names)
        else:
            return jsonify({"error": "No 'name' column found"}), 400
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


#Staff Profile CURD funcitons
@app.route('/services/staff', methods=['POST'])
def create_staff():
    data = request.get_json()
    try:
        new_staff = CreateStaff(
            name=data["name"],
            level=data["level"],
            gender=data["gender"],
            age=data["age"],
            email=data["email"]
        )
        result = new_staff.operate()
        return jsonify({"message": f"Staff created: {result}"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 400


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
def delete_staff(staff_id):
    try:
        deleter = DeleteStaff(staff_id=staff_id)
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

