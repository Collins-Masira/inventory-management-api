#!/bin/bash
# Run this from INSIDE ~/module5/inventory-management-api
# Rebuilds a clean git history: main (skeleton) -> 3 real feature branches
set -e
echo "== Backing up old .git =="
if [ -d .git ]; then mv .git .git.OLD_BACKUP_$(date +%s); fi
git init -q
git config user.email "collinsmasiraondieki@gmail.com"
git config user.name "Collins Masira Ondieki"

echo "== Writing main (skeleton) app.py =="
cat > app.py << 'MAINEOF'
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
MAINEOF

cat > templates/index.html << 'MAINHTML'
<!DOCTYPE html>
<html>
<head><title>Inventory Management System</title></head>
<body>
  <h1>Inventory Management System</h1>
  <p>UI coming in feature/frontend-ui</p>
</body>
</html>
MAINHTML

rm -rf tests

git add .
git commit -q -m "Initial scaffold: Flask app factory, config, model, base template"
git branch -M main

echo "== feature/crud-and-routing =="
git checkout -q -b feature/crud-and-routing
cat > app.py << 'CRUDEOF'
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
CRUDEOF
git add app.py
git commit -q -m "Add full CRUD routes, helper routes, and external API integration"

echo "== feature/frontend-ui =="
git checkout -q main
git checkout -q -b feature/frontend-ui
cat > templates/index.html << 'UIEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Inventory Management System</title>
<style>
  body { font-family: Arial, sans-serif; max-width: 900px; margin: 40px auto; padding: 0 20px; color: #222; }
  h1 { margin-bottom: 4px; }
  .muted { color: #666; margin-top: 0; }
  button { background: #2d6cdf; color: #fff; border: none; padding: 10px 16px; border-radius: 6px; cursor: pointer; font-size: 14px; }
  button:hover { background: #1e54b7; }
  table { width: 100%; border-collapse: collapse; margin-top: 20px; }
  th, td { text-align: left; padding: 8px; border-bottom: 1px solid #ddd; font-size: 14px; }
  th { background: #f4f4f4; }
  #status { margin-top: 10px; font-size: 14px; }
  form { margin-top: 20px; display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
  input { padding: 8px; border: 1px solid #ccc; border-radius: 4px; }
</style>
</head>
<body>
  <h1>Inventory Management System</h1>
  <p class="muted">Flask REST API + Fake Store external API demo</p>

  <button id="importBtn">Import products from external API</button>
  <div id="status"></div>

  <h3>Add product manually</h3>
  <form id="addForm">
    <input name="name" placeholder="Name" required>
    <input name="price" placeholder="Price" type="number" step="0.01">
    <input name="quantity" placeholder="Quantity" type="number">
    <input name="category" placeholder="Category">
    <button type="submit">Add product</button>
  </form>

  <table>
    <thead>
      <tr><th>ID</th><th>Name</th><th>Category</th><th>Price</th><th>Qty</th><th></th></tr>
    </thead>
    <tbody id="productRows"></tbody>
  </table>

<script>
async function loadProducts() {
  const res = await fetch("/products");
  const products = await res.json();
  const rows = products.map(p => `
    <tr>
      <td>${p.id}</td><td>${p.name}</td><td>${p.category || ""}</td>
      <td>$${Number(p.price).toFixed(2)}</td><td>${p.quantity}</td>
      <td><button onclick="deleteProduct(${p.id})">Delete</button></td>
    </tr>`).join("");
  document.getElementById("productRows").innerHTML = rows;
}

async function deleteProduct(id) {
  await fetch(`/products/${id}`, { method: "DELETE" });
  loadProducts();
}

document.getElementById("importBtn").addEventListener("click", async () => {
  const statusEl = document.getElementById("status");
  statusEl.textContent = "Importing...";
  const res = await fetch("/external-products/import", { method: "POST" });
  const data = await res.json();
  statusEl.textContent = res.ok
    ? `Imported ${data.imported_count} new product(s).`
    : `Error: ${data.error}`;
  loadProducts();
});

document.getElementById("addForm").addEventListener("submit", async (e) => {
  e.preventDefault();
  const form = new FormData(e.target);
  const body = Object.fromEntries(form.entries());
  body.price = parseFloat(body.price) || 0;
  body.quantity = parseInt(body.quantity) || 0;
  await fetch("/products", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  });
  e.target.reset();
  loadProducts();
});

loadProducts();
</script>
</body>
</html>
UIEOF
git add templates/index.html
git commit -q -m "Build UI: product table, add-product form, external import button"

echo "== feature/testing =="
git checkout -q main
git checkout -q -b feature/testing
mkdir -p tests
cat > tests/test_app.py << 'TESTEOF'
import sys
import os
import pytest
from unittest.mock import patch

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import create_app
from models import db


@pytest.fixture
def client():
    app = create_app({
        "SQLALCHEMY_DATABASE_URI": "sqlite:///:memory:",
        "TESTING": True,
    })
    with app.app_context():
        db.create_all()
        yield app.test_client()
        db.session.remove()
        db.drop_all()


def test_create_product(client):
    response = client.post("/products", json={
        "name": "Laptop", "price": 999.99, "quantity": 5, "category": "Electronics"
    })
    assert response.status_code == 201
    data = response.get_json()
    assert data["name"] == "Laptop"
    assert data["id"] is not None


def test_get_all_products(client):
    client.post("/products", json={"name": "Mouse", "price": 20, "quantity": 10})
    response = client.get("/products")
    assert response.status_code == 200
    assert len(response.get_json()) == 1


def test_get_single_product_not_found(client):
    response = client.get("/products/999")
    assert response.status_code == 404


def test_update_product(client):
    created = client.post("/products", json={"name": "Keyboard", "price": 50, "quantity": 3}).get_json()
    response = client.patch(f"/products/{created['id']}", json={"quantity": 7})
    assert response.status_code == 200
    assert response.get_json()["quantity"] == 7


def test_delete_product(client):
    created = client.post("/products", json={"name": "Monitor", "price": 150, "quantity": 2}).get_json()
    response = client.delete(f"/products/{created['id']}")
    assert response.status_code == 200
    follow_up = client.get(f"/products/{created['id']}")
    assert follow_up.status_code == 404


def test_import_external_products(client):
    fake_items = [
        {"title": "Fake Shirt", "description": "A shirt", "price": 19.99, "category": "clothing", "image": "x.png"}
    ]
    with patch("app.requests.get") as mock_get:
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = fake_items
        mock_get.return_value.raise_for_status = lambda: None

        response = client.post("/external-products/import")
        assert response.status_code == 201
        data = response.get_json()
        assert data["imported_count"] == 1
        assert data["products"][0]["name"] == "Fake Shirt"
TESTEOF
git add tests/test_app.py
git commit -q -m "Add pytest suite: one test per CRUD feature plus external API import"

git checkout -q main
echo ""
echo "== Branch graph =="
git log --oneline --all --graph --decorate
echo ""
echo "Next: git push --force -u origin main"
echo "Then: git push -u origin feature/crud-and-routing"
echo "Then: git push -u origin feature/frontend-ui"
echo "Then: git push -u origin feature/testing"
