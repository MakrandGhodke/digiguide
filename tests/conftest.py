"""Shared fixtures for the DigiGuide backend test suite.

Design notes
------------
* `utils.py` loads PyTorch + CLIP at import time. Tests replace it with a tiny stub
  *before* `main` is imported, so the suite runs in seconds and needs no model download.
* Every test gets its own temporary user database and upload folder, so tests never
  touch the real `users.json` or `dataset/` contents.
* The FAISS index is replaced by a fake whose distance we control, which lets us
  exercise each branch of /predict deterministically.
"""
import io
import os
import sys
import types
from pathlib import Path

import numpy as np
import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

# --- stub the heavy CLIP module BEFORE importing main ---------------------------------
_fake_utils = types.ModuleType("utils")


def _fake_image_to_embedding(image):
    vec = np.ones((1, 512), dtype="float32")
    return vec / np.linalg.norm(vec)


_fake_utils.image_to_embedding = _fake_image_to_embedding
sys.modules["utils"] = _fake_utils

import main  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from PIL import Image  # noqa: E402

LANDMARK_KEY = next(k for k in main.LANDMARK_INFO if k != "unknown")
LANDMARK = main.LANDMARK_INFO[LANDMARK_KEY]


class FakeIndex:
    """Stands in for faiss.Index: every query returns the same L2 distance."""

    def __init__(self, distance: float):
        self.distance = distance
        self.ntotal = 1

    def search(self, embedding, k):
        distances = np.full((1, k), self.distance, dtype="float32")
        indices = np.zeros((1, k), dtype="int64")
        return distances, indices


@pytest.fixture
def client(tmp_path, monkeypatch):
    users_file = tmp_path / "users.json"
    users_file.write_text("{}")
    monkeypatch.setattr(main, "USER_DB_FILE", str(users_file))
    uploads = tmp_path / "uploads"
    uploads.mkdir()
    monkeypatch.setattr(main, "TEMP_DIR", str(uploads))
    return TestClient(main.app)


@pytest.fixture
def load_index(monkeypatch):
    """Factory: load_index(distance) installs a fake index + one-entry metadata."""

    def _load(distance: float):
        monkeypatch.setattr(main, "index", FakeIndex(distance))
        monkeypatch.setattr(
            main, "metadata", {0: {"landmark_name": LANDMARK_KEY, "filename": "sample.jpg"}}
        )

    return _load


@pytest.fixture
def jpeg_bytes():
    buf = io.BytesIO()
    Image.new("RGB", (64, 48), color=(120, 90, 60)).save(buf, format="JPEG")
    return buf.getvalue()


@pytest.fixture
def signed_up_user(client):
    payload = {"email": "tester@example.com", "password": "S3cret-pass", "name": "Test User"}
    response = client.post("/auth/signup", json=payload)
    assert response.status_code == 200
    return {**payload, "token": response.json()["access_token"]}
