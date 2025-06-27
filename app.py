#second time updated one and added dummy logic for prediction result ===>kyi pyar hlaing
from flask import Flask, request, jsonify
import pandas as pd
import os
import json
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

CSV_PATH = 'data/user_inputs.csv'
os.makedirs(os.path.dirname(CSV_PATH), exist_ok=True)

@app.route('/')
def home():
    return "API Server is Running"

@app.route('/save', methods=['POST'])
def save_data():
    data = request.get_json()

    input_row = {
        'date': data.get('date'),
        'day': data.get('day'),
        'event': data.get('event'),
        'customer_count': data.get('customer_count'),
        'sales': data.get('sales'),
        'staff_names': json.dumps(data.get('staff_names')),
        'staff_count': data.get('staff_count'),
        'predicted_staff': None
    }

    df = pd.DataFrame([input_row])
    file_exists = os.path.isfile(CSV_PATH)
    df.to_csv(CSV_PATH, mode='a', header=not file_exists, index=False)

    return jsonify({"message": "Data saved successfully"}), 200

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()

    # No saving to CSV here
    customer_count = int(data.get('customer_count', 0))
    sales = int(data.get('sales', 0))
# add real result in here
    predicted_sales = sales + 10000  # Dummy logic
    predicted_staff = customer_count // 50 + 1  # Dummy logic

    return jsonify({
        "predicted_sales": predicted_sales,
        "predicted_staff": predicted_staff
    }), 200
if __name__ == '__main__':
    app.run(debug=True)

