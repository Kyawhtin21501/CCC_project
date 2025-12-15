from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os


Base = declarative_base()


DATABASE_URL = "sqlite:///ccc_project.db"


engine = create_engine(
    DATABASE_URL,
    echo=True,       
    future=True
)


SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
