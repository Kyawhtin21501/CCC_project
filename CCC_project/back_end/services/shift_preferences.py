from sqlalchemy.orm import Session
from ..models.shift_pref_model import ShiftPre
from ..utils.db import get_db

class ShiftPreferences:

    @staticmethod
    def save_to_shiftPre_db(data: dict):
        db : Session = next(get_db())
        new_shift= ShiftPre(
                    date = data["date"],
                    name =  data["name"],
                    id  =  data["id"],
                    morning =  data["morning"] ,
                    afternoon =  data["afternoon"],
                    night =  data["night"]
        )
        db.add(new_shift)
        db.commit()
        db.refresh(new_shift)
        
        return  new_shift


