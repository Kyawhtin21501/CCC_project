from flask import Flask
from back_end.routes.staff_routes import staff_bp
from back_end.routes.shift_pre_routes import shift_pre_bp
from back_end.routes.daily_report_route import daily_report_bp
from back_end.routes.prediction_routes import pred_sales_bp
from back_end.routes.shift_routes import shift_ass_bp
from flask_cors import CORS

def create_app():
    application = Flask(__name__)
    # 修正点1: app ではなく application に変更
    CORS(application)

    application.register_blueprint(staff_bp)
    application.register_blueprint(shift_pre_bp)
    application.register_blueprint(daily_report_bp)
    application.register_blueprint(pred_sales_bp)
    application.register_blueprint(shift_ass_bp)
    return application


app = create_app()

if __name__ == "__main__":
    #for local
    app.run(host="0.0.0.0", port=5000, debug=True)