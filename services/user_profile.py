import pandas as pd
import os
class staff_profile:
    def __init__(self,id,name,level,gender,age,csv_path="data/testing.csv"):
        self.id = id
        self.name = name
        self.level = level
        self.gender = gender 
        self.age = age
        self.csv_path = csv_path
    def save_data(self):
        staff_data = [self.id,self.name,self.level,self.gender,self.age],
        df = pd.DataFrame(staff_data)
        file_exists = os.path.isfile(self.csv_path)
        df.to_csv(self.csv_path, mode="a", index=False, header=not file_exists)

        return print(staff_data)

staff1 = staff_profile(250324,"Kyaw Htin Hein",5,"Male",24)
staff1.save_data()
staff2 = staff_profile(250325,"Kyi Pyar Hlaing",5,"Female",24)
staff1.save_data()