from sqlalchemy import Column, Integer, String, Boolean, JSON,Date,Float
from ..utils.db import Base,engine

class Pred_sales(Base):
    __tablename__ = "prediction_sales"
    
    id = Column(Integer , primary_key=True, index=True)
    date = Column(Date , nullable=False)
    pred_sales = Column(Float , nullable=False)
    
    def to_dict(self):
        return{
            "id" : self.id,
            "date" : self.date,
            "pred_sales" : self.pred_sales
        }