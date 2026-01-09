from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base



Base = declarative_base()

#BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATABASE_FILE = "postgresql://kyawhtin21501:BFqWIxdu9xN2VXK2ewpV5ow4ApyTVLGQ@dpg-d5ft50vpm1nc73dmc9c0-a.virginia-postgres.render.com/ccc_project"
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
