"""Auth router and dependencies."""

from typing import Any, Annotated

from fastapi import APIRouter, Depends, Header, HTTPException

from ..database import get_auth_client
from ..schemas.auth import AuthUser

router = APIRouter(prefix="/auth", tags=["auth"])


def _extract_bearer_token(authorization: str | None) -> str:
    """Extract a bearer token from an Authorization header."""

    if not authorization:
        raise HTTPException(status_code=401, detail="Missing Authorization header")
    parts = authorization.split()
    if len(parts) != 2 or parts[0].lower() != "bearer":
        raise HTTPException(status_code=401, detail="Invalid Authorization header")
    return parts[1]


def _extract_user_payload(user_response: Any) -> tuple[str, str | None]:
    """Extract user id and email from a Supabase user response."""

    if hasattr(user_response, "user") and getattr(user_response, "user"):
        user = user_response.user
        return getattr(user, "id"), getattr(user, "email", None)
    if isinstance(user_response, dict):
        user = user_response.get("user") or user_response
        user_id = user.get("id") if isinstance(user, dict) else None
        email = user.get("email") if isinstance(user, dict) else None
        if user_id:
            return user_id, email
    raise HTTPException(status_code=401, detail="Invalid user response")


def get_current_user(
    authorization: Annotated[str | None, Header()] = None,
) -> AuthUser:
    """Validate Supabase JWT and return the current user."""

    token = _extract_bearer_token(authorization)
    client = get_auth_client()
    try:
        user_response = client.auth.get_user(token)
    except Exception as exc:  # noqa: BLE001
        raise HTTPException(status_code=401, detail=f"Invalid token: {exc}") from exc
    user_id, email = _extract_user_payload(user_response)
    return AuthUser(id=user_id, email=email)


@router.get("/me", response_model=AuthUser)
def read_me(current_user: AuthUser = Depends(get_current_user)) -> AuthUser:
    """Return the current authenticated user."""

    return current_user
