from flask import Flask
from  back_end.routes.staff_routes import staff_bp
from  back_end.routes.shift_pre_routes import shift_pre_bp
from  back_end.routes.daily_report_route import daily_report_bp
from  back_end.routes.prediction_routes import pred_sales_bp
from  back_end.routes.shift_routes import shift_ass_bp

from flask_cors import CORS



def create_app():
    app = Flask(__name__)
    CORS(app)

    app.register_blueprint(staff_bp)
    app.register_blueprint(shift_pre_bp)
    app.register_blueprint(daily_report_bp)
    app.register_blueprint(pred_sales_bp)
    app.register_blueprint(shift_ass_bp)
    return app



if __name__ == "__main__":
    app = create_app()
    app.run(host="0.0.0.0", port=5000, debug=True)

  
