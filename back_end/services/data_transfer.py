import pandas as pd
from sqlalchemy import create_engine

# CSV 読み込み
df = pd.read_csv("/Users/khein21502/Documents/project_root/CCC_project/data/data_for_dashboard/temporary_shift_database_for_dashboard.csv")
df = df.rename(columns={"ID" : "id", "Name" : "name"  } )
# PostgreSQL 接続
engine = create_engine("postgresql+psycopg2://khein21502:password@localhost:5432/ccc_project")

# テーブルにデータを追加
df.to_sql("temporary_shift_for_dashboard", engine, if_exists="append", index=False)
