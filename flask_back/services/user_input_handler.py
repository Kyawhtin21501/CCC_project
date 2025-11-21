import pandas as pd
import os
from datetime import datetime
from sqlalchemy import create_engine

class UserInputHandler:
    """
    This class processes user-submitted data (daily store input)
    and stores it into PostgreSQL safely.
    """

    def __init__(self, input_data, staff_manager, db_url, date_format="%Y-%m-%d"):
        """
        input_data: dict from frontend
        staff_manager: StaffManager instance
        db_url: PostgreSQL connection string
                e.g. "postgresql://username:password@localhost:5432/restaurant_db"
        """
        self.data = input_data
        self.staff_manager = staff_manager
        self.db_url = db_url
        self.date_format = date_format
        self.engine = create_engine(db_url)

    def process_and_save(self):
        # Format row
        input_row = {
            'date': self.data.get('date'),
            'is_festival': True if str(self.data.get('event')).lower() in ["1", "true", "yes"] else False,
            'sales': self.data.get('sales'),
            'guests': self.data.get('customer_count'),
            'staff_count': self.data.get('staff_count'),
            'assigned_staff': self.data.get('staff_names')
        }

        # Clean staff names
        cleaned_names = self.staff_manager.clean_names(input_row['assigned_staff'])

        # Build final record
        final_record = {
            'date': input_row['date'],
            'is_festival': input_row['is_festival'],
            'sales': input_row['sales'],
            'guests': input_row['guests'],
            'staff_count': input_row['staff_count'],
            'assigned_staff': ', '.join(cleaned_names)
        }

        # Convert to DataFrame for SQL insert
        df = pd.DataFrame([final_record])

        # Save to PostgreSQL
        df.to_sql("user_input", self.engine, if_exists='append', index=False)

        return final_record
