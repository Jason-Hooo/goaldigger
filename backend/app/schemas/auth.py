"""Auth schemas."""

from pydantic import BaseModel


class AuthUser(BaseModel):
    """Authenticated user identity."""

    id: str
    email: str | None = None
