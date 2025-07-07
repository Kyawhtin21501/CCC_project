import sys
import os
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from flask import Flask, request, jsonify
from flask_cors import CORS

from services.staff_manager import StaffManager
from services.user_input_handler import UserInputHandler
#from services.predictor import Predictor

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

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    predictor = Predictor(data.get('customer_count', 0), data.get('sales', 0))
    return jsonify({
        "predicted_sales": predictor.predict_sales(),
        "predicted_staff": predictor.predict_staff()
    }), 200

if __name__ == '__main__':
    app.run(debug=True)
