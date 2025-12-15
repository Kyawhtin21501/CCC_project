from flask import Blueprint, request, jsonify
from ..services.shift_preferences import ShiftPreferences

shift_pre_bp = Blueprint("shift_pre" , __name__)

@shift_pre_bp.post("/shift_pre")
def save_shift_pre():
    data = request.json
    new_shift_pre = ShiftPreferences.save_to_shiftPre_db(data)

    return jsonify(new_shift_pre.to_dict()), 201
