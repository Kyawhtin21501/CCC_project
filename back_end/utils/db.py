from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os


Base = declarative_base()

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_FILE = os.path.join(BASE_DIR, "../../ccc_project.db")
DATABASE_URL = f"sqlite:///{DATABASE_FILE}"







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
