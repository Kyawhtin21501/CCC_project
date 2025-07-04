from staff_pro import CreateStaff, EditStaff, DeleteStaff, SearchStaff


print("== Create ==")
staff1 = CreateStaff("Kha Lar Lay", 2, "Male", 20,"hein12345@gmail.com")
print(staff1.operate()) 
"""
staff2 = CreateStaff("Kyi Pyar Hlaing", 4, "Female", 24,"kyi1111@gmail.com")
print(staff2.operate()) 



print("\n== Edit ==")
edit = EditStaff(1001, {"Level": 3})
print(edit.operate())  


print("\n== Search by Name ==")
search_name = SearchStaff("Hlaing", by="Name")
print(search_name.operate()) 


print("\n== Search by ID ==")
search_id = SearchStaff(1001, by="ID")
print(search_id.operate())  


print("\n== Delete ==")
delete = DeleteStaff(1002)
print(delete.operate())  


print("\n== Search Deleted ==")
search_deleted = SearchStaff(1002, by="ID")
print(search_deleted.operate())

"""

