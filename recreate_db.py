from back_end.utils.db import Base, engine
#from back_end.models.staff_model import Staff
#from back_end.models.shift_pref_model import ShiftPre 

from back_end.models.daily_report_model import Daily_data
Base.metadata.create_all(bind=engine)
print("DB recreated")
