# from sqlalchemy.orm import Session
# from pprint import pprint
# import pandas as pd
# import numpy as np
# from datetime import datetime, timedelta, date

# from ortools.sat.python import cp_model

# from back_end.models.shift_model import ShiftMain
# from back_end.utils.db import get_db
# from back_end.services.staff_manager import StaffService
# from back_end.services.shift_preferences import ShiftPreferences
# from back_end.services.pred_manager import DataPrepare


# class ShiftAss:
#     def __init__(self,start_date,end_date):
#         self.start_date = start_date
#         self.end_date = end_date
#         self.help_id = 1500  
#         self.model = cp_model.CpModel()
#         self.work = {}
#         self.cost = {}
#         self.max_cost = {}

#     # =========================================================
#     # STAFF DATA
#     # =========================================================
#     def get_staff_data_df(self):
#         staff = StaffService.get_all_staff()
#         df = pd.DataFrame([s.to_dict() for s in staff])
       
#         return df

#     # =========================================================
#     # SHIFT PREFERENCES
#     # =========================================================
#     def get_shift_pre_df(self):
#         shift_pre = ShiftPreferences.get_shift_pre()
#         df = pd.DataFrame([s.to_dict() for s in shift_pre])

#         df["date"] = pd.to_datetime(df["date"])
#         df = df[
#             (df["date"] >= pd.to_datetime(self.start_date)) &
#             (df["date"] <= pd.to_datetime(self.end_date))
#         ]

#         df = df.rename(columns={"staff_id": "id"})
#         return df

#     # =========================================================
#     # PREDICTED SALES
#     # =========================================================
#     def get_pred_sale(self):
#         pred = DataPrepare(self.start_date, self.end_date)
#         df = pd.DataFrame(pred.run_prediction())
#         df["date"] = pd.to_datetime(df["date"])
#         return df

#     # =========================================================
#     # HELPERS
#     # =========================================================
#     def pred_sales_per_hour(self, hour, sales):
#         if hour in [9, 10]:
#             return sales * 0.052
#         elif hour in [12, 13, 14, 15]:
#             return sales * 0.1
#         elif hour in [16, 17]:
#             return sales * 0.07
#         elif hour in [18, 19, 20 ,23]:
#             return sales * 0.08
#         else:
#             return sales * 0.09

#     def salary(self, level):
#         if level in [1, 2]:
#             return 1200
#         elif level == 3:
#             return 1250
#         elif level == 4:
#             return 1400
#         else:
#             return 1500

#     # =========================================================
#     # COMBINE DATA
#     # =========================================================
#     def combine_data(self):
#         df = pd.merge(
#             self.get_shift_pre_df(),
#             self.get_staff_data_df(),
#             how="left",
#             on="id"
#         )

#         df = pd.merge(
#             df,
#             self.get_pred_sale(),
#             how="left",
#             on="date"
#         )

#         # NaN cleanup
#         df["name"] = df["name"].fillna("unknown")
#         df["level"] = df["level"].fillna(0).astype(int)
#         df["status"] = df["status"].fillna("unknown")
#         df["predicted_sales"] = df["predicted_sales"].fillna(0)

#         records = []
#         for _, row in df.iterrows():
#             for h in range(9, 25):
#                 records.append({
#                     "date": row["date"],
#                     "hour": h,
#                     "id": row["id"],
#                     "name": row["name"],
#                     "level": row["level"],
#                     "status": row["status"],
#                     "predicted_sales": row["predicted_sales"],
#                 })
#         unique_dates = df["date"].unique()
#         for d in unique_dates:
#             pred_val = df[df["date"] == d]["predicted_sales"].values[0] if not df[df["date"] == d].empty else 0
#             for h in range(9, 25):
#                 records.append({
#                     "date": d, "hour": h, "id": 1500,
#                     "name": "not_enough", "level": 0, "salary": 0, 
#                     "predicted_sales": pred_val
#                 })
#         final_df = pd.DataFrame(records)

#         final_df["pred_sale_per_hour"] = final_df.apply(
#             lambda r: self.pred_sales_per_hour(r["hour"], r["predicted_sales"]),
#             axis=1
#         )
#         """
#         final_df["max_cost"] = (
#             final_df["pred_sale_per_hour"] * 0.3
#         ).astype(int)
#         """
#         final_df["salary"] = final_df["level"].apply(self.salary).astype(int)

#         final_df = final_df.sort_values(
#             by=["date", "hour", "id"]
#         ).reset_index(drop=True)

#         return final_df

#     # =========================================================
#     # CREATE SHIFT (CP-SAT)
#     # =========================================================
#     def create_shift(self, df=None):
#         model = cp_model.CpModel()
#         if df is None:
#             df = self.combine_data()
        
