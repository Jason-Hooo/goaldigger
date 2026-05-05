"""Split bill endpoints."""

from fastapi import APIRouter, Depends, HTTPException

from ..database import get_data_client, unwrap_response
from ..schemas.auth import AuthUser
from ..schemas.splits import (
    SplitExpenseCreate,
    SplitExpenseOut,
    SplitExpenseUpdate,
    SplitGroupCreate,
    SplitGroupOut,
    SplitMemberCreate,
    SplitMemberOut,
)
from .auth import get_current_user

router = APIRouter(prefix="/splits", tags=["splits"])

GROUPS_TABLE = "split_groups"
MEMBERS_TABLE = "split_members"
EXPENSES_TABLE = "split_expenses"


def _ensure_group_owner(group_id: str, user_id: str) -> None:
    """Ensure the current user owns the split group."""

    client = get_data_client()
    response = (
        client.table(GROUPS_TABLE)
        .select("id")
        .eq("id", group_id)
        .eq("owner_id", user_id)
        .execute()
    )
    data = unwrap_response(response, "Failed to validate group")
    if not data:
        raise HTTPException(status_code=404, detail="Group not found")


@router.get("/groups", response_model=list[SplitGroupOut])
def list_groups(current_user: AuthUser = Depends(get_current_user)) -> list[SplitGroupOut]:
    """List split groups owned by the current user."""

    client = get_data_client()
    response = (
        client.table(GROUPS_TABLE)
        .select("*")
        .eq("owner_id", current_user.id)
        .order("created_at", desc=True)
        .execute()
    )
    data = unwrap_response(response, "Failed to fetch groups")
    return data or []


@router.post("/groups", response_model=SplitGroupOut)
def create_group(
    group: SplitGroupCreate,
    current_user: AuthUser = Depends(get_current_user),
) -> SplitGroupOut:
    """Create a split group."""

    payload = group.model_dump()
    payload["owner_id"] = current_user.id
    client = get_data_client()
    response = client.table(GROUPS_TABLE).insert(payload).execute()
    data = unwrap_response(response, "Failed to create group")
    if not data:
        raise HTTPException(status_code=400, detail="Group not created")
    return data[0]


@router.get("/groups/{group_id}/members", response_model=list[SplitMemberOut])
def list_members(
    group_id: str,
    current_user: AuthUser = Depends(get_current_user),
) -> list[SplitMemberOut]:
    """List members for a split group."""

    _ensure_group_owner(group_id, current_user.id)
    client = get_data_client()
    response = (
        client.table(MEMBERS_TABLE)
        .select("*")
        .eq("group_id", group_id)
        .order("created_at", desc=True)
        .execute()
    )
    data = unwrap_response(response, "Failed to fetch group members")
    return data or []


@router.post("/groups/{group_id}/members", response_model=SplitMemberOut)
def create_member(
    group_id: str,
    member: SplitMemberCreate,
    current_user: AuthUser = Depends(get_current_user),
) -> SplitMemberOut:
    """Add a member to a split group."""

    _ensure_group_owner(group_id, current_user.id)
    payload = member.model_dump()
    payload["group_id"] = group_id
    client = get_data_client()
    response = client.table(MEMBERS_TABLE).insert(payload).execute()
    data = unwrap_response(response, "Failed to add member")
    if not data:
        raise HTTPException(status_code=400, detail="Member not created")
    return data[0]


@router.get("/expenses", response_model=list[SplitExpenseOut])
def list_expenses(
    group_id: str | None = None,
    current_user: AuthUser = Depends(get_current_user),
) -> list[SplitExpenseOut]:
    """List split expenses for the current user."""

    client = get_data_client()
    query = client.table(EXPENSES_TABLE).select("*").eq("user_id", current_user.id)
    if group_id:
        query = query.eq("group_id", group_id)
    response = query.order("occurred_at", desc=True).execute()
    data = unwrap_response(response, "Failed to fetch split expenses")
    return data or []


@router.post("/expenses", response_model=SplitExpenseOut)
def create_expense(
    expense: SplitExpenseCreate,
    current_user: AuthUser = Depends(get_current_user),
) -> SplitExpenseOut:
    """Create a split expense."""

    _ensure_group_owner(expense.group_id, current_user.id)
    payload = expense.model_dump()
    payload["user_id"] = current_user.id
    client = get_data_client()
    response = client.table(EXPENSES_TABLE).insert(payload).execute()
    data = unwrap_response(response, "Failed to create split expense")
    if not data:
        raise HTTPException(status_code=400, detail="Split expense not created")
    return data[0]


@router.put("/expenses/{expense_id}", response_model=SplitExpenseOut)
def update_expense(
    expense_id: str,
    expense: SplitExpenseUpdate,
    current_user: AuthUser = Depends(get_current_user),
) -> SplitExpenseOut:
    """Update a split expense."""

    update_data = expense.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    client = get_data_client()
    response = (
        client.table(EXPENSES_TABLE)
        .update(update_data)
        .eq("id", expense_id)
        .eq("user_id", current_user.id)
        .execute()
    )
    data = unwrap_response(response, "Failed to update split expense")
    if not data:
        raise HTTPException(status_code=404, detail="Split expense not found")
    return data[0]


@router.delete("/expenses/{expense_id}", response_model=dict)
def delete_expense(
    expense_id: str,
    current_user: AuthUser = Depends(get_current_user),
) -> dict:
    """Delete a split expense."""

    client = get_data_client()
    response = (
        client.table(EXPENSES_TABLE)
        .delete()
        .eq("id", expense_id)
        .eq("user_id", current_user.id)
        .execute()
    )
    data = unwrap_response(response, "Failed to delete split expense")
    if not data:
        raise HTTPException(status_code=404, detail="Split expense not found")
    return {"status": "deleted", "id": expense_id}
