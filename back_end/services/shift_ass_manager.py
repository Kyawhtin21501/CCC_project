
from pulp import LpProblem, LpVariable, LpMaximize, lpSum
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
        return pd.DataFrame([s.to_dict() for s in staff])

    def get_shift_pre_df(self):
        shift_pre = ShiftPreferences.get_shift_pre()
        df = pd.DataFrame([s.to_dict() for s in shift_pre])

        df["date"] = pd.to_datetime(df["date"])

        df = df[
            (df["date"] >= pd.to_datetime(self.start_date)) &
            (df["date"] <= pd.to_datetime(self.end_date))
        ]
        return df

    def get_pred_sale(self):
        pred_sales = DataPrepare(self.start_date, self.end_date)
        pred_sales_data = pred_sales.run_prediction()
        df = pd.DataFrame(pred_sales_data)
        
       
        return df 
    
    @staticmethod
    def create_slot():
        pass
        
     

a = ShiftAss(start_date,end_date)
result = a.get_staff_data_df()
result2 = a.get_shift_pre_df()
result3 = a.get_pred_sale()
print(result)
print(result2)
print(result3)
