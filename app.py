from flask import Flask, render_template

from models import db
from config import Config


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.from_object(Config)
    if test_config:
        app.config.update(test_config)

    db.init_app(app)

    with app.app_context():
        db.create_all()

    @app.route("/")
    def home():
        return render_template("index.html")

    # --- CRUD routes added in feature/crud-and-routing ---
    # --- External API routes added in feature/crud-and-routing ---

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
