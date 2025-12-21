from pulp import LpProblem, LpVariable, LpMaximize, lpSum
import pandas as pd
import numpy as np

class ShiftAss:
    def __init__(self):
        #temporary data
        self.start_date = "2025-12-20"
        self.end_date = "2025-12-27"
        self.staff_data = "/Users/khein21502/Documents/ccc_project_f/CCC_project/testing_staff.json"
        self.sales_data = "/Users/khein21502/Documents/ccc_project_f/CCC_project/testing_sales_pre.json"
        self.shift_pre = "/Users/khein21502/Documents/ccc_project_f/CCC_project/testing_data_for_dev.json"
        #_____________________
        pass
    


    
    @classmethod
    def data_prepare(self):
        staff_df = pd.DataFrame(self.staff_data)
        sales_df = pd.DataFrame(self.sales_data)
        shift_pre_df = pd.DataFrame(self.shift_pre)
        return staff_df , sales_df , shift_pre_df
        
    @staticmethod
    
    def to_create_slot():
        pass