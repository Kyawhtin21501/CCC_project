from flask import Blueprint, request, jsonify
from ..services.daily_report_manager import DailyReport

daily_report_bp = Blueprint("daily_report", __name__)

@daily_report_bp.post("/daily_report")
def create_new_daily():
    data = request.get_json()
    print(data)
    if not data:
        return jsonify({"error": "invalid json"}), 400
    new_d = DailyReport.create_daily_report(data)
    return jsonify(new_d.to_dict()), 201
    
@daily_report_bp.get("/daily_report")
def get_dr_data():
    dr = DailyReport.get_daily_report()
    return jsonify([d.to_dict() for d in dr]), 200
    