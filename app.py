#second time updated one and added dummy logic for prediction result ===>kyi pyar hlaing
from flask import Flask, request, jsonify
import pandas as pd
import os
import json
from flask_cors import CORS

app = Flask(__name__)
CORS(app)


@app.route('/')
def home():
    return "API Server is Running"

@app.route('/user_input', methods=['POST'])
def save_data():
    input_row = {
        'date': "2025-06-28",
        'is_festival': True,
        'sales': 20000,
        'guests': 10,
        'staff_count': 2,
        'assigned_staff': ["Alice", "Hannah", "Kevin"]
    }
    staff_data_path = "data/staff_data.csv"
    csv_path = "data/user_input.csv"
    staff_df = pd.read_csv(staff_data_path)
    total_level = 0
    for name in input_row['assigned_staff']:
        match = staff_df[staff_df['Name'] == name]
        if not match.empty:
            total_level += int(match['Level'].values[0])

    input_row['total_staff_level'] = total_level

    df = pd.DataFrame([input_row])

   
    file_exists = os.path.isfile(csv_path)
    df.to_csv(csv_path, mode="a", index=False, header=not file_exists)


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
    app.run(debug=True, host="0.0.0.0", port=5001)


