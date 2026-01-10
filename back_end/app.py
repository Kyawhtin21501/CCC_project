import os
from flask import Flask
from flask_cors import CORS
# データベース(db)を定義しているファイルからインポートしてください
# あなたの構成に合わせて from back_end.models import db などに変更してください
# ここでは例として models からインポートすると仮定します
# from back_end.models import db 

from back_end.routes.staff_routes import staff_bp
from back_end.routes.shift_pre_routes import shift_pre_bp
from back_end.routes.daily_report_route import daily_report_bp
from back_end.routes.prediction_routes import pred_sales_bp
from back_end.routes.shift_routes import shift_ass_bp

def create_app():
    application = Flask(__name__)
    CORS(application)

    # --- データベース設定 ---
    uri = os.environ.get("DATABASE_URL")
    if uri and uri.startswith("postgres://"):
        uri = uri.replace("postgres://", "postgresql://", 1)
    
    application.config['SQLALCHEMY_DATABASE_URI'] = uri or 'sqlite:///default.db'
    application.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # db.init_app(application) # dbインスタンスがある場合に有効化してください

    application.register_blueprint(staff_bp)
    application.register_blueprint(shift_pre_bp)
    application.register_blueprint(daily_report_bp)
    application.register_blueprint(pred_sales_bp)
    application.register_blueprint(shift_ass_bp)

    # 修正点1: printをここから消して、applicationだけを返すようにします
    return application

# アプリを作成
app = create_app()

# --- 修正点2: テーブル自動作成の追加 ---
# db をインポートしている場合、以下のコメントアウトを外すとテーブルが自動で作られます
# with app.app_context():
#     db.create_all()

if __name__ == "__main__":
    # ローカル実行用
    app.run(host="0.0.0.0", port=5000, debug=True)