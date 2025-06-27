""" from flask import Flask, request, jsonify
import pandas as pd
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)
@app.route('/')
def home():
    return "API Server is Running"

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()
    input_row = {
        'date': data.get('date'),
        'day': data.get('day'),
        'event': data.get('event'),
        'customer_count': data.get('customer_count'),
        'sales': data.get('sales')
    }
    csv_path = 'data/user_inputs.csv'
    df = pd.DataFrame([input_row])
    df.to_csv(csv_path, mode='a', header=False, index=False)
    return jsonify({
        "data": df["sales"].tolist()
    })

if __name__ == '__main__':
    app.run(debug=True)
"""

#updated one
from flask import Flask, request, jsonify
import pandas as pd
import os
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

CSV_PATH = 'data/user_inputs.csv'

# Ensure directory exists
os.makedirs(os.path.dirname(CSV_PATH), exist_ok=True)

@app.route('/')
def home():
    return "API Server is Running"

# --- Save-only endpoint ---
@app.route('/save', methods=['POST'])
def save_data():
    data = request.get_json()

    input_row = {
        'date': data.get('date'),
        'day': data.get('day'),
        'event': data.get('event'),
        'customer_count': data.get('customer_count'),
        'sales': data.get('sales'),
        'staff_names': str(data.get('staff_names')),  # Convert list to string
        'staff_count': data.get('staff_count'),
        'predicted_staff': None  # No prediction in /save
    }

    df = pd.DataFrame([input_row])
    file_exists = os.path.isfile(CSV_PATH)

    df.to_csv(CSV_PATH, mode='a', header=not file_exists, index=False)
    return jsonify({"message": "Data saved successfully"}), 200

# --- Save + Predict endpoint ---
@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()

    input_row = {
        'date': data.get('date'),
        'day': data.get('day'),
        'event': data.get('event'),
        'customer_count': data.get('customer_count'),
        'sales': data.get('sales'),
        'staff_names': str(data.get('staff_names')),
        'staff_count': data.get('staff_count'),
        'predicted_staff': 4  # Dummy logic
    }

    # Save to CSV
    df = pd.DataFrame([input_row])
    file_exists = os.path.isfile(CSV_PATH)
    df.to_csv(CSV_PATH, mode='a', header=not file_exists, index=False)

    # Dummy prediction result
    predicted_sales = 100000  # Replace with real model if needed

    return jsonify({
        "predicted_sales": predicted_sales,
        "predicted_staff": input_row["predicted_staff"]
    }), 200

if __name__ == '__main__':
    app.run(debug=True)
