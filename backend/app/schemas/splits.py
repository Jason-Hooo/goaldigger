"""Split bill schemas."""

from datetime import datetime

from pydantic import BaseModel


class SplitGroupBase(BaseModel):
    """Base fields for a split group."""

    name: str
    description: str | None = None


class SplitGroupCreate(SplitGroupBase):
    """Payload to create a split group."""


class SplitGroupOut(SplitGroupBase):
    """Split group returned from the API."""

    id: str
    owner_id: str
    created_at: datetime | None = None


class SplitMemberBase(BaseModel):
    """Base fields for a split group member."""

    name: str
    email: str | None = None


class SplitMemberCreate(SplitMemberBase):
    """Payload to add a member to a split group."""


class SplitMemberOut(SplitMemberBase):
    """Split group member returned from the API."""

    id: str
    group_id: str
    created_at: datetime | None = None


class SplitExpenseBase(BaseModel):
    """Base fields for a split expense."""

    group_id: str
    title: str
    amount: float
    paid_by: str
    occurred_at: datetime
    note: str | None = None


class SplitExpenseCreate(SplitExpenseBase):
    """Payload to create a split expense."""


class SplitExpenseUpdate(BaseModel):
    """Payload to update a split expense."""

    title: str | None = None
    amount: float | None = None
    paid_by: str | None = None
    occurred_at: datetime | None = None
    note: str | None = None


class SplitExpenseOut(SplitExpenseBase):
    """Split expense returned from the API."""

    id: str
    created_at: datetime | None = None

class SplitOverviewOut(BaseModel):
    """Split group overview specifically formatted for frontend SplitTile."""
    group_id: str
    title: str
    subtitle: str
    amount: str          
    net_balance: float   
    icon_type: str       
