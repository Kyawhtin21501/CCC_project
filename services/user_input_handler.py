import pandas as pd
import os

class UserInputHandler:
    def __init__(self, input_data, staff_manager, csv_path="data/user_input.csv"):
        self.data = input_data
        self.staff_manager = staff_manager
        self.csv_path = csv_path

    def process_and_save(self):
        input_row = {
            'date': self.data.get('date'),
            'is_festival': self.data.get('event'),
            'sales': self.data.get('sales'),
            'guests': self.data.get('customer_count'),
            'staff_count': self.data.get('staff_count'),
            'assigned_staff': self.data.get('staff_names'),
        }

        cleaned_names = self.staff_manager.clean_names(input_row['assigned_staff'])
        input_row['assigned_staff'] = cleaned_names
        input_row['total_staff_level'] = self.staff_manager.calculate_total_level(cleaned_names)

        df = pd.DataFrame([input_row])
        file_exists = os.path.isfile(self.csv_path)
        df.to_csv(self.csv_path, mode="a", index=False, header=not file_exists)

        return cleaned_names
