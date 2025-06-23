from flask import Flask, request, jsonify
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
    csv_path = 'data/user_input.csv'
    df = pd.DataFrame([input_row])
    df.to_csv(csv_path, mode='a', header=False, index=False)
    return jsonify({
        "data": df["sales"].tolist()
    })

if __name__ == '__main__':
    app.run(debug=True)
