import pandas as pd
import numpy as np

np.random.seed(42)

# 期間設定（約6か月分）
dates = pd.date_range(start="2022-04-01", end="2022-09-30")

# 各特徴量の生成
weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
weathers = ["Sunny", "Cloudy", "Rainy", "Snowy"]
seasons = {"04": "Spring", "05": "Spring", "06": "Summer", "07": "Summer", "08": "Summer", "09": "Autumn"}

data = []
for date in dates:
    month = date.month
    day = date.day
    weekday = date.day_name()
    season = seasons[f"{month:02d}"]

    # 気温（季節によって変動）
    if season == "Spring":
        temp = np.random.normal(18, 3)
    elif season == "Summer":
        temp = np.random.normal(28, 4)
    else:  # Autumn
        temp = np.random.normal(22, 3)
    
    # 雨（mm）
    rain = max(0, np.random.normal(3 if np.random.rand() > 0.7 else 0, 2))

    # 祭りの日（たまに）
    festival = 1 if np.random.rand() < 0.1 else 0

    # 天気
    weather = np.random.choice(weathers, p=[0.4, 0.3, 0.25, 0.05])

    # 売上（要因ごとの重み付け）
    base_sales = 200000
    if weekday in ["Saturday", "Sunday"]:
        base_sales += 40000
    if weather == "Rainy":
        base_sales -= 15000
    if weather == "Sunny":
        base_sales += 10000
    if festival == 1:
        base_sales += np.random.randint(30000, 60000)
    base_sales += (temp - 22) * 1500  # 暑いとき少し上がる
    base_sales += np.random.normal(0, 8000)  # ノイズ

    sales = np.clip(base_sales, 150000, 300000)  # 指定範囲に制限

    data.append([date, sales, month, day, weekday, temp, rain, weather, festival, season])

# DataFrame 化
df = pd.DataFrame(data, columns=["date", "sales", "month", "day", "weekday", "temperature", "rain", "weather", "festival", "season"])

# 保存
df.to_csv("complex_restaurant_sales.csv", index=False)

print("✅ データ生成完了: complex_restaurant_sales.csv")
print(df.head())
