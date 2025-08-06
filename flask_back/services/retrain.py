import pandas as pd
import joblib

class ReTrainModel:
    """
    This class checks whether the model should be retrained based on accumulated user input data.
    If the number of new data rows reaches a threshold (default: 100),
    the class returns the most recent N rows for retraining.
    """

    def __init__(self, data_path, model_path, count=100):
        """
        Initialize the ReTrainModel class.

        Parameters:
        - data_path: Path to the CSV file containing user input data
        - model_path: Path to the saved model (.pkl file)
        - count: Number of new records required to trigger retraining (default is 100)
        """
        self.data_path = data_path
        self.model_path = model_path
        self.count = count

    def should_retrain(self):
        """
        Check if the number of records in the data file meets the retraining threshold.

        Returns:
        - The latest `count` rows (DataFrame) if retraining is needed and data count is divisible by count
        - False if retraining is not needed or an error occurs
        """
        try:
            # Load user input data
            df = pd.read_csv(self.data_path)
            current_count = len(df)
            print(f"📊 Current number of records: {current_count}")

            # Check if data count meets the retraining condition
            if current_count >= self.count:
                print(" Retraining condition met.")

                # Retrain only when count is exactly divisible (e.g., 100, 200, 300...)
                if current_count % self.count == 0:
                    input_data = df.tail(self.count)
                    print(" Retraining data preview (latest batch):")
                    print(input_data)
                    return input_data
                else:
                    print("⏳ Data is sufficient, but not a full batch yet. Waiting for next cycle.")
                    return False
            else:
                print(" Not enough data yet to trigger retraining.")
                return False

        except FileNotFoundError:
            print(f"File not found: {self.data_path}")
            return False
        except Exception as e:
            print(f"Unexpected error occurred: {e}")
            return False

# Example usage
data_path = "/Users/khein21502/Documents/project_root/CCC_project/CCC_project/data/user_input.csv"
model_path = "/Users/khein21502/Documents/project_root/CCC_project/CCC_project/model/sales_model.pkl"

reT= ReTrainModel(data_path, model_path)
if reT.should_retrain():
    print("Ready to call retrain_model()")
