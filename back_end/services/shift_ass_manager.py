from pulp import LpProblem, LpVariable, LpMaximize, lpSum
import pandas as pd
import numpy as np
import os

class ShiftAss:
    def __init__(self):
        # この py ファイルの場所を基準にする
        base_dir = os.path.dirname(os.path.abspath(__file__))

        self.start_date = "2025-12-20"
        self.end_date = "2025-12-27"

        # JSON ファイルのパス（安全・実務向け）
        self.staff_data = os.path.normpath(
            os.path.join(base_dir, "../../testing_staff.json")
        )
        self.sales_data = os.path.normpath(
            os.path.join(base_dir, "../../testing_sales_pre.json")
        )
        self.shift_pre = os.path.normpath(
            os.path.join(base_dir, "../../testing_data_for_dev.json")
        )

    def data_prepare(self):
        staff_df = pd.read_json(self.staff_data)
        sales_df = pd.read_json(self.sales_data)
        shift_pre_df = pd.read_json(self.shift_pre)
        
        # date を datetime に統一（超重要）
        for df in [staff_df, sales_df, shift_pre_df]:
            if "date" in df.columns:
                df["date"] = pd.to_datetime(df["date"]).dt.tz_localize(None)

                
        return staff_df, sales_df, shift_pre_df
        
    def cal_date_range(self):
        return {
            "start_date": pd.to_datetime(self.start_date),
            "end_date": pd.to_datetime(self.end_date),
            
        }

    def date_set_by_range_date(self, df, column, date_range):
        return df[df[column].between(
            date_range["start_date"],
            date_range["end_date"]
        )]

    def creat_slots(self):
        date_range = self.cal_date_range()
        staff_df, sales_df, shift_pre_df = self.data_prepare()

       
        shift_df = self.date_set_by_range_date(
            shift_pre_df, "date", date_range
        )
        sales_df = self.date_set_by_range_date(
            sales_df, "date", date_range
        )

        
        shift_df = shift_df.merge(
            staff_df[["id", "level", "status"]],
            left_on="staff_id",
            right_on="id",
            how="left"
        )

        
        shift_df = shift_df.merge(
            sales_df[["date", "predicted_sales"]],
            on="date",
            how="left"
        )
        shift_df = shift_df.drop("id",axis=1)
        return shift_df


if __name__ == "__main__":
    testing = ShiftAss()
    df = testing.creat_slots()

    
    print(df.head())
