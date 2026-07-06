# Inventory Management System — Flask REST API

A full CRUD RESTful API built with Flask and SQLAlchemy, with an external API
integration (Fake Store API) and a simple front-end for importing and viewing
inventory. Built as the Week 2 Summative Lab for the Moringa Python/Flask module.

## Task 1: Define the Problem

Small businesses need a simple way to track inventory (products, prices,
stock levels, categories) and to bootstrap that inventory from an external
product catalog instead of typing every item in by hand. This app exposes a
REST API for full CRUD on products, plus a route/UI that imports sample
products from a public external API (https://fakestoreapi.com) into the
local database.

## Task 2: Determine the Design

**Stack:** Flask, Flask-SQLAlchemy (SQLite), Requests, Pytest.

**Data model — `Product`**

| Field       | Type    | Notes                |
|-------------|---------|-----------------------|
| id          | Integer | Primary key           |
| name        | String  | Required              |
| description | String  | Optional              |
| price       | Float   | Default 0.0           |
| quantity    | Integer | Default 0              |
| category    | String  | Optional              |
| image       | String  | Optional image URL    |

**Routes**

| Method | Route                              | Purpose                                    |
|--------|-------------------------------------|---------------------------------------------|
| GET    | `/`                                  | UI: view inventory, import, add products     |
| GET    | `/products`                          | List all products                            |
| GET    | `/products/<id>`                     | Get a single product                         |
| POST   | `/products`                          | Create a product                             |
| PATCH  | `/products/<id>`                     | Update a product                             |
| DELETE | `/products/<id>`                     | Delete a product                             |
| GET    | `/products/category/<category>`      | Helper: filter by category                   |
| GET    | `/products/low-stock?threshold=5`    | Helper: low-stock report                     |
| GET    | `/external-products`                 | Preview products from the external API       |
| POST   | `/external-products/import`          | Import external products into the local DB   |

## Task 3: Develop the Code

```
inventory-management-api/
├── app.py               # Flask app + all routes
├── models.py             # SQLAlchemy Product model
├── config.py              # App configuration
├── templates/
│   └── index.html          # Minimal UI (import button + product table)
├── tests/
│   └── test_app.py           # Pytest suite
├── requirements.txt
└── README.md
```

### Setup

```bash
python3 -m venv venv
source venv/bin/activate        # Windows: venv\Scripts\activate
pip install -r requirements.txt
python app.py
```

Visit `http://127.0.0.1:5000/` for the UI, or hit the routes above directly
with curl/Postman/Insomnia.

### Example requests

```bash
curl -X POST http://127.0.0.1:5000/products \
  -H "Content-Type: application/json" \
  -d '{"name": "Laptop", "price": 999.99, "quantity": 5, "category": "Electronics"}'

curl -X PATCH http://127.0.0.1:5000/products/1 \
  -H "Content-Type: application/json" \
  -d '{"quantity": 10}'

curl -X POST http://127.0.0.1:5000/external-products/import
```

## Task 4: Test and Debug

Run the test suite:

```bash
pytest tests/ -v
```

The suite covers one feature per test: create, read (list), read (404
case), update, delete, and the external API import (mocked so tests don't
depend on the network).

## Task 5: Document and Maintain

- Keep this README updated whenever a route or model field changes.
- Use feature branches for new work and pull requests to merge into `main`
  (see Git workflow below) so history stays traceable.
- Re-run `pytest` before every push.

## Git Workflow (for the "Excelled" Git Management rubric row)

```bash
git init
git add .
git commit -m "Initial commit: project scaffold"
git branch -M main
git remote add origin <your-repo-url>
git push -u origin main

# For each feature, branch off main:
git checkout -b feature/crud-routes
# ...work, commit...
git push -u origin feature/crud-routes
# Open a Pull Request on GitHub, review, merge into main, then:
git checkout main
git pull
git branch -d feature/crud-routes
git push origin --delete feature/crud-routes
```

Repeat that branch → PR → merge → delete cycle for each feature
(e.g. `feature/external-api`, `feature/testing`) to satisfy "branches used,
pull requests merged, and branches cleared."
