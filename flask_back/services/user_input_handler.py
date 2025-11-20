import pandas as pd
import os
from datetime import datetime, timedelta
from sqlalchemy import create_engine  #for connecting to database
class UserInputHandler:
    """
    This class handles user-submitted daily input data (e.g., from Dashboard screen),
    cleans the assigned staff names, calculates total staff level, and saves the record to CSV.
    """

    def __init__(self, input_data,staff_manager, csv_path=None,date_format="%Y-%m-%d"):
        """
        Constructor: accepts user input dict, a StaffManager instance, and an optional CSV path.
        """
        self.data = input_data
        self.staff_manager = staff_manager
        self.date_format = date_format
        # Default path if none is provided (e.g., /project_root/data/user_input.csv)
        if csv_path is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))  # e.g., /flask_back/services/
            csv_path = os.path.abspath(os.path.join(base_dir, '..', '..', 'data', 'user_input.csv'))
        #if not os.path.exists(csv_path):
            #pd.DataFrame(columns=['date', 'is_festival', 'sales', 'guests', 'staff_count', 'assigned_staff', 'total_staff_level']).to_csv(csv_path, index=False)
       
      
    def process_and_save(self):
        input_row = {
            'date': self.data.get('date'),
            'is_festival': self.data.get('event'),
            'sales': self.data.get('sales'),
            'guests': self.data.get('customer_count'),
            'staff_count': self.data.get('staff_count'),
            'assigned_staff': self.data.get('staff_names'),
        }

        
    # Clean and normalize names
        cleaned_names = self.staff_manager.clean_names(input_row['assigned_staff'])
        
        
        return {
            'date': input_row['date'],
            'is_festival': True if self.data.get('event') == "True" else False, # Convert to boolean
            'sales': input_row['sales'],
            'guests': input_row['guests'],
            'staff_count': input_row['staff_count'],
            'assigned_staff': ', '.join(cleaned_names),
        }



"""
{
  "date": "2025-07-25",
  "event": 1,  # or True/False
  "sales": 90000,
  "customer_count": 85,
  "staff_count": 5,
  "staff_names": ["  kyaw htin hein", "Ko Ko", "Mya Mya"]
}
"""
