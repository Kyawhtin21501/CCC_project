
from pulp import LpProblem, LpVariable, LpMinimize, lpSum,LpStatus
from sqlalchemy.orm import Session
from ..models.shift_model import ShiftMain


from ..utils.db import get_db
import pandas as pd
import numpy as np
import os
from back_end.services.staff_manager import StaffService
from back_end.services.shift_preferences import ShiftPreferences
from back_end.services.pred_manager import DataPrepare
from sqlalchemy.orm import Session
import datetime
start_date = "2025-12-20"
end_date = "2025-12-27"

class ShiftAss:

    def __init__(self, start_date, end_date):
        self.start_date = start_date
        self.end_date = end_date

    def get_staff_data_df(self):
        staff = StaffService.get_all_staff()
        df = pd.DataFrame([s.to_dict() for s in staff])
        df = df[["id","name","level","status"]]
        return df

    def get_shift_pre_df(self):
        shift_pre = ShiftPreferences.get_shift_pre()
        df = pd.DataFrame([s.to_dict() for s in shift_pre])

        df["date"] = pd.to_datetime(df["date"])

        df = df[
            (df["date"] >= pd.to_datetime(self.start_date)) &
            (df["date"] <= pd.to_datetime(self.end_date))
        ]
        df = df.rename(columns= {"staff_id" : "id"})
        return df

    def get_pred_sale(self):
        pred_sales = DataPrepare(self.start_date, self.end_date)
        pred_sales_data = pred_sales.run_prediction()
        df = pd.DataFrame(pred_sales_data)
        df["date"] = pd.to_datetime(df["date"])
       
        return df 
    
    def pred_sales_per_hour(self, hour, sales):
        if hour in [9,10]:
            return sales * 0.05
        elif hour in [12,13,14,15]:
            return sales * 0.25
        
        elif hour in [16,17,23]:
            return sales * 0.1
        elif hour in [18,19,20]:
            return sales * 0.2
        else:
            return sales * 0.15

    def salary(self,level):
        if level in [1,2]:
            return 1300
        elif level == 3:
            return 1350
        elif level == 4:
            return 1400
        else:
            return 1500
        
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

        df["start_dt"] = pd.to_datetime(
            df["date"].dt.strftime("%Y-%m-%d") + " " + df["start_time"]
        )
        df["end_dt"] = pd.to_datetime(
            df["date"].dt.strftime("%Y-%m-%d") + " " + df["end_time"]
        )

        df.loc[df["end_dt"] < df["start_dt"], "end_dt"] += pd.Timedelta(days=1)

        records = []

        for _, row in df.iterrows():
            hours = int((row["end_dt"] - row["start_dt"]).total_seconds() // 3600)

            for h in range(hours):
                records.append({
                    "date": row["date"],
                    "hour": (row["start_dt"] + pd.Timedelta(hours=h)).hour,
                    "staff_id": row["id"],
                    "name": row["name"],
                    "level": row["level"],
                    
                    "status": row["status"],
                    "predicted_sales": row.get("predicted_sales", 0),
                    
                })

        final_df = pd.DataFrame(records)

        final_df["pred_sale_per_hour"] = final_df.apply(
            lambda row: self.pred_sales_per_hour(
                row["hour"],
                row["predicted_sales"] if pd.notna(row["predicted_sales"]) else 0
            ),
            axis=1
        )
        final_df["max_cost"] = final_df["pred_sale_per_hour"] * 0.25
        
        final_df["salary"] = final_df["level"].apply(self.salary)

        return final_df


        
        
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

        
        model += (
            lpSum(df.loc[i, "salary"] * x[i] for i in df.index)
            + lpSum(10000 * not_enough[k] for k in time_keys)  
        )

      
        for (date, hour), g in df.groupby(["date", "hour"]):
            required = max(1, int(g["pred_sale_per_hour"].iloc[0] // 20000))

            model += (
                lpSum(x[i] for i in g.index) + not_enough[(date, hour)]
                >= required
            )

            model += (
                lpSum(df.loc[i, "salary"] * x[i] for i in g.index)
                <= g["max_cost"].iloc[0]
            )

        MIN_LEVEL = 3
        MANAGER_LEVEL = 5

        for (date, hour), g in df.groupby(["date", "hour"]):

            required = max(1, int(g["pred_sale_per_hour"].iloc[0] // 20000))

            model += (
                lpSum(x[i] for i in g.index) + not_enough[(date, hour)]
                >= required
            )

            model += (
                lpSum(df.loc[i, "salary"] * x[i] for i in g.index)
                <= g["max_cost"].iloc[0]
            )

            senior_idx = g[g["level"] >= MIN_LEVEL].index
            manager_idx = g[g["level"] == MANAGER_LEVEL].index

            if len(senior_idx) > 0:
                model += lpSum(x[i] for i in senior_idx) >= 1
            elif len(manager_idx) > 0:
                model += lpSum(x[i] for i in manager_idx) >= 1
            else:
                model += not_enough[(date, hour)] >= 1


    
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

        final_shift = final_shift[["date","hour","staff_id","name","level","note"]]

        return final_shift


    
    def shift_save_db(self):
        df = self.combine_data()
        shift_rows = self.create_shift(df) 
        db: Session = next(get_db())

     
        db.query(ShiftMain).delete()
        db.commit()

        # ① DataFrame → ORM用オブジェクト
        objs = [
            ShiftMain(
                date=row["date"],
                hour=row["hour"],
                staff_id=row["staff_id"],
                name=row["name"],
                level=row["level"],
                note=row.get("note"),
                )
            for _, row in shift_rows.iterrows()
            ]

        db.add_all(objs)
        db.commit()


        result = [
                {
                "date": row["date"],
                "hour": row["hour"],
                "staff_id": row["staff_id"],
                "name": row["name"],
                #"level": row["level"],
                "level": None if pd.isna(row["level"]) else row["level"],
                "note": row.get("note"),
                 }
                for _, row in shift_rows.iterrows()
            ]

        return result

