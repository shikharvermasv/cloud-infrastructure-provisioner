from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_health_check():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "healthy",
        "service": "cloud-provisioner-api",
    }


def test_create_resource():
    response = client.post(
        "/resources",
        json={
            "name": "test-vpc",
            "resource_type": "vpc",
            "environment": "dev",
        },
    )

    assert response.status_code == 201

    data = response.json()

    assert data["message"] == "Resource created successfully"
    assert data["resource"]["name"] == "test-vpc"


def test_get_resources():
    response = client.get("/resources")

    assert response.status_code == 200
    assert "resources" in response.json()


def test_get_resource():
    response = client.get("/resources/test-vpc")

    assert response.status_code == 200
    assert response.json()["name"] == "test-vpc"


def test_resource_not_found():
    response = client.get("/resources/does-not-exist")

    assert response.status_code == 404
    assert response.json() == {
        "detail": "Resource not found"
    }