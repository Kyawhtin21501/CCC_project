import os
import pandas as pd
import re
import unicodedata

class StaffManager:
    def __init__(self, staff_csv_path=None):
        if staff_csv_path is None:
            # Get path like /project_root/data/staff_dataBase.csv or not i cannot run -->Kyipyar hlaing
            base_dir = os.path.dirname(os.path.abspath(__file__))  # → /flask_back/services
            staff_csv_path = os.path.abspath(os.path.join(base_dir, '..', '..', 'data', 'staff_dataBase.csv'))

        self.staff_df = pd.read_csv(staff_csv_path)
        print(f"[StaffManager] Loaded staff database from: {staff_csv_path}")

    def clean_names(self, names):
        cleaned = []
        for name in names:
            # Normalize Unicode, trim, remove extra whitespace, capitalize
            name = unicodedata.normalize("NFKC", name).strip()
            name = re.sub(r"\s+", " ", name).title()
            cleaned.append(name)
        return cleaned

    def calculate_total_level(self, names):
        total = 0
        for name in names:
            match = self.staff_df[self.staff_df['Name'] == name]
            if not match.empty:
                try:
                    total += int(match['Level'].values[0])
                except ValueError:
                    print(f"[StaffManager] Warning: Invalid level for {name}")
        return total
