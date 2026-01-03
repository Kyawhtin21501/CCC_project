from sqlalchemy.orm import Session
from pprint import pprint
import pandas as pd
import numpy as np
from datetime import datetime, timedelta, date

from ortools.sat.python import cp_model

from back_end.models.shift_model import ShiftMain
from back_end.utils.db import get_db
from back_end.services.staff_manager import StaffService
from back_end.services.shift_preferences import ShiftPreferences
from back_end.services.pred_manager import DataPrepare


class ShiftAss:
    def __init__(self):
        self.start_date = "2026-01-01"
        self.end_date = "2026-01-07"

        self.model = cp_model.CpModel()
        self.work = {}
        self.cost = {}
        self.max_cost = {}

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
    # COMBINE DATA
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

        # NaN cleanup
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

        final_df = pd.DataFrame(records)

        final_df["pred_sale_per_hour"] = final_df.apply(
            lambda r: self.pred_sales_per_hour(r["hour"], r["predicted_sales"]),
            axis=1
        )

        final_df["max_cost"] = (
            final_df["pred_sale_per_hour"] * 0.25
        ).round().astype(int)

        final_df["salary"] = final_df["level"].apply(self.salary).astype(int)

        final_df = final_df.sort_values(
            by=["date", "hour", "id"]
        ).reset_index(drop=True)

        return final_df

    # =========================================================
    # CREATE SHIFT (CP-SAT)
    # =========================================================
    def creat_shift(self, df):
        model = cp_model.CpModel()

        """
        groupby(["date", "hour"]).groups
        -> key: (date, hour)
        -> value: index list
        """
        df["date"] = pd.to_datetime(df["date"]).dt.date
        time_strip = list(df.groupby(["date", "hour"]).groups.keys())

        # -----------------------------------------------------
        # Decision Variables
        # -----------------------------------------------------
        work = {}
        for _, row in df.iterrows():
            s = row["id"]
            d = row["date"]
            h = row["hour"]
            work[s, d, h] = model.NewBoolVar(f"work_{s}_{d}_{h}")

        # -----------------------------------------------------
        # Cost / Sales
        # -----------------------------------------------------
        cost = {}
        max_cost = {}
        pred_sales = {}

        for _, row in df.iterrows():
            s = row["id"]
            d = row["date"]
            h = row["hour"]

            cost[s, d, h] = row["salary"]
            max_cost[d, h] = row["max_cost"]
            pred_sales[d, h] = row["pred_sale_per_hour"]

        # -----------------------------------------------------
        # Cost Constraint
        # -----------------------------------------------------
        for d, h in max_cost:
            model.Add(
                sum(
                    cost[s, d, h] * w
                    for (s, dd, hh), w in work.items()
                    if dd == d and hh == h
                ) <= max_cost[d, h]
            )

        # -----------------------------------------------------
        # Skill Constraints
        # -----------------------------------------------------
        staff_df = self.get_staff_data_df()

        regular_staff = staff_df[staff_df["level"].isin([3, 4])]["id"].tolist()
        manager_staff = staff_df[staff_df["level"] == 5]["id"].tolist()

        has_regular = {}
        for date, hour in time_strip:
            has_regular[date, hour] = model.NewBoolVar(
                f"has_regular_{date}_{hour}"
            )

            model.Add(
                sum(
                    w for (s, d, h), w in work.items()
                    if d == date and h == hour and s in regular_staff
                ) >= 1
            ).OnlyEnforceIf(has_regular[date, hour])

            model.Add(
                sum(
                    w for (s, d, h), w in work.items()
                    if d == date and h == hour and s in regular_staff
                ) == 0
            ).OnlyEnforceIf(has_regular[date, hour].Not())

            model.Add(
                sum(
                    w for (s, d, h), w in work.items()
                    if d == date and h == hour and s in manager_staff
                ) >= 1
            ).OnlyEnforceIf(has_regular[date, hour].Not())

        # -----------------------------------------------------
        # Continuity
        # -----------------------------------------------------
        for (s, d, h), w in work.items():
            if h <= 9:
                continue

            if (s, d, h-1) in work and (s, d, h+1) in work:
                model.Add(w <= work[s, d, h-1] + work[s, d, h+1])

        # -----------------------------------------------------
        # Break Constraint (7h window -> max 6)
        # -----------------------------------------------------
        hours = sorted(df["hour"].unique())
        for s in df["staff_id"].unique():
            for d in df["date"].unique():
                for i in range(len(hours) - 6):
                    window = hours[i:i+7]
                    if all((s, d, h) in work for h in window):
                        model.Add(
                            sum(work[s, d, h] for h in window) <= 6
                        )

        # -----------------------------------------------------
        # Weekly Limit (International)
        # -----------------------------------------------------
        dates = sorted(df["date"].unique())
        international_staff = staff_df[
            staff_df["status"] == "international"
        ]["id"].tolist()

        for s in international_staff:
            for i in range(len(dates)):
                start = dates[i]
                end = start + timedelta(days=6)

                model.Add(
                    sum(
                        w for (ss, d, h), w in work.items()
                        if ss == s and start <= d <= end
                    ) <= 28
                )

        # -----------------------------------------------------
        # High School Constraint
        # -----------------------------------------------------
        high_school_staff = staff_df[
            staff_df["status"] == "high_school"
        ]["id"].tolist()

        for (s, d, h), w in work.items():
            if s in high_school_staff and h >= 22:
                model.Add(w == 0)

        # -----------------------------------------------------
        # Objective
        # -----------------------------------------------------
        model.Maximize(
            sum(w for w in work.values())
            - 0.001 * sum(cost[s, d, h] * w for (s, d, h), w in work.items())
        )


        solver = cp_model.CpSolver()
        solver.parameters.max_time_in_seconds = 10
        status = solver.Solve(model)

        return solver, status, work
    def run(self):
        df = self.combine_data()
        solver, status, work = self.creat_shift(df)

        shift_ass = []  

        if status in (cp_model.OPTIMAL, cp_model.FEASIBLE):
            for (s, d, h), w in work.items():
                if solver.Value(w) == 1:
                    shift_ass.append({
                        "id": s,
                        "date": d,
                        "hour": h
                    })

            shift_ass_df = pd.DataFrame(shift_ass)

        else:
            print("No solution found.")
            shift_ass_df = pd.DataFrame()

        shift_ass_df["salary"] = shift_ass_df["id"].apply(self.salary).astype(int)
        staff_df = self.get_staff_data_df()
        shift_ass_df = shift_ass_df.merge(staff_df , how="left", on= "id")
        # 実際の人件費
        actual_cost = (
            shift_ass_df
            .groupby(["date", "hour"])["salary"]
            .sum()
        )

        # 実際の人数
        actual_count = (
            shift_ass_df
            .groupby(["date", "hour"])["id"]
            .count()
        )

        # max_cost
        max_cost = (
            df
            .groupby(["date", "hour"])["max_cost"]
            .first()
        )

        # 1人あたり最低給料（基準）
        min_salary = df["salary"].min()

        result = []

        for key in max_cost.index:
            mc = max_cost.loc[key]
            ac = actual_cost.get(key, 0)
            cnt = actual_count.get(key, 0)

        # max_costベースで入れられる最大人数
            max_possible = mc // min_salary

            shortage = max_possible - cnt

            if shortage > 0:
                result.append({
                    "date": key[0],
                    "hour": key[1],
                    "max_cost": mc,
                    "actual_cost": ac,
                    "actual_staff": cnt,
                    "can_add_staff": shortage
                })

        shortage_df = pd.DataFrame(result)
        result = shift_ass_df.merge(
            shortage_df[["date", "hour", "can_add_staff"]],
            on=["date", "hour"],
            how="left"
        )

        result["can_add_staff"] = result["can_add_staff"].fillna("perfect")

            
        return result

            
                  
        

if __name__ == "__main__":
    sa = ShiftAss()
    df= sa.combine_data()
    print(df.head(5))
    #print(df2.head(5))

    
    
    
