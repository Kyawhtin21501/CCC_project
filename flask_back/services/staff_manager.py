import os
import pandas as pd
import re
import unicodedata
from sqlalchemy import create_engine ,Table, MetaData #for connecting to database
#from flask_sqlalchemy import SQLAlchemy
from dotenv import load_dotenv  #
import logging

load_dotenv()
engine = create_engine('postgresql+psycopg2://khein21502:@localhost/ccc_project')
class StaffManager:
    """
    Handles loading and processing of staff data from CSV.
    Provides methods to clean staff names and calculate total skill level.
    """

    def __init__(self, staff_csv_path=None):
        """
        Constructor: Load the staff database CSV.
        If no path is provided, use default path: /project_root/data/staff_dataBase.csv
        """
        if staff_csv_path is None:
            # Get absolute path to the staff database CSV
            base_dir = os.path.dirname(os.path.abspath(__file__))  # current file → /flask_back/services/
            staff_csv_path = os.path.abspath(os.path.join(base_dir, '..', '..', 'data', 'staff_dataBase.csv'))

        self.staff_df = pd.read_sql("SELECT * FROM staff_profile", engine)
        print(f"[StaffManager] Loaded staff database from: {staff_csv_path}")

    def clean_names(self, names = None):
        """
        Clean a list of staff names:
        - Normalize Unicode (e.g., full-width to half-width)
        - Remove leading/trailing and extra inner spaces
        - Convert to title case (e.g., "john DOE" → "John Doe")
        """
        cleaned = []
        for name in names:
            name = unicodedata.normalize("NFKC", name).strip()          # Normalize and trim
            name = re.sub(r"\s+", " ", name).title()                    # Remove extra spaces and capitalize
            cleaned.append(name)
        return cleaned
"""
    def calculate_total_level(self, names):
        
        Given a list of staff names, return the total of their skill levels.
        Useful for checking combined team capacity.
    
        total = 0
        for name in names:
            match = self.staff_df[self.staff_df['Name'] == name]
            if not match.empty:
                try:
                    total += int(match['Level'].values[0])
                except ValueError:
                    print(f"[StaffManager] Warning: Invalid level for {name}")
        return total
"""