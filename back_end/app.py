# 修正前 (相対インポート)
# from .database import engine, Base 

# 修正後 (絶対パスで指定)

from back_end.utils.db import engine, Base
from flask import Flask
from flask_cors import CORS
# その他のインポートも同様に「back_end.」から始めてください
from back_end.routes.staff_routes import staff_bp
from back_end.routes.shift_pre_routes import shift_pre_bp
from back_end.routes.daily_report_route import daily_report_bp
from back_end.routes.prediction_routes import pred_sales_bp
from back_end.routes.shift_routes import shift_ass_bp

def create_app():
    application = Flask(__name__)
    CORS(application)

    # 各 Blueprint の登録
    application.register_blueprint(staff_bp)
    application.register_blueprint(shift_pre_bp)
    application.register_blueprint(daily_report_bp)
    application.register_blueprint(pred_sales_bp)
    application.register_blueprint(shift_ass_bp)

    return application

# アプリのインスタンスを作成
app = create_app()

# --- 修正点2: テーブルの自動作成（関数の外で1回だけ実行） ---
with app.app_context():
    try:
        # モデルを読み込んで Base にテーブル情報を登録させる
        from . import models 
        # Base と engine を使って実際にテーブルを作成
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created successfully!")
    except Exception as e:
        print(f"❌ Database table creation failed: {e}")

if __name__ == "__main__":
    # ローカル実行用
    app.run(host="0.0.0.0", port=5000, debug=True)