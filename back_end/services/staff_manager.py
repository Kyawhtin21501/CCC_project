# services/staff_service.py
from sqlalchemy.orm import Session
from ..models.staff_model import Staff
from ..utils.db import get_db

class StaffService:
   
    #take all staff data frome db
    @staticmethod
    def get_all_staff():
        db: Session = next(get_db())
        return db.query(Staff).all()

    #just only one and forever 
    @staticmethod
    def get_staff_by_id(staff_id: int):
        db: Session = next(get_db())
        return db.query(Staff).filter(Staff.id == staff_id).first()

    # reg new member( insert )
    @staticmethod
    def create_staff(data: dict):
        db: Session = next(get_db())

    # 最後の staff を取得
        last = db.query(Staff).order_by(Staff.id.desc()).first()

        if last is None:
        # 最初の登録なら ID を 1001 に
            new_id = 1001
        else:
            new_id = last.id + 1

        new_staff = Staff(
            id=new_id,
            name=data["name"],
            age=data["age"],
            level=data["level"],
            status=data["status"],
            e_mail=data["e_mail"]
    )

        db.add(new_staff)
        db.commit()
        db.refresh(new_staff)
        return new_staff

    # update/ changing data 
    @staticmethod
    def update_staff(staff_id: int, data: dict):
        db: Session = next(get_db())
        staff = db.query(Staff).filter(Staff.id == staff_id).first()
        if not staff:
            return None

        for key, value in data.items():
            setattr(staff, key, value)

        db.commit()
        db.refresh(staff)
        return staff

    # delete data 
    @staticmethod
    def delete_staff(staff_id: int):
        db: Session = next(get_db())
        staff = db.query(Staff).filter(Staff.id == staff_id).first()
        if not staff:
            return None

        db.delete(staff)
        db.commit()
        return True
