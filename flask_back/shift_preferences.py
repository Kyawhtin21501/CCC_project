import pandas as pd
class ShiftPreferences:
    def __init__(self, data):
        self.data = data
    def save_to_database(self):
        all_preferences = []
        for date, shifts in self.data.items():
            for staff,preferences in shifts.items():
                for shift, preference in preferences.items():
                    staff_shift_preference = {
                        "date": date,
                        "staff": staff,
                        "shift": shift,
                        "preference": preference
                    }
                    all_preferences.append(staff_shift_preference)
        df = pd.DataFrame(all_preferences)
        df.to_csv("data/shift_preferences.csv", index=False)  
        return df  
                   
   


        


