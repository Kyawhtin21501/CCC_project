# import sys
# import os
# sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
# from flask import Flask, request, jsonify
# from flask_cors import CORS
# from services.staff_manager import StaffManager
# from services.user_input_handler import UserInputHandler
# from services.pred import ShiftCreator
# from services.staff_pro import CreateStaff, StaffProfileOperation
# app = Flask(__name__)
# CORS(app)


# @app.route('/')
# def home():
#     return "API Server is Running"

# @app.route('/user_input', methods=['POST'])
# def save_data():
#     data = request.get_json()
#     staff_manager = StaffManager()
#     handler = UserInputHandler(data, staff_manager)
#     cleaned_names = handler.process_and_save()
#     print(cleaned_names)
#     return jsonify({"message": "Data saved successfully"}), 200


# #creating staff profile

# @app.route('/services/testing', methods=['POST'])
# def submit_staff():
#     try:
#         data = request.json
#         name = data.get('name')
#         level = int(data.get('level'))
#         gender = data.get('gender')
#         age = int(data.get('age'))
#         email = data.get('email')

#         staff_creator = CreateStaff(name, level, gender, age, email)
#         result = staff_creator.operate()

#         return jsonify({'message': f'Staff created: {result}'}), 200
#     except Exception as e:
#         return jsonify({'error': str(e)}), 500






# @app.route('/shift', methods=['POST'])

# @app.route('/shift', methods=['POST'])
# def shift():
#     data = request.get_json()
    
#     start_date = data.get("start_date")
#     end_date = data.get("end_date")
#     latitude = data.get("latitude")
#     longitude = data.get("longitude")

#     creator = ShiftCreator(start_date, end_date, latitude, longitude)
#     start, end = creator.date_data_from_user()

#     if not start or not end:
#         return jsonify({"error": "Invalid date format"}), 400

#     festivals = creator.check_festival_range(start, end)
#     weather_df = creator.weather_data(start, end)
#     pred_df = creator.pred_from_model(start, end, festivals, weather_df)
#     result_df = creator.pred_staff_count(pred_df)

#     result_json = result_df.to_dict(orient="records")

#     return jsonify(result_json), 200
    
# if __name__ == '__main__':
#     app.run(debug=True)
  


import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from flask import Flask, request, jsonify
from flask_cors import CORS
from services.staff_manager import StaffManager
from services.user_input_handler import UserInputHandler
from services.pred import ShiftCreator
from services.staff_pro import CreateStaff, StaffProfileOperation
import pandas as pd
app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return "API Server is Running"

@app.route('/user_input', methods=['POST'])
def save_data():
    data = request.get_json()
    staff_manager = StaffManager()
    handler = UserInputHandler(data, staff_manager)
    cleaned_names = handler.process_and_save()
    print(cleaned_names)
    return jsonify({"message": "Data saved successfully"}), 200

@app.route('/services/testing', methods=['POST'])
def submit_staff():
    try:
        data = request.json
        name = data.get('name')
        level = int(data.get('level'))
        gender = data.get('gender')
        age = int(data.get('age'))
        email = data.get('email')

        staff_creator = CreateStaff(name, level, gender, age, email)
        result = staff_creator.operate()

        return jsonify({'message': f'Staff created: {result}'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

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

@app.route('/staff_list', methods=['GET'])
def staff_list():
    data_path = "data/staff_data.csv"
    staff_df = pd.DataFrame(data_path)
    staff_data = staff_df.values()
    return jsonify(staff_data)

if __name__ == '__main__':
    app.run(debug=True)

