from flask import Blueprint, request, jsonify
from ..services.pred_manager import DataPrepare ,GetPred

pred_sales_bp = Blueprint("pred_sales", __name__)

@pred_sales_bp.post("/pred_sales")
def create_pred_sale():
    data = request.get_json()
    if not data:
        return jsonify({"error: invalid date"}), 400
    start = data["start_date"]
    end = data["end_date"]
    new_p = DataPrepare(start,end)
    result = new_p.run_prediction()
    return jsonify(result), 201

@pred_sales_bp.post("/pred_sales_dash")
def get_pred_for_one_week():
    from datetime import datetime, timedelta
    date_format="%Y-%m-%d"
    start = datetime.now() - timedelta(days=1)
    
    end = start + timedelta(days=7)
    start = datetime.strftime(start,date_format)
    end = datetime.strftime(end,date_format)
    records = DataPrepare(start, end)
    result = records.run_prediction()
    
   

    return jsonify(result), 200

