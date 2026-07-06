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
