import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

Base = declarative_base()

# Renderの環境変数から取得（パスワードを隠す）
DATABASE_URL = "sqlite:////Users/khein21502/Documents/ccc_project_f/CCC_project/ccc_project.db"

# Render特有の postgres:// を postgresql:// に修正する処理
"""
if DATABASE_URL and DATABASE_URL.startswith("postgres://"):
    DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)
"""
# 環境変数がない場合のフォールバック（開発用）


engine = create_engine(
    DATABASE_URL, connect_args={"check_same_thread": False})    
   

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