#         # 決定変数
#         work = {}
#         for _, row in df.iterrows():
#             s, d, h = row["id"], row["date"], row["hour"]
#             work[s, d, h] = model.NewBoolVar(f"work_{s}_{d}_{h}")

#         # スタッフ属性の辞書化 (高速化のため)
#         staff_info = df.drop_duplicates('id').set_index('id')[['level', 'status']].to_dict('index')
#         staff_ids = df["id"].unique()
#         dates = df["date"].unique()

#         for (d, h), group in df.groupby(["date", "hour"]):
#             sales = group["pred_sale_per_hour"].iloc[0]
            
#             # 1. 必要人数の確保 (5000円に1人)
#             num_staff = max(1, int(sales // 5000))
#             slot_vars = [work[row["id"], d, h] for _, row in group.iterrows()]
#             model.Add(sum(slot_vars) == num_staff) 

#             # 2. 責任者制約 (L4以上 or Help)
         

#             # 3. Level 3 枠の制約 (L3がいなければL5、L5もいなければHelp)
#             # 「L3 or L5 or Help」が1人以上
        
#             l4_vars = [work[row["id"], d, h] for _, row in group.iterrows() 
#                        if row["id"] == self.help_id
#                        or staff_info.get(row["id"], {}).get('level') in [3 , 4 ,5]
#                        ]
#             model.Add(sum(l4_vars) >= 1)
#         """
#             # 3. Level 3 枠の制約 (L3 or L5 or Help が必須)
#             l3_vars = [work[row["id"], d, h] for _, row in group.iterrows() 
#                        if  
#                        or staff_info.get(row["id"], {}).get('level') == 5 
#                        or row["id"] == self.help_id]
#             model.Add(sum(l3_vars) >= 1)
#         """
#         # 3. 個別・連続性ルール
#         for s in staff_ids:
#             if s == self.help_id: continue
#             status = staff_info.get(s, {}).get('status', 'unknown')
#             if status == "international":
#                 # このスタッフの全日付・全時間のwork変数を合計
#                 weekly_vars = [work[sid, d, h] for (sid, d, h) in work.keys() if sid == s]
#                 model.Add(sum(weekly_vars) <= 28)
                
#             for d in dates:
#                 day_hours = range(9, 25)
#                 # この日のこの人の全勤務変数
#                 d_vars = [work[s, d, h] for h in day_hours if (s, d, h) in work]
#                 if not d_vars: continue
                
#                 # 【1時間限定の休憩】を検知する変数
#                 break_starts = []
#                 for h in day_hours:
#                     if (s, d, h) not in work: continue
#                     if status == "high_school" and h >= 22:
#                         model.Add(work[s, d, h] == 0)
#                     # --- 休憩検知 (1->0) ---
#                     if h > 9 and (s, d, h-1) in work:
#                         is_brk = model.NewBoolVar(f'brk_{s}_{d}_{h}')
#                         # 直前が1 かつ 今が0 の時だけ is_brk=1
#                         model.Add(is_brk >= work[s, d, h-1] - work[s, d, h])
#                         break_starts.append(is_brk)
#                         # 休憩は1時間だけ（次は必ず仕事に戻る）
#                         if (s, d, h+1) in work:
#                             model.Add(work[s, d, h+1] >= is_brk)

#                     # --- 【重要】連続勤務は最大5時間まで（6時間連続勤務を禁止） ---
#                     # 誰であっても、6時間連続で「1」が続くことを数学的に禁止する
#                     window_6 = [work[s, d, h + i] for i in range(6) if (s, d, h + i) in work]
#                     if len(window_6) == 6:
#                         model.Add(sum(window_6) <= 5) # 6時間のうち仕事は5時間以内＝必ず1時間は休む

#                 # --- 1日の合計が6時間を超えたら、必ず1回は休憩を「開始」させる ---
#                 if break_starts:
#                     # 休憩開始（1->0）の合計回数を「最大2回」に制限
#                     model.Add(sum(break_starts) <= 3)

#                 # 4. 6時間超えの勤務なら最低1回は休憩を入れる
#                 total_w = sum(work[s, d, h] for h in day_hours)
#                 has_long_shift = model.NewBoolVar(f'long_{s}_{d}')
#                 model.Add(total_w > 6).OnlyEnforceIf(has_long_shift)
#                 model.Add(total_w <= 6).OnlyEnforceIf(has_long_shift.Not())
#                 if break_starts:
#                     model.Add(sum(break_starts) >= 1).OnlyEnforceIf(has_long_shift)
                   
               

#         # 4. 目的関数
#         obj_terms = []
#         for (s, d, h), w in work.items():
#             if s == self.help_id:
#                 obj_terms.append(w * 1000)
#             else:
#                 obj_terms.append(w * 1)

