from sqlalchemy.orm import Session
from ..models.shift_pref_model import ShiftPre
from ..utils.db import get_db
from datetime import datetime


class ShiftPreferences:
    def __init__(self, data: dict):
        self.data = data

    @staticmethod
    def change_date(date_str: str):
        return datetime.strptime(date_str, '%Y-%m-%d').date()

    @staticmethod
    def change_time(time_str: str):
        return datetime.strptime(time_str, '%H:%M').time()

    def save_to_shiftPre_db(self):
        if not self.data:
            raise ValueError("No data provided")

        db: Session = next(get_db())

        try:
            new_shift = ShiftPre(
                staff_id=self.data["staff_id"],
                date=self.change_date(self.data["date"]),
                start_time=self.change_time(self.data["start_time"]),
                end_time=self.change_time(self.data["end_time"])
            )

            
            if new_shift.start_time >= new_shift.end_time:
                raise ValueError("start_time must be before end_time")
            
            db.add(new_shift)
            db.commit()
            db.refresh(new_shift)

            return new_shift

        except Exception as e:
            db.rollback()
            raise e


    @staticmethod
    def get_shift_pre():
        db: Session = next(get_db())
        return db.query(ShiftPre).all()