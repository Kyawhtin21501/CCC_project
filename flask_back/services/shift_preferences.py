import pandas as pd
import os
class ShiftPreferences:
    def __init__(self, dataframe, save_path):
        self.data = dataframe
        self.save_path = save_path

    def save_to_database(self):
       
        os.makedirs(os.path.dirname(self.save_path), exist_ok=True)
        self.data['date'] = pd.to_datetime(self.data['date']).dt.strftime('%Y-%m-%d')

        if os.path.exists(self.save_path):
            existing = pd.read_csv(self.save_path)
            combined = pd.concat([existing, self.data])
            combined.drop_duplicates(subset=["staff", "date"], keep="last", inplace=True)
            combined.to_csv(self.save_path, index=False, encoding='utf-8-sig')
        else:
            self.data.to_csv(self.save_path, index=False, encoding='utf-8-sig')

        print(f"[ShiftPreferences] Saved to {self.save_path}")

