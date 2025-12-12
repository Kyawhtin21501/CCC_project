from sqlalchemy import Column, Integer, String
from back_end.utils.db import Base

class Staff(Base):
    __tablename__ = "staff"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    age = Column(Integer, nullable=False)
    level = Column(Integer, nullable=False)
    status = Column(String(50), nullable=False)
    e_mail = Column(String(100), unique=True, nullable=False)


    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "age": self.age,
            "level": self.level,
            "status": self.status,
            "e_mail": self.e_mail
        }
