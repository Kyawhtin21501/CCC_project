import pandas as pd
import os
from sqlalchemy import create_engine ,Table, MetaData #for connecting to database
from dotenv import load_dotenv 
load_dotenv()
engine = create_engine('postgresql+psycopg2://khein21502:@localhost/ccc_project')
class ShiftPreferences:
    def __init__(self, dataframe):
        self.data = dataframe
    
    
       

    def save_to_database(self):
     
        #os.makedirs(os.path.dirname(self.save_path), exist_ok=True)


        self.data['date'] = pd.to_datetime(self.data['date']).dt.strftime('%Y-%m-%d')

    
        
        
        staff_database = pd.read_sql_table("staff_profile", engine)
        print("[DEBUG] staff_database loaded:")
        print(staff_database.head())

        if "staff" in self.data.columns:
            self.data.rename(columns={"staff": "name"}, inplace=True)
        print(self.data.columns)
     
        merged_data = pd.merge(self.data, staff_database[["name", "id"]], on="name", how="left")

        if merged_data["id"].isnull().any():
            print("[WARNING] Some staff names did not match and have missing IDs.")

        self.data = merged_data  

        print("[DEBUG] Data before saving:")
        print(self.data.head())

     
        import pandas as pd
import os
from sqlalchemy import create_engine ,Table, MetaData #for connecting to database
from dotenv import load_dotenv 
load_dotenv()
engine = create_engine('postgresql+psycopg2://khein21502:@localhost/ccc_project')
class ShiftPreferences:
    def __init__(self, dataframe):
        self.data = dataframe
    
    
       

    def save_to_database(self):
     
        #os.makedirs(os.path.dirname(self.save_path), exist_ok=True)


        self.data['date'] = pd.to_datetime(self.data['date']).dt.strftime('%Y-%m-%d')

    
        
        
        staff_database = pd.read_sql_table("staff_profile", engine)
        print("[DEBUG] staff_database loaded:")
        print(staff_database.head())

        if "staff" in self.data.columns:
            self.data.rename(columns={"staff": "name"}, inplace=True)
        print(self.data.columns)
     
        merged_data = pd.merge(self.data, staff_database[["name", "id"]], on="name", how="left")

        if merged_data["id"].isnull().any():
            print("[WARNING] Some staff names did not match and have missing IDs.")

        self.data = merged_data  

        print("[DEBUG] Data before saving:")
        print(self.data.head())

     
        self.data.to_sql("staff_shift", engine, if_exists="append", index=False)

