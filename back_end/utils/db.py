from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base



Base = declarative_base()

#BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_FILE = "postgresql://kyawhtin21501:JnLswv2jDtr9n152yzQbYRlksKV5llil@dpg-d4tdl1k9c44c73bm0b0g-a.singapore-postgres.render.com/omakase_shift_5rie"
DATABASE_URL = f"{DATABASE_FILE}"







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
