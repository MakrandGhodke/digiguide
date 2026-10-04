"""Tests for POST /predict covering each decision branch.

Fake index distance -> cosine similarity = 1 - d^2/2, and the visual threshold is 0.85:
    distance 0.0 -> similarity 1.0 (visual match)
    distance 2.0 -> similarity 0.0 (no visual match)
"""
import pytest
from conftest import LANDMARK, LANDMARK_KEY


def _post(client, jpeg, **form):
    return client.post("/predict", files={"file": ("photo.jpg", jpeg, "image/jpeg")}, data=form)


def test_server_not_ready_when_index_is_not_loaded(client, jpeg_bytes, monkeypatch):
    import main

    monkeypatch.setattr(main, "index", None)
    monkeypatch.setattr(main, "metadata", {})
    r = _post(client, jpeg_bytes)
    assert r.status_code == 500
    assert "not ready" in r.json()["detail"].lower()


def test_missing_file_is_validation_error(client, load_index):
    load_index(0.0)
    assert client.post("/predict").status_code == 422


def test_visual_match_returns_the_matched_landmark(client, load_index, jpeg_bytes):
    load_index(distance=0.0)
    r = _post(client, jpeg_bytes)
    assert r.status_code == 200
    prediction = r.json()["predictions"][0]
    assert prediction["matchType"] == "visual"
    assert prediction["id"] == LANDMARK_KEY
    assert prediction["score"] == pytest.approx(1.0)


def test_visual_match_at_threshold_boundary(client, load_index, jpeg_bytes):
    # similarity just below 0.85 must NOT count as a visual match
    # d such that 1 - d^2/2 = 0.84  ->  d = sqrt(0.32)
    load_index(distance=0.32 ** 0.5)
    r = _post(client, jpeg_bytes)
    assert r.json()["predictions"][0]["matchType"] != "visual"


def test_no_visual_match_with_location_returns_nearby_list_sorted(client, load_index, jpeg_bytes):
    load_index(distance=2.0)
    r = _post(client, jpeg_bytes, latitude=LANDMARK["lat"], longitude=LANDMARK["lon"])
    predictions = r.json()["predictions"]
    assert all(p["matchType"] == "list" for p in predictions)
    assert predictions[0]["id"] == LANDMARK_KEY
    assert len(predictions) <= 5
    distances = [p["distance"] for p in predictions]
    assert distances == sorted(distances)
    assert max(distances) <= 50.0  # SEARCH_RADIUS_KM


def test_no_match_and_no_location_returns_unknown(client, load_index, jpeg_bytes):
    load_index(distance=2.0)
    prediction = _post(client, jpeg_bytes).json()["predictions"][0]
    assert prediction["matchType"] == "unknown"
    assert prediction["id"] == "-1"
    assert prediction["score"] == 0.0


def test_no_match_and_location_far_from_every_landmark_returns_unknown(client, load_index, jpeg_bytes):
    load_index(distance=2.0)
    r = _post(client, jpeg_bytes, latitude=-33.86, longitude=151.21)  # Sydney
    assert r.json()["predictions"][0]["matchType"] == "unknown"


def test_each_prediction_gets_a_unique_image_id(client, load_index, jpeg_bytes):
    load_index(distance=0.0)
    first = _post(client, jpeg_bytes).json()["predictions"][0]["imageId"]
    second = _post(client, jpeg_bytes).json()["predictions"][0]["imageId"]
    assert first != second


@pytest.mark.xfail(
    strict=True,
    reason="BUG-2: an invalid upload is a client error but the API answers 500 (server error).",
)
def test_non_image_upload_is_a_client_error_not_a_server_error(client, load_index):
    load_index(0.0)
    r = client.post("/predict", files={"file": ("notes.txt", b"this is not an image", "text/plain")})
    assert 400 <= r.status_code < 500
