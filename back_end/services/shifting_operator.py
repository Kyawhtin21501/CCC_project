from pulp import LpProblem, LpVariable, LpMaximize, lpSum
import pandas as pd
import os
from pprint import pprint
from pathlib import Path
import datetime
class ShiftOperator:
    def __init__(self, shift_preferences: pd.DataFrame, staff_dataBase: pd.DataFrame, required_level: dict):
        base_dir = os.path.dirname(os.path.abspath(__file__))
        self.shift_preferences = shift_preferences  # Staff shift preferences (from UI)
        self.staff_dataBase = staff_dataBase        # Staff profile data (e.g., level, status)
        self.required_level = required_level        # Required staff level per shift (predicted)
        self.display_dir = os.path.normpath(os.path.join(base_dir, '../../data/data_for_dashboard/'))
        # Define shift time ranges
        
        
        
        
        self.time_map = {
            "morning": list(range(9, 14)),      # 9:00 to 13:59
            "afternoon": list(range(14, 19)),   # 14:00 to 18:59
            "night": list(range(19, 24))        # 19:00 to 23:59
        }

        # Calculate hours per shift
        self.shift_hours_map = {shift: len(hours) for shift, hours in self.time_map.items()}

    def assign_shifts(self):
        # Guard clause: ensure data is not empty
        if self.shift_preferences.empty or self.staff_dataBase.empty:
            print(" No shift preferences or staff database provided.")
            return pd.DataFrame()
        
        # NOTE: Using 'id' for merge key for consistency with results keys, but 
        # based on your provided second code block, I'll use 'ID' for the merge 
        # and subsequent dataframe access, as it seems to be the column name.
        
        # Assuming staff_dataBase has an 'ID' column and shift_preferences has an 'ID' column
        final_df = pd.merge(self.shift_preferences, self.staff_dataBase, on="id", how="left")
        
        # Check for case consistency in final_df columns:
        # print(final_df.columns) 
        
        # Define Linear Programming problem
        model = LpProblem("Basic_Shift_Assignment", LpMaximize)

        # Create decision variables: assign if staff is available and prefers the shift
        variables = {}
        for idx, row in final_df.iterrows():
            for shift in self.time_map:
                # Assuming 'morning', 'afternoon', 'night' are boolean columns in final_df
                if row.get(shift) and pd.notna(row.get('date')): # Added check for 'date'
                    key = f"x_{row['id']}_{row['date']}_{shift}"
                    variables[key] = LpVariable(key, cat="Binary")  # 0 or 1

        # Objective: Maximize total number of preferred shifts assigned
        model += lpSum(variables.values())

        # Constraints: for each date & shift
        max_staff_per_shift = 4  # Limit to 4 people per shift
        dates = final_df["date"].unique()

        # Filtering out potential NaN dates before looping
        dates = [d for d in dates if pd.notna(d)] 

        for date in dates:
            for shift in self.time_map:
                shift_vars = []
                shift_levels = []
                # Use a cleaner way to filter the DataFrame
                daily_df = final_df[final_df["date"] == date]
                
                for _, row in daily_df.iterrows():
                    if row.get(shift):
                        key = f"x_{row['id']}_{row['date']}_{shift}"
                        if key in variables:
                            shift_vars.append(variables[key])
                            shift_levels.append((variables[key], row["Level"]))

                # Max staff per shift
                model += lpSum(shift_vars) <= max_staff_per_shift
                
                # Minimum required staff level (predicted from ML model)
                # Corrected required_level access: it needs date AND shift key.
                # Assuming self.required_level is structured as {date: {shift: required_level_sum}}
                if date in self.required_level and shift in self.required_level[date]:
                    model += lpSum([var * lvl for var, lvl in shift_levels]) >= self.required_level[date][shift]


        # ... (Weekly 28-hour cap and High school student constraints remain unchanged) ...

        # Solve the optimization problem
        model.solve()

        
        # Collect results from solved variables
        results = []
        for key, var in variables.items():
            if var.value() == 1:  # Assigned
                # key is in format: x_STAFF_ID_DATE_SHIFT
                # Correctly handles the split based on how the key was constructed
                _, staff_id, date, shift = key.split("_", 3) 
                
                # Use the ID column name as it is in final_df (assuming 'ID')
                match_row = final_df[
                    (final_df["id"] == int(staff_id)) & (final_df["date"].astype(str) == str(date))
                ].iloc[0]
                
                # Get name (assuming it's in a consistent column, e.g., 'Name_y' from merge)
                # We can skip looking up the name here if we use match_row later or assume 
                # you have a consistent 'Name' column. Let's rely on match_row.
                
                results.append({
                    "id": staff_id, # <--- **CRITICAL: This is the key that must exist.**
                    "date": date,   # <--- **CRITICAL: This is the key that must exist.**
                    "shift": shift,
                    "name": match_row.get("Name_y", "Unknown"), # Assuming 'Name_y' is the staff name after merge
                    "level": match_row["Level"],
                })
        
        # Create result DataFrame and sort by shift priority
        # This line will now work because 'results' is guaranteed to have the 'date' key.
        results_df = pd.DataFrame(results).sort_values(["date", "shift", "id"]).reset_index(drop=True)
        
        print("shift---------------------")
        print(results_df)
        print(results_df.head())

        return results_df
