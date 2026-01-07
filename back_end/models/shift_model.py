from sqlalchemy import Column, Integer, String, Date
from ..utils.db import Base

class ShiftMain(Base):
    __tablename__ = "shift_ass"

    # シフト割当1件 = 1行
    id = Column(Integer, primary_key=True, autoincrement=True)

    # 時間情報
    date = Column(Date, nullable=False)
    hour = Column(Integer, nullable=False)

    # スタッフ情報
    staff_id = Column(Integer, nullable=False)
    name = Column(String(50), nullable=False)
    level = Column(Integer, nullable=True)
    status = Column(String(50), nullable=False)  # student / normal / etc

    # コスト情報
    salary = Column(Integer, nullable=False)

    # 予測・最適化結果
    
    # null = perfect（追加不要）
    # 数値 = あと何人入れられるか

    def to_dict(self):
        return {
            "id": self.id,
            "date": self.date.isoformat(),
            "hour": self.hour,
            "staff_id": self.staff_id,
            "name": self.name,
            "level": self.level,
            "status": self.status,
            "salary": self.salary,
      
            
        }
