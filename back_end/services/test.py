
#from pulp import LpProblem, LpVariable, LpMinimize, lpSum
from sqlalchemy.orm import Session
#from sqlalchemy import func

from pprint import pprint
import pandas as pd
import numpy as np
from datetime import datetime, timedelta, date

from back_end.models.shift_model import ShiftMain
from back_end.utils.db import get_db
from ortools.sat.python import cp_model
from back_end.services.staff_manager import StaffService
from back_end.services.shift_preferences import ShiftPreferences
from back_end.services.pred_manager import DataPrepare



class ShiftAss:

    def __init__(self):
        self.start_date = "2026-1-1"
        self.end_date = "2026-1-7"
        

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
      
        pred = DataPrepare(self.start_date,self.end_date)
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
        """
        #df.loc[df["end_dt"] < df["start_dt"], "end_dt"] += pd.Timedelta(days=1)

        records = []

        for _, row in df.iterrows():
            #hours = int((row["end_dt"] - row["start_dt"]).total_seconds() // 3600)

            for h in range(9, 25):
                records.append({
                    "date": row["date"],
                    
                    "hour": h,
                    "staff_id": row["id"],
                    "name": row["name"],
                    "level": row["level"],
                    "status": row["status"],
                    "predicted_sales": row["predicted_sales"]
                })

        final_df = pd.DataFrame(records)

        final_df["pred_sale_per_hour"] = final_df.apply(
            lambda r: self.pred_sales_per_hour(r["hour"], r["predicted_sales"]),
            axis=1
        )

        final_df["max_cost"] = (final_df["pred_sale_per_hour"] * 0.25).astype(int)
        
        final_df["salary"] = final_df["level"].apply(self.salary)
        #final_df = final_df.sort_values(by=["date", "hour", "staff_id"]).reset_index(drop=True)

        return final_df
    
    def create_shift_ass(self):
        df = self.combine_data()
        model = cp_model.CpModel() # model creation
        work = {}
        
        #create variables
        
        time_keys = list(df.groupby(["date", "hour"]).groups.keys())
        for staff in df['staff_id'].unique():
            for date, hour in time_keys:
                work[staff, date, hour] = model.NewBoolVar(f"work_{staff}_{date}_{hour}")

        #cost varable
        
        cost = {}
        max_cost = {}
        pred_sales = {}

        for _, row in df.iterrows():
            s = row['staff_id']
            d = row['date']
            h = row['hour']
    
            cost[s, d, h] = row['salary']        # 1時間あたりのコスト
            max_cost[d, h] = row['max_cost']    # 時間帯ごとの最大人件費
            pred_sales[d, h] = row['pred_sale_per_hour']  # 1時間ごとの売上予測
            for d, h in max_cost:
                model.Add(sum(cost[s, d, h] * work[s, d, h] for s in df['staff_id'].unique()) <= max_cost[d, h])

        
    


        

        
        
        
        
        
        
        return  work

    
if __name__ == "__main__":
    sa = ShiftAss()
   
    df = sa.combine_data()
    df.to_csv("combined_data.csv", index=False)
    #df = pd.DataFrame(df)
    
    print(df.head())

    
    
    
