from faker import Faker
import random
from datetime import date, timedelta, time
from back_end.utils.db import engine
from back_end.models.staff_model import Staff
from back_end.models.shift_pref_model import ShiftPre

from sqlalchemy.orm import Session



def create_staff(session: Session):
    import pandas as pd
    # 1. ファイル読み込み
    df = pd.read_excel("/Users/khein21502/Documents/ccc_project_f/CCC_project/scripts/ppt_symdata_CCC_project.xlsx")
    
    # 2. 前処理（列名を小文字にして空白削除）
    df.columns = [c.strip().lower() for c in df.columns]

    # 3. 必要な列の抽出
    # もしExcel側が 'email' なら、ここで 'email' を指定します
    df = df[["name", "age", "level", "email", "status", "gender"]]
    
    staff_list = []
    for index, row in df.iterrows():
        # 4. モデルの属性名(e_mail)に合わせてマッピング
        staff_member = Staff(
            name=row["name"],
            age=row["age"],
            level=row["level"],
            status=row["status"],
            e_mail=row["email"],  # ここでDB側のカラム名 'e_mail' に変換
            gender=row["gender"]
        )
        staff_list.append(staff_member)
    
    # 5. 一括追加
    session.add_all(staff_list)
    session.commit()
    return staff_list

def main():
    session = Session(bind=engine)

    try:
        # テストデータの初期化（既存データの削除）
        print("🗑  Deleting old data...")
        session.query(ShiftPre).delete()
        session.query(Staff).delete()
        session.commit()

        # データの生成と保存
        print("📥 Inserting new staff data...")
        inserted_staff = create_staff(session)
        
        print(f"✅ {len(inserted_staff)} staff members generated")

    except Exception as e:
        session.rollback()
        print(f"❌ Error occurred: {e}")
    finally:
        session.close()

if __name__ == "__main__":
    main()