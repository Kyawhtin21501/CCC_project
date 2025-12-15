from sqlalchemy import Column, Integer, String, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from utils.db import Base

class ShiftPre(Base):
    __tablename__ = "shift_pre"


    id = Column(Integer, primary_key=True, index=True)

 
    staff_id = Column(Integer, ForeignKey("staff.id"), nullable=False)
    date = Column(String, nullable=False)


    morning = Column(Integer, default=0)
    afternoon = Column(Integer, default=0)
    night = Column(Integer, default=0)

    staff = relationship("Staff", back_populates="shift_preferences")


    __table_args__ = (
        UniqueConstraint("staff_id", "date", name="uq_staff_date"),
    )
