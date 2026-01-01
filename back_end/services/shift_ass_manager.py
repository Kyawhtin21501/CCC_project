
from pulp import LpProblem, LpVariable, LpMinimize, lpSum
from sqlalchemy.orm import Session
#from sqlalchemy import func
from ..models.shift_model import ShiftMain
from ..utils.db import get_db
from pprint import pprint
import pandas as pd
import numpy as np
from datetime import datetime, timedelta, date

from back_end.services.staff_manager import StaffService
from back_end.services.shift_preferences import ShiftPreferences
from back_end.services.pred_manager import DataPrepare


class ShiftAss:

    def __init__(self, start_date, end_date):
        self.start_date = start_date
        self.end_date = end_date

    # =========================================================
    # STAFF DATA
    # =========================================================
    def get_staff_data_df(self):
        staff = StaffService.get_all_staff()
        df = pd.DataFrame([s.to_dict() for s in staff])
        df = df[["id", "name", "level", "status"]]
        return df

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

        df = df.rename(columns={"staff_id": "id"})
        return df

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
            return sales * 0.05
        elif hour in [12, 13, 14, 15]:
            return sales * 0.25
        elif hour in [16, 17, 23]:
            return sales * 0.10
        elif hour in [18, 19, 20]:
            return sales * 0.20
        else:
            return sales * 0.15

    def salary(self, level):
        if level in [1, 2]:
            return 1300
        elif level == 3:
            return 1350
        elif level == 4:
            return 1400
        else:
            return 1500

    # =========================================================
    # COMBINE DATA (🔥 MAIN FIX IS HERE)
    # =========================================================
    def combine_data(self):
        df = pd.merge(
            self.get_shift_pre_df(),
            self.get_staff_data_df(),
            how="left",
            on="id"
        )

        df = pd.merge(
            df,
            self.get_pred_sale(),
            how="left",
            on="date"
        )

        # CRITICAL NaN CLEANUP
        df["name"] = df["name"].fillna("unknown")
        df["level"] = df["level"].fillna(0).astype(int)
        df["status"] = df["status"].fillna("unknown")
        df["predicted_sales"] = df["predicted_sales"].fillna(0)
        """
        df["start_dt"] = pd.to_datetime(
            df["date"].dt.strftime("%Y-%m-%d") + " " + df["start_time"]
        )
        df["end_dt"] = pd.to_datetime(
            df["date"].dt.strftime("%Y-%m-%d") + " " + df["end_time"]
        )
       

        df.loc[df["end_dt"] < df["start_dt"], "end_dt"] += pd.Timedelta(days=1)
        """
        records = []

        for _, row in df.iterrows():
            #hours = int((row["end_dt"] - row["start_dt"]).total_seconds() // 3600)

            for h in range(9,25):
                records.append({
                    "date": row["date"],
                    "hour": h,
                    "staff_id": row["id"],
                    "name": row["name"],
                    "level": row["level"],
                    "status": row["status"],
                    "predicted_sales": row["predicted_sales"],
                })

        final_df = pd.DataFrame(records)

        final_df["pred_sale_per_hour"] = final_df.apply(
            lambda r: self.pred_sales_per_hour(r["hour"], r["predicted_sales"]),
            axis=1
        )

        final_df["max_cost"] = final_df["pred_sale_per_hour"] * 0.25
        final_df["salary"] = final_df["level"].apply(self.salary)
        final_df = final_df.sort_values(by=["date", "hour", "staff_id"]).reset_index(drop=True)
        #print("final_df")
        #print(final_df.to_string())
        return final_df


    # OPTIMIZATION
    def create_shift(self, df):
         model = LpProblem("ShiftOptimize", LpMinimize)

         x = LpVariable.dicts("x", df.index, cat="Binary")

         time_keys = list(df.groupby(["date", "hour"]).groups.keys())
         not_enough = LpVariable.dicts(
             "not_enough",
             time_keys,
             lowBound=0,
             cat="Integer"
         )
         break_var = LpVariable.dicts(
            "break",
            df.index,
            cat="Binary"
         )
         for staff_id, g_staff in df.groupby("staff_id"):
            for date, g_day in g_staff.groupby("date"):
                hours = g_day.sort_values("hour")
                idxs = hours.index.tolist()

                for k in range(len(idxs) - 1):
                    model += (
                        break_var[idxs[k]] >=
                        x[idxs[k]] - x[idxs[k+1]]
                    )

         for staff_id, g_staff in df.groupby("staff_id"):
            for date, g_day in g_staff.groupby("date"):
                idxs = g_day.index.tolist()
                model += lpSum(break_var[i] for i in idxs) <= 3

        
       
         MIN_LEVEL = 3
         MANAGER_LEVEL = 5
      
         for (date, hour), g in df.groupby(["date", "hour"]):
             model += (lpSum(df.loc[i, "salary"] * x[i] for i in g.index) <= g["max_cost"].iloc[0])
             n_e = int(g["max_cost"].iloc[0] // 1200)
             if n_e >= 1:
                 model += (lpSum(x[i] for i in g.index) + not_enough[(date, hour)] >= n_e)
             senior_idx = g[g["level"] >= MIN_LEVEL].index
             manager_idx = g[g["level"] == MANAGER_LEVEL].index

             if len(senior_idx) > 0:
                 model += lpSum(x[i] for i in senior_idx) >= 1
             elif len(manager_idx) > 0:
                 model += lpSum(x[i] for i in manager_idx) >= 1
             else:
                 model += not_enough[(date, hour)] >= 1

             
         for staff_id, g_staff in df.groupby("staff_id"):
            level = g_staff["level"].iloc[0]

            if level == 1:
                for date, g_day in g_staff.groupby("date"):
                    hours = g_day.sort_values("hour")
                    idxs = hours.index.tolist()

                    for k in range(len(idxs) - 1):
                        model += (
                            x[idxs[k]] <= x[idxs[k]] + x[idxs[k+1]]
                        )
         for staff_id, g_staff in df.groupby("staff_id"):
            level = g_staff["level"].iloc[0]

            if level >= 2:
                for date, g_day in g_staff.groupby("date"):
                    hours = g_day.sort_values("hour")
                    idxs = hours.index.tolist()

                    for k in range(len(idxs) - 2):
                        model += (
                            x[idxs[k]] <=
                            x[idxs[k]] + x[idxs[k+1]] + x[idxs[k+2]]
                        )


         

        

           

             

    
         for i, row in df.iterrows():
             if row["status"] == "high_school" and row["hour"] >= 22:
                 model += x[i] == 0


         for staff_id, g in df[df["status"] == "international_student"].groupby("staff_id"):
             model += lpSum(x[i] for i in g.index) <= 28

   
         for staff_id, g_staff in df.groupby("staff_id"):
             for date, g_day in g_staff.groupby("date"):
                 idxs = g_day.sort_values("hour").index.tolist()
                 
                 for k in range(len(idxs) - 6):
                     model += lpSum(x[i] for i in idxs[k:k+7]) <= 6
                     
    
         model.solve()
         selected = [i for i in df.index if x[i].value() == 1]

         shift_df = df.loc[selected].copy()
         shift_df["note"] = ""

         lack_rows = []

         for (date, hour), v in not_enough.items():
             shortage = int(v.value())
             for _ in range(9 , 24):
                for _ in range(shortage):
                 lack_rows.append({
                     "date": date,
                     "hour": hour,
                     "staff_id": -1,
                     "name": "not enough",
                     "level": None,
                     "status": None,
                     "salary": 0,
                     "note": "shortage"
                 })

         lack_df = pd.DataFrame(lack_rows)

         final_shift = pd.concat(
             [shift_df, lack_df],
             ignore_index=True
             ).sort_values(["date", "hour", "staff_id"])

         final_shift = final_shift[["date","hour","staff_id","name","level","note","salary"]]
        
         return final_shift

   
    

    def shift_save_db(self):
        df = self.combine_data()
        shift_rows = self.create_shift(df)

        db: Session = next(get_db())

        db.query(ShiftMain).filter(
            ShiftMain.date >= self.start_date,
            ShiftMain.date <= self.end_date
        ).delete()

        db.commit()

        objs = [
            ShiftMain(
                date=row["date"],
                hour=int(row["hour"]),
                staff_id=int(row["staff_id"]) if not pd.isna(row["staff_id"]) else -1,
                name=str(row["name"]) if pd.notna(row["name"]) else "not enough",
                level=int(row["level"]) if pd.notna(row["level"]) else 0,
                note=row.get("note") or "",
            )
            for _, row in shift_rows.iterrows()
        ]

        db.add_all(objs)
        db.commit()

        return shift_rows.to_dict(orient="records")

    @staticmethod
    def get_shift_main():
       
        today = datetime.today().date()
        tomorrow = today + timedelta(days=1)
        
        
        
        #print(today , tomorrow)
        db : Session = next(get_db())
        data = db.query(ShiftMain).filter(
                    ShiftMain.date >= today,
                    ShiftMain.date <= tomorrow
                ).all()
        if not data:
            print("該当シフトはありません")
        else:
            for d in data:
                print(d)
        return  data
        
    
     
        
        