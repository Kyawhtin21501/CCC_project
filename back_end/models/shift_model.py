from sqlalchemy import Column, Integer, String,DATE
from ..utils.db import Base,engine
from sqlalchemy.orm import relationship

class ShiftMain(Base):
    __tablename__ = "shift_ass"

    id = Column(Integer, primary_key=True, autoincrement=True)
    date = Column(DATE, nullable=False)
    hour = Column(Integer, nullable=False)
    staff_id = Column(Integer, nullable=False)
    name = Column(String(50), nullable=False)
    level = Column(Integer, nullable=True)
    note = Column(String, nullable=True)

    def to_dict(self):
        return {
            "id": self.id,
            "date": self.date.isoformat(),
            "hour": self.hour,
            "staff_id": self.staff_id,
            "name": self.name,
            "level": self.level,
            "note": self.note
        }

