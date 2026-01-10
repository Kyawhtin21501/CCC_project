import os
from flask import Flask
from flask_cors import CORS

# 自分のフォルダ内からインポートするため、ドット（.）を使います
from .database import engine, Base
# Blueprintのインポートも統一します
from .routes.staff_routes import staff_bp
from .routes.shift_pre_routes import shift_pre_bp
from .routes.daily_report_route import daily_report_bp
from .routes.prediction_routes import pred_sales_bp
from .routes.shift_routes import shift_ass_bp

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

# Gunicornが読み込むためのエントリーポイント
app = create_app()

# --- 重要：テーブルの自動作成 ---
with app.app_context():
    try:
        # テーブルを作成するためにモデルを読み込む必要があります
        from . import models 
        Base.metadata.create_all(bind=engine)
        print("✅ Database tables created successfully!")
    except Exception as e:
        print(f"❌ Database table creation failed: {e}")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)