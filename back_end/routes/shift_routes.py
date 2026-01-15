from flask import Blueprint, request, jsonify

from datetime import datetime, date,timedelta
from ..services.shift_ass_manager import ShiftAss

shift_ass_bp = Blueprint("shift_ass" , __name__)

@shift_ass_bp.post("/shift_ass")
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
    today = datetime.today().date()
    tomorrow = today + timedelta(days=1)
    day1 , day2 = ShiftAss.get_shift_main(today,tomorrow)
    
  
    return jsonify(day1, day2), 200

@shift_ass_bp.get("/shift_ass_data_main")
def shift_ass_main():
    
    start = request.args.get('start_date')
    end = request.args.get('end_date')
    if not start or not end:
        return "Missing parameters", 400
    shift_ass_main = ShiftAss.get_shift_main(start,end)
    
    return jsonify(shift_ass_main), 200