import os
from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

# 1. 環境変数の取得
DATABASE_URL = os.environ.get("DATABASE_URL")

# 2. ローカル環境（DATABASE_URLがない場合）のフォールバック設定
if not DATABASE_URL or DATABASE_URL.strip() == "":
    DATABASE_URL = "sqlite:///./local_test.db"
    print("ℹ️ DATABASE_URL 未設定のため、ローカル SQLite を使用します。")
else:
    # Render 等の PostgreSQL 用修正
    if DATABASE_URL.startswith("postgres://"):
        DATABASE_URL = DATABASE_URL.replace("postgres://", "postgresql://", 1)

# 3. エンジンとセッションの作成
# SQLite の場合は check_same_thread=False が必要
if "sqlite" in DATABASE_URL:
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- 重要：ここから下が足りていなかった部分です ---

def get_db():
    """
    データベースセッションを作成し、処理が終わったら自動で閉じる関数。
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()