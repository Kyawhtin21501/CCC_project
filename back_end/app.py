from flask import Flask
from .routes.staff_routes import staff_bp
from  .routes.shift_pre_routes import shift_pre_bp
from  .routes.daily_report_route import daily_report_bp
from  .routes.prediction_routes import pred_sales_bp
from flask_cors import CORS



def create_app():
    app = Flask(__name__)
    CORS(app)

    app.register_blueprint(staff_bp)
    app.register_blueprint(shift_pre_bp)
    app.register_blueprint(daily_report_bp)
    app.register_blueprint(pred_sales_bp)
    return app

if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
