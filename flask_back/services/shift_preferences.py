import pandas as pd
import os

class ShiftPreferences:
    def __init__(self, dataframe, save_path):
        self.data = dataframe
        self.save_path = save_path
    
        self.staff_database_path = os.path.normpath(
            os.path.join(os.path.dirname(save_path), '../data/staff_dataBase.csv')
        )

    def save_to_database(self):
     
        os.makedirs(os.path.dirname(self.save_path), exist_ok=True)


        self.data['date'] = pd.to_datetime(self.data['date']).dt.strftime('%Y-%m-%d')

    
        if not os.path.exists(self.staff_database_path):
            raise FileNotFoundError(f"Staff database not found: {self.staff_database_path}")
        
        staff_database = pd.read_csv(self.staff_database_path)
        print("[DEBUG] staff_database loaded:")
        print(staff_database.head())

        if "staff" in self.data.columns:
            self.data.rename(columns={"staff": "Name"}, inplace=True)

     
        merged_data = pd.merge(self.data, staff_database[["Name", "ID"]], on="Name", how="left")

        if merged_data["ID"].isnull().any():
            print("[WARNING] Some staff names did not match and have missing IDs.")

        self.data = merged_data  

        print("[DEBUG] Data before saving:")
        print(self.data.head())

     
        if os.path.exists(self.save_path):
            existing = pd.read_csv(self.save_path)
            combined = pd.concat([existing, self.data], ignore_index=True)
            combined.drop_duplicates(subset=["Name", "date"], keep="last", inplace=True)
            combined.to_csv(self.save_path, index=False, encoding='utf-8-sig')
        else:
            self.data.to_csv(self.save_path, index=False, encoding='utf-8-sig')

        print(f"[ShiftPreferences] Saved to {self.save_path}")
