import pandas as pd
import os

class UserInputHandler:
    """
    This class handles user-submitted daily input data (e.g., from Dashboard screen),
    cleans the assigned staff names, calculates total staff level, and saves the record to CSV.
    """

    def __init__(self, input_data, staff_manager, csv_path=None):
        """
        Constructor: accepts user input dict, a StaffManager instance, and an optional CSV path.
        """
        self.data = input_data
        self.staff_manager = staff_manager

        # Default path if none is provided (e.g., /project_root/data/user_input.csv)
        if csv_path is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))  # e.g., /flask_back/services/
            csv_path = os.path.abspath(os.path.join(base_dir, '..', '..', 'data', 'user_input.csv'))

        self.csv_path = csv_path
        print(f"[UserInputHandler] Writing to: {self.csv_path}")

    def process_and_save(self):
        """
        Process the input:
        - Clean assigned staff names
        - Calculate total staff level
        - Save all data as a new row in user_input.csv
        """
        input_row = {
            'date': self.data.get('date'),                        # e.g., "2025-07-25"
            'is_festival': self.data.get('event'),               # Boolean or 1/0
            'sales': self.data.get('sales'),                     # Predicted or actual sales
            'guests': self.data.get('customer_count'),           # Number of guests
            'staff_count': self.data.get('staff_count'),         # Number of assigned staff
            'assigned_staff': self.data.get('staff_names'),      # List of staff names
        }

        # Clean and normalize names (e.g., full-width to half-width, remove extra spaces)
        cleaned_names = self.staff_manager.clean_names(input_row['assigned_staff'])

        # Calculate total staff level from cleaned names
        input_row['assigned_staff'] = cleaned_names
        input_row['total_staff_level'] = self.staff_manager.calculate_total_level(cleaned_names)

        # Create a DataFrame with just one row
        df = pd.DataFrame([input_row])

        # Save to CSV in append mode. Add header only if file doesn't already exist
        file_exists = os.path.isfile(self.csv_path)
        df.to_csv(self.csv_path, mode="a", index=False, header=not file_exists)

        return cleaned_names


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