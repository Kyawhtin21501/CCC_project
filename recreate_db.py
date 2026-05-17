import os
from sqlalchemy import create_engine

from dotenv import load_dotenv  

load_dotenv()  


DATABASE_URL = "sqlite:///./test.db"
engine = create_engine(DATABASE_URL)
