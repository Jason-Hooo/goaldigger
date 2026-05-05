"""Ledger schemas."""

from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class LedgerEntryBase(BaseModel):
    """Base fields for a ledger entry."""

    type: Literal["income", "expense"]
    amount: float
    currency: str = "USD"
    category: str
    note: str | None = None
    occurred_at: datetime
    tags: list[str] = Field(default_factory=list)


class LedgerEntryCreate(LedgerEntryBase):
    """Payload to create a ledger entry."""


class LedgerEntryUpdate(BaseModel):
    """Payload to update a ledger entry."""

    type: Literal["income", "expense"] | None = None
    amount: float | None = None
    currency: str | None = None
    category: str | None = None
    note: str | None = None
    occurred_at: datetime | None = None
    tags: list[str] | None = None


class LedgerEntryOut(LedgerEntryBase):
    """Ledger entry returned from the API."""

    id: str
    user_id: str
    created_at: datetime | None = None
