from sqlalchemy.orm import Session
from ..models.staff_model import Staff
from ..utils.db import get_db

class StaffService:

    status_map = {
        "留学生": "international_student",
        "高校生": "high_school_student",
        "フリーター": "freeter",
        "パートタイム" : "part-time"
    }
    #take all staff data from database for using dashboard or something like that
    
    @staticmethod
    def get_all_staff():
        db: Session = next(get_db())
        return db.query(Staff).all()
    #take one person frome database like searching with staff id 
    
    @staticmethod
    def get_staff_by_id(staff_id: int):
        db: Session = next(get_db())
        return db.query(Staff).filter(Staff.id == staff_id).first()
    
    #create staff data 
    @staticmethod
    def create_staff(data: dict):
        db: Session = next(get_db())

        new_staff = Staff(
            name=data["name"],
            age=data["age"],
            level=data["level"],
            status=data["status"],
            e_mail=data["e_mail"],
            gender = data["gender"]
        )


        db.add(new_staff)
        db.commit()
        db.refresh(new_staff)
        return new_staff

    @staticmethod
    def update_staff(staff_id: int, data: dict):
        db: Session = next(get_db())
        staff = db.query(Staff).filter(Staff.id == staff_id).first()

        if not staff:
            return None

        if "status" in data:
            data["status"] = StaffService.status_map.get(
                data["status"]
            )

        for key, value in data.items():
            setattr(staff, key, value)

        db.commit()
        db.refresh(staff)
        return staff

    @staticmethod
    def delete_staff(staff_id: int):
        db: Session = next(get_db())
        staff = db.query(Staff).filter(Staff.id == staff_id).first()

        if not staff:
            return None

        db.delete(staff)
        db.commit()
        return True
