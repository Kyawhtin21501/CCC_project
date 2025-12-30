from flask import Blueprint, request, jsonify
from ..services.shift_ass_manager import ShiftAss

shift_ass_bp = Blueprint("shift_ass" , __name__)

@shift_ass_bp.get("/shift_ass")
def shift_ass():
    data = request.get_json()
    start = data["start_date"]
    end = data["end_date"]
    print("check api " , start ,end)
    s = ShiftAss(start, end)
    new_rows = s.shift_save_db()

    return jsonify(new_rows), 200



@shift_ass_bp.get("/shift_ass_dash_board")
def shift_ass_dash():
    shift_ass_dash = ShiftAss.get_shift_main()
    return jsonify([s.to_dict() for s in shift_ass_dash]), 200