from flask import Flask, request, jsonify
import pandas as pd
import os
from datetime import datetime

app = Flask(__name__)

@app.route('/predict', methods=['POST'])
def predict():
    data = request.get_json()

    # Extract input fields
    input_row = {
        'date': data.get('date'),
        'day': data.get('day'),
        'event': data.get('event'),
        'customer_count': data.get('customer_count'),
        'sales': data.get('sales')
    }

    # Save to CSV
    csv_path = 'userinput.csv'
    df = pd.DataFrame([input_row])
    
    # Append or create new
    if os.path.exists(csv_path):
        df.to_csv(csv_path, mode='a', header=False, index=False)
    else:
        df.to_csv(csv_path, mode='w', header=True, index=False)

    # Return dummy prediction (replace with your model)
    return jsonify({
        'predicted_sales': 9999,
        'predicted_staff': 5
    })

