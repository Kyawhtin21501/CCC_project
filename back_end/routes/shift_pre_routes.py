from flask import Blueprint, request, jsonify
from sqlalchemy.exc import IntegrityError
from ..services.shift_preferences import ShiftPreferences
shift_pre_bp = Blueprint("shift_pre", __name__)

@shift_pre_bp.post("/shift_pre")

def save_shift_pre():
    data = request.get_json()


    if not data:
        return jsonify({
            "error": "Bad Request",
            "message": "JSON body is required"
        }), 400

    try:
        service = ShiftPreferences(data)
        new_shift_pre = service.save_to_shiftPre_db()

        return jsonify(new_shift_pre.to_dict()), 201

    except ValueError as e:
        return jsonify({
            "error": "Validation Error",
            "message": str(e)
        }), 422


    except IntegrityError:
        return jsonify({
            "error": "Validation Error",
            "message": "Shift already exists for this staff and date"
        }), 422


    except Exception as e:
        
        return jsonify({
            
            "error": "Internal Server Error"
        }), 500
        
        
@shift_pre_bp.get("/shift_pre")
def get_shift_pre():
    shift_d = ShiftPreferences.get_shift_pre()
    return jsonify([r.to_dict() for r in shift_d]), 200