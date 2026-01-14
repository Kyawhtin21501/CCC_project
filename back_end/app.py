from flask import Flask
from .routes.staff_routes import staff_bp
from  .routes.shift_pre_routes import shift_pre_bp
from  .routes.daily_report_route import daily_report_bp
from  .routes.prediction_routes import pred_sales_bp
from  .routes.shift_routes import shift_ass_bp

from flask_cors import CORS



def create_app():
    application = Flask(__name__)
    CORS(app)

    application.register_blueprint(staff_bp)
    application.register_blueprint(shift_pre_bp)
    application.register_blueprint(daily_report_bp)
    application.register_blueprint(pred_sales_bp)
    application.register_blueprint(shift_ass_bp)
    return application



if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=5000, debug=True)

  
