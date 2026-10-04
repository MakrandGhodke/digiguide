"""Tests for /, /landmarks and /nearby."""
from conftest import LANDMARK, LANDMARK_KEY

REQUIRED_FIELDS = {"id", "name", "shortDescription", "longDescription", "lat", "lng", "city", "country"}


def test_root_reports_backend_running(client):
    r = client.get("/")
    assert r.status_code == 200
    assert "running" in r.json()["message"].lower()


def test_landmarks_lists_all_known_landmarks_except_unknown(client):
    r = client.get("/landmarks")
    assert r.status_code == 200
    ids = [lm["id"] for lm in r.json()["landmarks"]]
    assert LANDMARK_KEY in ids
    assert "unknown" not in ids
    assert len(ids) == len(set(ids))  # no duplicates


def test_each_landmark_has_required_fields(client):
    for lm in client.get("/landmarks").json()["landmarks"]:
        assert REQUIRED_FIELDS <= lm.keys(), f"{lm.get('id')} is missing fields"


def test_nearby_is_sorted_by_distance_and_nearest_is_the_queried_landmark(client):
    r = client.post("/nearby", data={"latitude": LANDMARK["lat"], "longitude": LANDMARK["lon"]})
    assert r.status_code == 200
    results = r.json()["landmarks"]
    distances = [lm["distance"] for lm in results]
    assert distances == sorted(distances)
    assert results[0]["id"] == LANDMARK_KEY
    assert results[0]["distance"] == 0.0


def test_nearby_missing_coordinates_is_validation_error(client):
    assert client.post("/nearby", data={"latitude": 49.87}).status_code == 422
    assert client.post("/nearby", data={}).status_code == 422


def test_nearby_rejects_non_numeric_coordinates(client):
    r = client.post("/nearby", data={"latitude": "abc", "longitude": "def"})
    assert r.status_code == 422
