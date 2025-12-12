from flask import Flask


from CCC_project.back_end.routes.staff_routes import staff_bp

from flask_cors import CORS



def create_app():
    app = Flask(__name__)
    CORS(app)

    app.register_blueprint(staff_bp)
    
    return app

if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
