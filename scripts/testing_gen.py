from faker import Faker
import random
from datetime import date, timedelta, time
from back_end.utils.db import engine
from back_end.models.staff_model import Staff
from back_end.models.shift_pref_model import ShiftPre

from sqlalchemy.orm import Session

fake = Faker("ja_JP")

STATUS_LIST = ["full-time","part-time", "international"]
GENDER_LIST = ["male", "female"]

def random_time_pair():
    start_hour = random.randint(9, 16)
    duration = random.choice([2, 3, 4, 5, 6])
    end_hour = min(start_hour + duration, 23)
    return time(start_hour, 0), time(end_hour, 0)


def create_staff(session: Session, n=30):
    staff_list = []

    for _ in range(n):
        status = random.choice(STATUS_LIST)

        age = random.randint(18, 25) if status == "international" else random.randint(22, 55)

        staff = Staff(
            name=fake.name(),
            age=age,
            level=random.randint(1, 5),
            status=status,
            e_mail=fake.unique.email(),
            gender=random.choice(GENDER_LIST)
        )
        session.add(staff)
        staff_list.append(staff)

    session.commit()
    return staff_list


def create_shift_preferences(session: Session, staff_list, days=14):
    today = date.today()

    for staff in staff_list:
        dates = random.sample(
            [today + timedelta(days=i) for i in range(days)],
            k=random.randint(3, days)
        )

        for work_date in dates:
            start_time, end_time = random_time_pair()

            shift = ShiftPre(
                staff=staff,
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

    staff_list = create_staff(session, n=40)
    create_shift_preferences(session, staff_list)

    session.close()
    print("✅ test data generated")

if __name__ == "__main__":
    main()