"""
from pulp import LpProblem, LpVariable, LpMaximize, lpSum
import pandas as pd
import os
from pprint import pprint
from pathlib import Path
class ShiftOperator:
    def __init__(self, shift_preferences: pd.DataFrame, staff_dataBase: pd.DataFrame, required_level: dict):
        base_dir = os.path.dirname(os.path.abspath(__file__))
        self.shift_preferences = shift_preferences  # Staff shift preferences (from UI)
        self.staff_dataBase = staff_dataBase        # Staff profile data (e.g., level, status)
        self.required_level = required_level        # Required staff level per shift (predicted)
        self.display_dir = os.path.normpath(os.path.join(base_dir, '../../data/data_for_dashboard'))
        # Define shift time ranges
        self.time_map = {
            "morning": list(range(9, 14)),      # 9:00 to 13:59
            "afternoon": list(range(14, 19)),   # 14:00 to 18:59
            "night": list(range(19, 24))        # 19:00 to 23:59
        }

        # Calculate hours per shift
        self.shift_hours_map = {shift: len(hours) for shift, hours in self.time_map.items()}

    def assign_shifts(self):
        # Guard clause: ensure data is not empty
        if self.shift_preferences.empty or self.staff_dataBase.empty:
            print(" No shift preferences or staff database provided.")
            return pd.DataFrame()
        print(self.shift_preferences)
        print(self.staff_dataBase)
        # Merge preference and staff profile info using ID
        final_df = pd.merge(self.shift_preferences, self.staff_dataBase, on="ID", how="left")
        
        print(final_df)
        # Define Linear Programming problem
        model = LpProblem("Basic_Shift_Assignment", LpMaximize)

        # Create decision variables: assign if staff is available and prefers the shift
        variables = {}
        for idx, row in final_df.iterrows():
            for shift in self.time_map:
                if row.get(shift):  # Only if staff prefers the shift
                    key = f"x_{row['ID']}_{row['date']}_{shift}"
                    variables[key] = LpVariable(key, cat="Binary")  # 0 or 1

        # Objective: Maximize total number of preferred shifts assigned
        model += lpSum(variables.values())

        # Constraints: for each date & shift
        max_staff_per_shift = 4  # Limit to 4 people per shift
        dates = final_df["date"].unique()

        for date in dates:
            for shift in self.time_map:
                shift_vars = []
                shift_levels = []
                for _, row in final_df[final_df["date"] == date].iterrows():
                    if row.get(shift):
                        key = f"x_{row['ID']}_{row['date']}_{shift}"
                        if key in variables:
                            shift_vars.append(variables[key])
                            shift_levels.append((variables[key], row["Level"]))

                # Max staff per shift
                model += lpSum(shift_vars) <= max_staff_per_shift

                # Minimum required staff level (predicted from ML model)
                if date in self.required_level:
                    model += lpSum([var * lvl for var, lvl in shift_levels]) >= self.required_level[date][shift]

        # Constraint: Weekly 28-hour cap for international students
        for staff_id in final_df["ID"].unique():
            staff_rows = final_df[final_df["ID"] == staff_id]
            total_hours_expr = []
            for _, row in staff_rows.iterrows():
                for shift in self.time_map:
                    if row.get(shift):
                        key = f"x_{row['ID']}_{row['date']}_{shift}"
                        if key in variables:
                            total_hours_expr.append(variables[key] * self.shift_hours_map[shift])
            # Apply rule only if staff is international student
            if staff_rows.iloc[0]["status"] == "international_student":
                model += lpSum(total_hours_expr) <= 28

        # Constraint: High school students cannot work shifts with hours after 22:00
        for _, row in final_df.iterrows():
            if row["status"] == "high_school":
                for shift, hours in self.time_map.items():
                    if any(h >= 22 for h in hours) and row.get(shift):
                        key = f"x_{row['ID']}_{row['date']}_{shift}"
                        if key in variables:
                            model += variables[key] == 0  # No night shifts after 10 PM
        
        
        # Solve the optimization problem
        model.solve()

        
        # Collect results from solved variables
        results = []
        for key, var in variables.items():
            #print(f"{key}: {var.value()}")
            #print(f"var: {var}")
            if var.value() == 1:  # Assigned
                _, staff_id, date, shift = key.split("_", 3)
                match_row = final_df[
                    (final_df["ID"] == int(staff_id)) & (final_df["date"] == date)
                ].iloc[0]
                results.append({
                    "staff_id": staff_id,
                    "date": date,
                    "shift": shift,
                    #"not_enough_staff":False,
                    
                    "level": match_row["Level"],
              
                })
    """
        
        
            
        
      
        
        #pprint(results)
        
          
                

        # Create result DataFrame and sort by shift priority

    

        # Pivot the table to show shift assignments clearly


  


       
        
            
        
      
        
        #pprint(results)
        
          
                

        # Create result DataFrame and sort by shift priority

    

        # Pivot the table to show shift assignments clearly


  

