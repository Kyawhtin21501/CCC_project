from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint, Date, CheckConstraint, Time
from sqlalchemy.orm import relationship
from datetime import time
from ..utils.db import Base

class ShiftPre(Base):
    __tablename__ = "shift_pre"

    shift_id = Column(Integer, primary_key=True, autoincrement=True)

    staff_id = Column(Integer, ForeignKey("staff.id"), nullable=False)
    date = Column(Date, nullable=False)

    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)

    
    staff = relationship("Staff", back_populates="shift_preferences")
    __table_args__ = (
        UniqueConstraint("staff_id", "date", name="uq_staff_date"),
        CheckConstraint("start_time < end_time", name="ck_start_before_end"),
        
    )

    def to_dict(self):
        return {
            "shift_id": self.shift_id,
            "staff_id": self.staff_id,
            "date": self.date.isoformat(),
            "start_time": self.start_time.strftime("%H:%M") if self.start_time else None,
            "end_time": self.end_time.strftime("%H:%M") if self.end_time else None,
        }
