"""Goal schemas."""

from datetime import datetime

from pydantic import BaseModel


class GoalBase(BaseModel):
    """Base fields for a goal."""

    title: str
    target_amount: float
    current_amount: float = 0
    due_date: datetime | None = None
    status: str = "active"
    note: str | None = None


class GoalCreate(GoalBase):
    """Payload to create a goal."""


class GoalUpdate(BaseModel):
    """Payload to update a goal."""

    title: str | None = None
    target_amount: float | None = None
    current_amount: float | None = None
    due_date: datetime | None = None
    status: str | None = None
    note: str | None = None


class GoalOut(GoalBase):
    """Goal returned from the API."""

    id: str
    user_id: str
    created_at: datetime | None = None
