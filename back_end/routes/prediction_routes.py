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

@pred_sales_bp.get("/pred_sales")
def get_pred_for_one_week():
    from datetime import datetime, timedelta

    start = datetime.now() - timedelta(days=1)
    end = start + timedelta(days=7)
    records = GetPred.get_one_week_pred(start, end)
    print(records)
   

    return jsonify([r.to_dict() for r in records]), 200

