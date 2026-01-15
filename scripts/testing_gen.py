from faker import Faker
import random
from datetime import date, timedelta, time
from back_end.utils.db import engine
from back_end.models.staff_model import Staff
from back_end.models.shift_pref_model import ShiftPre
 
from sqlalchemy.orm import Session
 
fake = Faker("ja_JP")
 
STATUS_LIST = ["full-time", "part-time","high-school", "international"]
GENDER_LIST = ["Male", "Female"]
 
def random_time_pair_min_5h():
    start_hour = random.randint(9, 14)
    duration = random.randint(5, 8)    
    end_hour = min(start_hour + duration, 23)
    return time(start_hour, 0), time(end_hour, 0)
 
 
 
def create_staff(session: Session, n=25):
    staff_list = []
 
    for _ in range(n):
        status = random.choice(STATUS_LIST)
 
        age = random.randint(18, 25) if status == "international" else random.randint(22, 55)
 
        staff = Staff(
            name=fake.name(),
            age=age,
            level=random.randint(1, 4),
            status=status,
            e_mail=fake.unique.email(),
            gender=random.choice(GENDER_LIST)
        )
        session.add(staff)
        staff_list.append(staff)
 
    session.commit()
    return staff_list
 
 
def create_shift_preferences(session: Session, staff_list):
    today = date.today()
    all_dates = [today + timedelta(days=i) for i in range(14)]  # 1週間
 
    for staff in staff_list:
        
        work_dates = random.sample(all_dates, k=10)
 
        for work_date in work_dates:
            start_time, end_time = random_time_pair_min_5h()
 
            shift = ShiftPre(
                staff_id=staff.id,   # ← 明示的にすると事故らない
                date=work_date,
                start_time=start_time,
                end_time=end_time
            )
            session.add(shift)
 
    session.commit()
 
 
 
def main():
    session = Session(bind=engine)
 
    # 念のため全削除（テスト環境限定）
    session.query(ShiftPre).delete()
    session.query(Staff).delete()
    session.commit()
 
    staff_list = create_staff(session, n=25)
    create_shift_preferences(session, staff_list)
 
    session.close()
    print("✅ test data generated")
 
if __name__ == "__main__":
    main()
 
 