#         model.Minimize(sum(obj_terms))
#         solver = cp_model.CpSolver()
#         solver.parameters.max_time_in_seconds = 10
#         status = solver.Solve(model)
#         return solver, status, work

#     def run(self):
#         df = self.combine_data()
#         solver, status, work = self.create_shift(df)
        
#         # スタッフ情報をIDで引けるように辞書化
#         staff_data = self.get_staff_data_df().set_index('id').to_dict('index')
        
#         shift_results = []  
#         if status in (cp_model.OPTIMAL, cp_model.FEASIBLE):
#             for (s, d, h), w in work.items():
#                 if solver.Value(w) == 1:
#                     info = staff_data.get(s, {"name": "not_enough", "level": 0, "status": "help"})
#                     shift_results.append({
#                         "staff_id": s,
#                         "date": d,
#                         "hour": h,
#                         "name": info["name"],
#                         "level": info["level"],
#                         "status": info["status"],
#                         "salary": self.salary(info["level"])
#                     })
#         return pd.DataFrame(shift_results)

#     def shift_save_db(self):
#         df = self.run()
#         if df.empty:
            
#             return "保存するデータがありません"

#         db: Session = next(get_db())
#         try:
#             # 対象期間を削除
#             db.query(ShiftMain).filter(
#                 ShiftMain.date >= self.start_date,
#                 ShiftMain.date <= self.end_date
#             ).delete()
            
#             objs = []
#             for row in df.itertuples(index=False):
#                 objs.append(
#                     ShiftMain(
#                         date=row.date,
#                         hour=int(row.hour),
#                         staff_id=int(row.staff_id), 
#                         name=row.name,
#                         level=int(row.level),
#                         status=row.status, 
#                         salary=int(row.salary)
#                     )
#                 )
#             db.add_all(objs)
#             db.commit()
#             return df.to_dict(orient="records")
#         except Exception as e:
#             db.rollback()
#             print(f"Error saving to DB: {e}")
#             return []
           




#     @staticmethod
#     def get_shift_main():
       
#         today = datetime.today().date()
#         tomorrow = today + timedelta(days=1)
        
        
        
#         #print(today , tomorrow)
#         db : Session = next(get_db())
#         data = db.query(ShiftMain).filter(
#                     ShiftMain.date >= today,
#                     ShiftMain.date <= tomorrow
#                 ).all()
#         if not data:
#             print("該当シフトはありません")
#         else:
#             for d in data:
#                 print(d)
#         return  data
        
from sqlalchemy.orm import Session
import pandas as pd
from datetime import datetime, timedelta

from ortools.sat.python import cp_model

from back_end.models.shift_model import ShiftMain
from back_end.utils.db import get_db
from back_end.services.staff_manager import StaffService
from back_end.services.shift_preferences import ShiftPreferences
from back_end.services.pred_manager import DataPrepare


