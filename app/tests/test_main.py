from fastapi.testclient import TestClient

from app.main import app, reset_items

client = TestClient(app)


def setup_function() -> None:
    reset_items()


def test_healthcheck_returns_expected_payload() -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "version": "1.0.0"}


def test_create_item_returns_created_item() -> None:
    payload = {"name": "widget", "description": "first item"}

    response = client.post("/items", json=payload)

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == payload["name"]
    assert data["description"] == payload["description"]
    assert data["id"]


def test_get_item_returns_existing_item() -> None:
    created = client.post("/items", json={"name": "widget", "description": "stored item"}).json()

    response = client.get(f"/items/{created['id']}")

    assert response.status_code == 200
    assert response.json() == created


def test_list_items_returns_all_existing_items() -> None:
    first = client.post("/items", json={"name": "widget", "description": "stored item"}).json()
    second = client.post("/items", json={"name": "gadget", "description": "another item"}).json()

    response = client.get("/items")

    assert response.status_code == 200
    assert response.json() == [first, second]


def test_get_item_returns_404_for_unknown_id() -> None:
    response = client.get("/items/missing-id")

    assert response.status_code == 404
    assert response.json() == {"detail": "Item not found"}
