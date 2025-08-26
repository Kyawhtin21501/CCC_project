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

# --- 志木駅東口の祭り日（毎年固定） ---
def festival_days_set(start_date, today):
    festival_days = set()
    for year in range(start_date.year, today.year + 1):
        # 志木まつり（7月第3日曜）
        july = datetime(year, 7, 1)
        first_sunday = july + timedelta(days=(6 - july.weekday()) % 7)
        shiki_festival = first_sunday + timedelta(weeks=2)  # 第3日曜
        festival_days.add(shiki_festival.strftime("%Y-%m-%d"))

        # 秋祭り（9月15日固定と仮定）
        festival_days.add(datetime(year, 9, 15).strftime("%Y-%m-%d"))

        # 年末イベント（12月28日）
        festival_days.add(datetime(year, 12, 28).strftime("%Y-%m-%d"))
    return festival_days

# --- 曜日＋祭り別 売上計算 ---
def sales_calculation(weekday, is_festival=False):
    if is_festival:
        # 祭りの日は 300000〜320000円
        return random.randint(300000, 320000)

    if weekday == "Friday":
        # 金曜は 250000～270000円、確率0.1で300000円
        if random.random() < 0.1:
            return 300000
        return random.randint(250000, 270000)
    elif weekday == "Saturday":
        # 土曜は 210000～250000円
        return random.randint(210000, 250000)
    else:
        # 平日は 200000～220000円
        return random.randint(200000, 220000)

# --- スタッフ割り当て ---
def staff_assignment(guests):
    members_dict = {
        "Alice": 1, "Bob": 2, "Charlie": 3, "David": 4, "Eve": 5,
        "Frank": 2, "Grace": 3, "Hannah": 4, "Ivy": 5, "Jack": 2,
        "Kevin": 3, "Liam": 4, "Mia": 5, "Noah": 2, "Olivia": 3,
        "Paul": 4, "Quinn": 5, "Riley": 2, "Sophia": 3, "Tyler": 4, "Uma": 5
    }

    required_level_sum = int(guests * 0.1)  # 客数に応じた必要レベル
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

# --- メイン処理 ---
days, end_date = calculate_date(start_date, today)
festival_days = festival_days_set(start_date, today)

for i in range(days):
    date = start_date + timedelta(days=i)
    weekday = date.strftime("%A")
    date_str = date.strftime("%Y-%m-%d")
    is_festival = date_str in festival_days

    # 来客数
    if weekday in ['Saturday', 'Sunday']:
        guests = random.randint(100, 400)
    else:
        guests = random.randint(80, 250)

    if is_festival:
        guests += int(guests * 0.7)  # 祭りの日は70%増

    # 曜日＋祭りで売上決定
    sales = sales_calculation(weekday, is_festival)

    assigned_staff, total_level = staff_assignment(guests)

    data.append({
        "date": date_str,
        "weekday": weekday,
        "is_festival": is_festival,
        "guests": guests,
        "sales": sales,
        "assigned_staff": assigned_staff,
        "total_staff_level": total_level,
        "staff_count": len(assigned_staff)
    })

df = pd.DataFrame(data)
df.to_csv("project.csv", index=False, encoding="utf-8-sig")

print(df.head(10))
print("success")
