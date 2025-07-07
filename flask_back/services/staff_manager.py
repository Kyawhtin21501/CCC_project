import pandas as pd
import re
import unicodedata

class StaffManager:
    def __init__(self, staff_csv_path="data/staff_dataBase.csv"):
        self.staff_df = pd.read_csv(staff_csv_path)

    def clean_names(self, names):
        cleaned = []
        for name in names:
            name = unicodedata.normalize("NFKC", name).strip()
            name = re.sub(r"\s+", " ", name).title()
            cleaned.append(name)
        return cleaned

    def calculate_total_level(self, names):
        total = 0
        for name in names:
            match = self.staff_df[self.staff_df['Name'] == name]
            if not match.empty:
                total += int(match['Level'].values[0])
        return total
