from sqlalchemy import Column, Integer, String, Boolean, JSON
from ..utils.db import Base,engine


class Daily_data(Base):
    __tablename__ = "daily_data"

    id = Column(Integer, primary_key=True, index=True)

    date = Column(String, nullable=False)          # "2025-08-10"
    day = Column(String, nullable=False)           # "Monday"

    is_event = Column(Boolean, default=False)      # イベント有無

    customer_count = Column(Integer, nullable=False)
    sales = Column(Integer, nullable=False)

    staff_names = Column(JSON, nullable=False)     # ← list 保存ここ
    staff_count = Column(Integer, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "date": self.date,
            "day": self.day,
            "is_event": self.is_event,
            "customer_count": self.customer_count,
            "sales": self.sales,
            "staff_names": self.staff_names,
            "staff_count": self.staff_count,
        }
