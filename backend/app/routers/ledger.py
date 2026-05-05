"""Ledger endpoints."""

from fastapi import APIRouter, Depends, HTTPException

from ..database import get_data_client, unwrap_response
from ..schemas.auth import AuthUser
from ..schemas.ledger import (
    LedgerEntryCreate,
    LedgerEntryOut,
    LedgerEntryUpdate,
)
from .auth import get_current_user

router = APIRouter(prefix="/ledger", tags=["ledger"])

LEDGER_TABLE = "ledger_entries"


@router.get("/", response_model=list[LedgerEntryOut])
def list_entries(current_user: AuthUser = Depends(get_current_user)) -> list[LedgerEntryOut]:
    """List ledger entries for the current user."""

    client = get_data_client()
    response = (
        client.table(LEDGER_TABLE)
        .select("*")
        .eq("user_id", current_user.id)
        .order("occurred_at", desc=True)
        .execute()
    )
    data = unwrap_response(response, "Failed to fetch ledger entries")
    return data or []


@router.post("/", response_model=LedgerEntryOut)
def create_entry(
    entry: LedgerEntryCreate,
    current_user: AuthUser = Depends(get_current_user),
) -> LedgerEntryOut:
    """Create a new ledger entry."""

    payload = entry.model_dump()
    payload["user_id"] = current_user.id
    client = get_data_client()
    response = client.table(LEDGER_TABLE).insert(payload).execute()
    data = unwrap_response(response, "Failed to create ledger entry")
    if not data:
        raise HTTPException(status_code=400, detail="Ledger entry not created")
    return data[0]


@router.put("/{entry_id}", response_model=LedgerEntryOut)
def update_entry(
    entry_id: str,
    entry: LedgerEntryUpdate,
    current_user: AuthUser = Depends(get_current_user),
) -> LedgerEntryOut:
    """Update an existing ledger entry."""

    update_data = entry.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    client = get_data_client()
    response = (
        client.table(LEDGER_TABLE)
        .update(update_data)
        .eq("id", entry_id)
        .eq("user_id", current_user.id)
        .execute()
    )
    data = unwrap_response(response, "Failed to update ledger entry")
    if not data:
        raise HTTPException(status_code=404, detail="Ledger entry not found")
    return data[0]


@router.delete("/{entry_id}", response_model=dict)
def delete_entry(
    entry_id: str,
    current_user: AuthUser = Depends(get_current_user),
) -> dict:
    """Delete a ledger entry."""

    client = get_data_client()
    response = (
        client.table(LEDGER_TABLE)
        .delete()
        .eq("id", entry_id)
        .eq("user_id", current_user.id)
        .execute()
    )
    data = unwrap_response(response, "Failed to delete ledger entry")
    if not data:
        raise HTTPException(status_code=404, detail="Ledger entry not found")
    return {"status": "deleted", "id": entry_id}
