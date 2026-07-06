from flask import Flask, request, jsonify, render_template
import requests

from models import db, Product
from config import Config

EXTERNAL_API_URL = "https://fakestoreapi.com/products"


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.from_object(Config)
    if test_config:
        app.config.update(test_config)

    db.init_app(app)

    with app.app_context():
        db.create_all()

    # ---------- UI ----------
    @app.route("/")
    def home():
        return render_template("index.html")

    # ---------- CRUD: Products ----------
    @app.route("/products", methods=["GET"])
    def get_products():
        products = Product.query.all()
        return jsonify([p.to_dict() for p in products]), 200

    @app.route("/products/<int:product_id>", methods=["GET"])
    def get_product(product_id):
        product = Product.query.get(product_id)
        if not product:
            return jsonify({"error": "Product not found"}), 404
        return jsonify(product.to_dict()), 200

    @app.route("/products", methods=["POST"])
    def create_product():
        data = request.get_json(silent=True) or {}
        if not data.get("name"):
            return jsonify({"error": "'name' is required"}), 400

        product = Product(
            name=data.get("name"),
            description=data.get("description", ""),
            price=data.get("price", 0.0),
            quantity=data.get("quantity", 0),
            category=data.get("category", ""),
            image=data.get("image", ""),
        )
        db.session.add(product)
        db.session.commit()
        return jsonify(product.to_dict()), 201

    @app.route("/products/<int:product_id>", methods=["PATCH"])
    def update_product(product_id):
        product = Product.query.get(product_id)
        if not product:
            return jsonify({"error": "Product not found"}), 404

        data = request.get_json(silent=True) or {}
        for field in ["name", "description", "price", "quantity", "category", "image"]:
            if field in data:
                setattr(product, field, data[field])

        db.session.commit()
        return jsonify(product.to_dict()), 200

    @app.route("/products/<int:product_id>", methods=["DELETE"])
    def delete_product(product_id):
        product = Product.query.get(product_id)
        if not product:
            return jsonify({"error": "Product not found"}), 404

        db.session.delete(product)
        db.session.commit()
        return jsonify({"message": f"Product {product_id} deleted"}), 200

    # ---------- Helper routes ----------
    @app.route("/products/category/<string:category>", methods=["GET"])
    def get_products_by_category(category):
        products = Product.query.filter(Product.category.ilike(f"%{category}%")).all()
        return jsonify([p.to_dict() for p in products]), 200

    @app.route("/products/low-stock", methods=["GET"])
    def low_stock():
        threshold = request.args.get("threshold", 5, type=int)
        products = Product.query.filter(Product.quantity <= threshold).all()
        return jsonify([p.to_dict() for p in products]), 200

    # ---------- External API integration ----------
    @app.route("/external-products", methods=["GET"])
    def fetch_external_products():
        try:
            response = requests.get(EXTERNAL_API_URL, timeout=5)
            response.raise_for_status()
            return jsonify(response.json()), 200
        except requests.RequestException as e:
            return jsonify({"error": str(e)}), 502

    @app.route("/external-products/import", methods=["POST"])
    def import_external_products():
        try:
            response = requests.get(EXTERNAL_API_URL, timeout=5)
            response.raise_for_status()
            items = response.json()
        except requests.RequestException as e:
            return jsonify({"error": str(e)}), 502

        imported = []
        for item in items:
            title = item.get("title")
            if not title:
                continue
            if Product.query.filter_by(name=title).first():
                continue
            product = Product(
                name=title,
                description=item.get("description", ""),
                price=item.get("price", 0.0),
                quantity=10,
                category=item.get("category", ""),
                image=item.get("image", ""),
            )
            db.session.add(product)
            imported.append(product)

        db.session.commit()
        return jsonify({
            "imported_count": len(imported),
            "products": [p.to_dict() for p in imported],
        }), 201

    return app


if __name__ == "__main__":
    app = create_app()
    app.run(debug=True)
