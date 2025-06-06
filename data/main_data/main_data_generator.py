import pandas as pd
import random
from datetime import datetime, timedelta

data = []
start_date = datetime(2000, 1, 1)
today = datetime.now()

def calculate_date(start_date, today):
    end_date = datetime(today.year, today.month, today.day)
    days = (end_date - start_date).days + 1
    return days, end_date

def festival_days_set(start_date, today):
    festival_days = set()
    for year in range(2000, today.year + 1):
        base = datetime(year, 1, 1)
        for _ in range(5):
            offset = random.randint(0, 364)
            festival_days.add((base + timedelta(days=offset)).strftime("%Y-%m-%d"))
    return festival_days

def sales_calculation(guests):
    return guests * random.randint(600, 2000)

def staff_assignment(guests):
    members_dict = {
        "Alice": 1, "Bob": 2, "Charlie": 3, "David": 4, "Eve": 5,
        "Frank": 2, "Grace": 3, "Hannah": 4, "Ivy": 5, "Jack": 2,
        "Kevin": 3, "Liam": 4, "Mia": 5, "Noah": 2, "Olivia": 3,
        "Paul": 4, "Quinn": 5, "Riley": 2, "Sophia": 3, "Tyler": 4, "Uma": 5
    }

    required_level_sum = int(guests * 0.1)
    available_members = list(members_dict.items())
    random.shuffle(available_members)

    assigned_staff = []
    current_sum = 0

    for name, level in available_members:
        if current_sum + level > required_level_sum:
            continue
        assigned_staff.append(name)
        current_sum += level
        if current_sum == required_level_sum:
            break

    return assigned_staff, current_sum

days, end_date = calculate_date(start_date, today)
festival_days = festival_days_set(start_date, today)

for i in range(days):
    date = start_date + timedelta(days=i)
    weekday = date.strftime("%A")
    is_weekend = weekday in ['Saturday', 'Sunday']
    date_str = date.strftime("%Y-%m-%d")
    is_festival = date_str in festival_days

    if is_weekend:
        guests = random.randint(100, 400)
    else:
        guests = random.randint(80, 250)

    if is_festival:
        guests += int(guests * 0.7)

    sales = sales_calculation(guests)
    assigned_staff, total_level = staff_assignment(guests)

    data.append({
        "date": date_str,
        "weekday": weekday,
        #"is_weekend": is_weekend,
        "is_festival": is_festival,
        "guests": guests,
        "sales": sales,
        "assigned_staff": assigned_staff,
        "total_staff_level": total_level,
        "staff_count": len(assigned_staff)
    })

df = pd.DataFrame(data)
df.to_csv("project.csv", index=False)
print(df.head())
print("success")
