import pandas as pd
import os

class StaffProfileOperation:
    def __init__(self, csv_path=None):
        if csv_path is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))  # /flask_back/services
            csv_path = os.path.abspath(os.path.join(base_dir, '..', '..', 'data', 'staff_dataBase.csv'))
        self.csv_path = csv_path

        if not os.path.exists(csv_path):
            pd.DataFrame(columns=["ID", "Name", "Level", "Gender", "Age", "Email"]).to_csv(csv_path, index=False)

    def operate(self):
        raise NotImplementedError("Subclasses must implement this")


class CreateStaff(StaffProfileOperation):

    def __init__(self, name, level, gender, age,email,status ,csv_path="data/staff_dataBase.csv"):

   

        super().__init__(csv_path)
        self.name = name
        self.level = level
        self.gender = gender
        self.age = age
        self.email = email
        self.status = status
        

    def _generate_new_id(self):
        df = pd.read_csv(self.csv_path)
        return 1001 if df.empty else int(df["ID"].max()) + 1

    def operate(self):
        new_id = self._generate_new_id()
        staff_data = {
            "ID": new_id,
            "Name": self.name,
            "Level": self.level,
            "Gender": self.gender,
            "Age": self.age,
            "Email" : self.email,
            "status": self.status

            

        }

        df = pd.read_csv(self.csv_path)
        df = pd.concat([df, pd.DataFrame([staff_data])], ignore_index=True)
        df.to_csv(self.csv_path, index=False)
        return f"{new_id} {self.name}"


class EditStaff(StaffProfileOperation):
    def __init__(self, staff_id, updates, csv_path=None):
        super().__init__(csv_path)
        self.staff_id = staff_id
        self.updates = updates

    def operate(self):
        if "ID" in self.updates:
            return ""  # Disallow ID update

        df = pd.read_csv(self.csv_path)
        if self.staff_id in df['ID'].values:
            df.loc[df['ID'] == self.staff_id, list(self.updates.keys())] = list(self.updates.values())
            df.to_csv(self.csv_path, index=False)
            return f"{self.staff_id}"
        else:
            return f"{self.staff_id}"


class DeleteStaff(StaffProfileOperation):
    def __init__(self, staff_id, csv_path=None):
        super().__init__(csv_path)
        self.staff_id = staff_id

    def operate(self):
        df = pd.read_csv(self.csv_path)
        if self.staff_id in df["ID"].values:
            df = df.drop(df[df["ID"] == self.staff_id].index)
            df.to_csv(self.csv_path, index=False)
            return f"{self.staff_id}"
        else:
            return f"{self.staff_id} not found"


class SearchStaff(StaffProfileOperation):
    def __init__(self, search_term, by="ID", csv_path=None):
        super().__init__(csv_path)
        self.search_term = search_term
        self.by = by

    def operate(self):
        df = pd.read_csv(self.csv_path)

        if self.by == "ID":
            try:
                search_val = int(self.search_term)
            except ValueError:
                return "error"
            result = df[df["ID"] == search_val]
        elif self.by == "Name":
            result = df[df["Name"].str.contains(self.search_term, case=False, na=False)]
        else:
            return "error"

        return result.to_dict(orient="records") if not result.empty else "error"