class ShiftAss:
    def __init__(self, start_date, end_date):
        self.start_date = start_date
        self.end_date = end_date
        self.help_id = 1500

    # =========================================================
    # STAFF DATA
    # =========================================================
    def get_staff_data_df(self):
        staff = StaffService.get_all_staff()
        return pd.DataFrame([s.to_dict() for s in staff])

    # =========================================================
    # SHIFT PREFERENCES
    # =========================================================
    def get_shift_pre_df(self):
        shift_pre = ShiftPreferences.get_shift_pre()
        df = pd.DataFrame([s.to_dict() for s in shift_pre])

        df["date"] = pd.to_datetime(df["date"])
        df = df[
            (df["date"] >= pd.to_datetime(self.start_date)) &
            (df["date"] <= pd.to_datetime(self.end_date))
        ]

        return df.rename(columns={"staff_id": "id"})

    # =========================================================
    # PREDICTED SALES
    # =========================================================
    def get_pred_sale(self):
        pred = DataPrepare(self.start_date, self.end_date)
        df = pd.DataFrame(pred.run_prediction())
        df["date"] = pd.to_datetime(df["date"])
        return df

    # =========================================================
    # HELPERS
    # =========================================================
    def pred_sales_per_hour(self, hour, sales):
        if hour in [9, 10]:
            return sales * 0.052
        elif hour in [12, 13, 14, 15]:
            return sales * 0.1
        elif hour in [16, 17]:
            return sales * 0.07
        elif hour in [18, 19, 20, 23]:
            return sales * 0.08
        return sales * 0.09

    def salary(self, level):
        return {1: 1200, 2: 1200, 3: 1250, 4: 1400}.get(level, 1500)

    # =========================================================
    # COMBINE DATA
    # =========================================================
    def combine_data(self):
        df = pd.merge(
            self.get_shift_pre_df(),
            self.get_staff_data_df(),
            how="left",
            on="id"
        )

        df = pd.merge(df, self.get_pred_sale(), how="left", on="date")

        df["name"] = df["name"].fillna("unknown")
        df["level"] = df["level"].fillna(0).astype(int)
        df["status"] = df["status"].fillna("unknown")
        df["predicted_sales"] = df["predicted_sales"].fillna(0)

        records = []
        for _, row in df.iterrows():
            for h in range(9, 25):
                records.append({
                    "date": row["date"],
                    "hour": h,
                    "id": row["id"],
                    "name": row["name"],
                    "level": row["level"],
                    "status": row["status"],
                    "predicted_sales": row["predicted_sales"],
                })

        # Help staff (ID 1500)
        for d in df["date"].unique():
            pred_val = df[df["date"] == d]["predicted_sales"].iloc[0]
            for h in range(9, 25):
                records.append({
                    "date": d,
                    "hour": h,
                    "id": self.help_id,
                    "name": "not_enough",
                    "level": 0,
                    "status": "help",
                    "predicted_sales": pred_val,
                })

        final_df = pd.DataFrame(records)
        final_df["pred_sale_per_hour"] = final_df.apply(
            lambda r: self.pred_sales_per_hour(r["hour"], r["predicted_sales"]),
            axis=1
        )
        final_df["salary"] = final_df["level"].apply(self.salary)

        return final_df.sort_values(["date", "hour", "id"]).reset_index(drop=True)

    # =========================================================
    # CREATE SHIFT
    # =========================================================
    def create_shift(self, df):
        model = cp_model.CpModel()
        work = {}

        for _, row in df.iterrows():
            work[row["id"], row["date"], row["hour"]] = model.NewBoolVar("w")

        staff_info = df.drop_duplicates("id").set_index("id")[["level", "status"]].to_dict("index")

        for (d, h), group in df.groupby(["date", "hour"]):
            sales = group["pred_sale_per_hour"].iloc[0]
            num_staff = max(1, int(sales // 5000))
            model.Add(sum(work[row["id"], d, h] for _, row in group.iterrows()) == num_staff)

            model.Add(
                sum(
                    work[row["id"], d, h]
                    for _, row in group.iterrows()
                    if row["id"] == self.help_id or staff_info[row["id"]]["level"] >= 3
                ) >= 1
            )

        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = 10
        status = solver.Solve(model)
        return solver, status, work

    # =========================================================
    # RUN
    # =========================================================
    def run(self):
        df = self.combine_data()
        solver, status, work = self.create_shift(df)
        staff_data = self.get_staff_data_df().set_index("id").to_dict("index")

        results = []
        if status in (cp_model.OPTIMAL, cp_model.FEASIBLE):
            for (s, d, h), w in work.items():
                if solver.Value(w):
                    info = staff_data.get(s, {"name": "not_enough", "level": 0, "status": "help"})
                    results.append({
                        "staff_id": s,
                        "date": d,
                        "hour": h,
                        "name": info["name"],
                        "level": info["level"],
                        "status": info["status"],
                        "salary": self.salary(info["level"]),
                    })
        return pd.DataFrame(results)

    # =========================================================
    # SAVE (🔥 MAIN FIX HERE 🔥)
    # =========================================================
    def shift_save_db(self):
        df = self.run()

        # ✅ FIX 1: ALWAYS return List (never String)
        if df.empty:
            return []   # <-- THIS FIXES Flutter ga7 crash

        db: Session = next(get_db())
        try:
            db.query(ShiftMain).filter(
                ShiftMain.date >= self.start_date,
                ShiftMain.date <= self.end_date
            ).delete()

            db.add_all([
                ShiftMain(
                    date=row.date,
                    hour=int(row.hour),
                    staff_id=int(row.staff_id),
                    name=row.name,
                    level=int(row.level),
                    status=row.status,
                    salary=int(row.salary)
                )
                for row in df.itertuples(index=False)
            ])
            db.commit()

            # ✅ FIX 2: Always return List[Dict]
            return df.to_dict(orient="records")

        except Exception as e:
            db.rollback()
            print(f"[ShiftAss] DB Error: {e}")

            # ✅ FIX 3: Even on error → return empty list
            return []

    # =========================================================
    # DASHBOARD
    # =========================================================
    @staticmethod
    def get_shift_main():
        today = datetime.today().date()
        tomorrow = today + timedelta(days=1)

        db: Session = next(get_db())
        return db.query(ShiftMain).filter(
            ShiftMain.date >= today,
            ShiftMain.date <= tomorrow
        ).all()
