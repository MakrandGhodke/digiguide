"""Tests for /auth/signup, /auth/signin and /auth/me."""
import json
from datetime import datetime, timedelta

import main
import pytest
from jose import jwt


def test_signup_returns_token_and_user(client):
    r = client.post("/auth/signup", json={"email": "a@b.com", "password": "pw12345", "name": "Ann"})
    assert r.status_code == 200
    body = r.json()
    assert body["token_type"] == "bearer"
    assert body["access_token"]
    assert body["user"] == {"email": "a@b.com", "name": "Ann"}


def test_signup_duplicate_email_is_rejected(client, signed_up_user):
    r = client.post("/auth/signup", json={"email": signed_up_user["email"], "password": "other"})
    assert r.status_code == 400
    assert "already registered" in r.json()["detail"].lower()


def test_signup_stores_bcrypt_hash_not_plaintext(client, signed_up_user):
    stored = json.loads(open(main.USER_DB_FILE).read())[signed_up_user["email"]]
    assert stored["password_hash"] != signed_up_user["password"]
    assert stored["password_hash"].startswith("$2")  # bcrypt prefix
    assert "password" not in stored


def test_signup_missing_password_is_validation_error(client):
    r = client.post("/auth/signup", json={"email": "x@y.com"})
    assert r.status_code == 422


def test_signin_success(client, signed_up_user):
    r = client.post(
        "/auth/signin",
        json={"email": signed_up_user["email"], "password": signed_up_user["password"]},
    )
    assert r.status_code == 200
    assert r.json()["user"]["email"] == signed_up_user["email"]
    assert r.json()["access_token"]


def test_signin_wrong_password_returns_401(client, signed_up_user):
    r = client.post("/auth/signin", json={"email": signed_up_user["email"], "password": "wrong"})
    assert r.status_code == 401


def test_signin_unknown_email_returns_401(client):
    r = client.post("/auth/signin", json={"email": "ghost@nowhere.com", "password": "x"})
    assert r.status_code == 401


def test_error_message_does_not_reveal_whether_email_exists(client, signed_up_user):
    wrong_pw = client.post("/auth/signin", json={"email": signed_up_user["email"], "password": "bad"})
    no_user = client.post("/auth/signin", json={"email": "ghost@nowhere.com", "password": "bad"})
    assert wrong_pw.json()["detail"] == no_user.json()["detail"]


def test_me_with_valid_token(client, signed_up_user):
    r = client.get("/auth/me", headers={"Authorization": f"Bearer {signed_up_user['token']}"})
    assert r.status_code == 200
    assert r.json() == {"email": signed_up_user["email"], "name": signed_up_user["name"]}


def test_me_with_garbage_token_returns_401(client):
    r = client.get("/auth/me", headers={"Authorization": "Bearer not-a-real-token"})
    assert r.status_code == 401


def test_me_without_credentials_is_rejected(client):
    # FastAPI changed this status from 403 to 401 across versions; both mean "not authenticated".
    r = client.get("/auth/me")
    assert r.status_code in (401, 403)


def test_me_with_expired_token_returns_401(client, signed_up_user):
    expired = jwt.encode(
        {"sub": signed_up_user["email"], "exp": datetime.utcnow() - timedelta(days=1)},
        main.SECRET_KEY,
        algorithm=main.ALGORITHM,
    )
    r = client.get("/auth/me", headers={"Authorization": f"Bearer {expired}"})
    assert r.status_code == 401


def test_me_with_token_for_deleted_user_returns_401(client):
    token = main.create_access_token({"sub": "deleted@example.com"})
    r = client.get("/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 401


def test_jwt_secret_is_not_hardcoded():
    assert main.SECRET_KEY != "digiguide-secret-key-2024"
