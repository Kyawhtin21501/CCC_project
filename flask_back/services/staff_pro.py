import pandas as pd
import os

class StaffProfileOperation:
    def __init__(self, csv_path="data/staff_dataBase.csv"):
        self.csv_path = csv_path
        if not os.path.exists(csv_path):
            pd.DataFrame(columns=["ID", "Name", "Level", "Gender", "Age","Email"]).to_csv(csv_path, index=False)

    def operate(self):
        raise NotImplementedError("error")


class CreateStaff(StaffProfileOperation):
    def __init__(self, name, level, gender, age,email, csv_path="data/staff_dataBase.csv"):
        super().__init__(csv_path)
        self.name = name
        self.level = level
        self.gender = gender
        self.age = age
        self.email = email

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
            "Email" : self.email
        }

        df = pd.read_csv(self.csv_path)
        df = pd.concat([df, pd.DataFrame([staff_data])], ignore_index=True)
        df.to_csv(self.csv_path, index=False)
        return f"{new_id} {self.name}"


class EditStaff(StaffProfileOperation):
    def __init__(self, staff_id, updates, csv_path="data/staff_dataBase.csv.csv"):
        super().__init__(csv_path)
        self.staff_id = staff_id
        self.updates = updates

    def operate(self):
        if "ID" in self.updates:
            return ""

        df = pd.read_csv(self.csv_path)
        if self.staff_id in df['ID'].values:
            df.loc[df['ID'] == self.staff_id, list(self.updates.keys())] = list(self.updates.values())
            df.to_csv(self.csv_path, index=False)
            return f"{self.staff_id}"
        else:
            return f"{self.staff_id}"


class DeleteStaff(StaffProfileOperation):
    def __init__(self, staff_id, csv_path="data/staff_dataBase.csv"):
        super().__init__(csv_path)
        self.staff_id = staff_id

    def operate(self):
        df = pd.read_csv(self.csv_path)
        if self.staff_id in df['ID'].values:
            df = df[df['ID'] != self.staff_id]
            df.to_csv(self.csv_path, index=False)
            return f"{self.staff_id}"
        else:
            return f"{self.staff_id} "


class SearchStaff(StaffProfileOperation):
    def __init__(self, search_term, by="ID", csv_path="staff_dataBase.csv"):
        super().__init__(csv_path)
        self.search_term = search_term
        self.by = by  

    def operate(self):
        df = pd.read_csv(self.csv_path)
        if self.by == "ID":
            result = df[df["ID"] == self.search_term]
        elif self.by == "Name":
            result = df[df["Name"].str.contains(self.search_term, case=False, na=False)]
        else:
            return "error"

        if not result.empty:
            return result.to_dict(orient="records")
        else:
            return "error"
