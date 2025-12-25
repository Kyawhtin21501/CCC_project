from flask import Blueprint, request, jsonify
from ..services.shift_ass_manager import ShiftAss

shift_ass_bp = Blueprint("shift_ass" , __name__)

@shift_ass_bp.post("/shift_ass")
def shift_ass():
    data = request.get_json()
    start = data["start_date"]
    end = data["end_date"]

    s = ShiftAss(start, end)
    new_rows = s.shift_save_db()

    return jsonify(new_rows), 200



