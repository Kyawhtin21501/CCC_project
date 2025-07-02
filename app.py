import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))
from flask import Flask, request, jsonify
from flask_cors import CORS
from services.staff_manager import StaffManager
from services.user_input_handler import UserInputHandler

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


#creating staff profile

@app.route('/testing', methods=['POST'])
def submit_staff():
    data = request.json
    print("Received staff data:", data)
    # Save to DB or process here
    return jsonify({'message': 'Staff profile saved successfully'})

# @app.route('/predict', methods=['POST'])
# def predict():
#     data = request.get_json()


#     customer_count = int(data.get('customer_count', 0))
#     sales = int(data.get('sales', 0))

#     predicted_sales = sales + 10000  # Dummy logic
#     predicted_staff = customer_count // 50 + 1  # Dummy logic

#     return jsonify({
#         "predicted_sales": predicted_sales,
#         "predicted_staff": predicted_staff
#     }), 200
if __name__ == '__main__':
    app.run(debug=True)
  


