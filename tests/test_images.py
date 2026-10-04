"""Tests for GET /images/{landmark_name}/{filename}."""
import asyncio

import main
import pytest
from fastapi import HTTPException


@pytest.fixture
def dataset(tmp_path, monkeypatch):
    root = tmp_path / "dataset"
    (root / "castle").mkdir(parents=True)
    (root / "castle" / "front.jpg").write_bytes(b"front-image")
    (root / "castle" / "side.png").write_bytes(b"side-image")
    (tmp_path / "secret.txt").write_text("TOP-SECRET")  # lives OUTSIDE the dataset folder
    monkeypatch.setattr(main, "DATASET_DIR", str(root))
    return root


def test_serves_exact_file(client, dataset):
    r = client.get("/images/castle/front.jpg")
    assert r.status_code == 200
    assert r.content == b"front-image"


def test_falls_back_to_another_image_when_filename_is_stale(client, dataset):
    r = client.get("/images/castle/does-not-exist.jpg")
    assert r.status_code == 200
    assert r.content in (b"front-image", b"side-image")


def test_unknown_landmark_returns_404(client, dataset):
    assert client.get("/images/atlantis/x.jpg").status_code == 404


@pytest.mark.xfail(
    strict=True,
    reason="BUG-1: path traversal - '..' as landmark_name serves files outside the dataset folder.",
)
def test_path_traversal_cannot_read_files_outside_dataset(dataset):
    # Call the handler directly: HTTP clients normalise '..' away before it reaches the app.
    with pytest.raises(HTTPException) as exc:
        asyncio.run(main.serve_image("..", "secret.txt"))
    assert exc.value.status_code == 404
