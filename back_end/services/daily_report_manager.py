from sqlalchemy.orm import Session
from ..models.daily_report_model import Daily_data
from ..utils.db import get_db


class DailyReport:
    
    @staticmethod
    def create_daily_report(data : dict):
        db: Session = next(get_db())
        new_data = Daily_data(
            date = data["date"],
            day  = data["day"],
            is_event=bool(data["event"]),
            customer_count = data["customer_count"],
            sales = data["sales"],
            staff_names = data["staff_names"],
            staff_count = data["staff_count"]
        )
        
        db.add(new_data)
        db.commit()
        db.refresh(new_data)
        return new_data
    
    
    @staticmethod
    def get_daily_report():
        db : Session = next(get_db())
        return db.query(Daily_data).all()