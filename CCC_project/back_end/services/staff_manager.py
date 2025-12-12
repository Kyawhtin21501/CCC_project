# services/staff_service.py
from sqlalchemy.orm import Session
from ..models.staff_model import Staff
from back_end.utils.db import get_db

class StaffService:

    # 全てのスタッフ取得
    @staticmethod
    def get_all_staff():
        db: Session = next(get_db())
        return db.query(Staff).all()

    # 1人のスタッフ取得
    @staticmethod
    def get_staff_by_id(staff_id: int):
        db: Session = next(get_db())
        return db.query(Staff).filter(Staff.id == staff_id).first()

    # 新規スタッフ追加 (INSERT)
    @staticmethod
    def create_staff(data: dict):
        db: Session = next(get_db())
        new_staff = Staff(
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

    # スタッフ更新 (UPDATE)
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

    # スタッフ削除 (DELETE)
    @staticmethod
    def delete_staff(staff_id: int):
        db: Session = next(get_db())
        staff = db.query(Staff).filter(Staff.id == staff_id).first()
        if not staff:
            return None

        db.delete(staff)
        db.commit()
        return True
