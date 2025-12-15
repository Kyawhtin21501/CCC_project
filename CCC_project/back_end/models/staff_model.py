from sqlalchemy import Column, Integer, String
from ..utils.db import Base
from sqlalchemy.orm import relationship
class Staff(Base):
    __tablename__ = "staff"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    age = Column(Integer, nullable=False)
    level = Column(Integer, nullable=False)
    status = Column(String(50), nullable=False)
    e_mail = Column(String(100), unique=True, nullable=False)
    shift_preferences = relationship(
        "ShiftPre",
        back_populates="staff",
        cascade="all, delete-orphan"
    )

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "age": self.age,
            "level": self.level,
            "status": self.status,
            "e_mail": self.e_mail
        }
