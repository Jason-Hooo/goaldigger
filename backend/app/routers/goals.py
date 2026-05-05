"""Goal endpoints."""

from fastapi import APIRouter, Depends, HTTPException

from ..database import get_data_client, unwrap_response
from ..schemas.auth import AuthUser
from ..schemas.goals import GoalCreate, GoalOut, GoalUpdate
from .auth import get_current_user

router = APIRouter(prefix="/goals", tags=["goals"])

GOALS_TABLE = "goals"


@router.get("/", response_model=list[GoalOut])
def list_goals(current_user: AuthUser = Depends(get_current_user)) -> list[GoalOut]:
    """List goals for the current user."""

    client = get_data_client()
    response = (
        client.table(GOALS_TABLE)
        .select("*")
        .eq("user_id", current_user.id)
        .order("created_at", desc=True)
        .execute()
    )
    data = unwrap_response(response, "Failed to fetch goals")
    return data or []


@router.post("/", response_model=GoalOut)
def create_goal(
    goal: GoalCreate,
    current_user: AuthUser = Depends(get_current_user),
) -> GoalOut:
    """Create a new goal."""

    payload = goal.model_dump()
    payload["user_id"] = current_user.id
    client = get_data_client()
    response = client.table(GOALS_TABLE).insert(payload).execute()
    data = unwrap_response(response, "Failed to create goal")
    if not data:
        raise HTTPException(status_code=400, detail="Goal not created")
    return data[0]


@router.put("/{goal_id}", response_model=GoalOut)
def update_goal(
    goal_id: str,
    goal: GoalUpdate,
    current_user: AuthUser = Depends(get_current_user),
) -> GoalOut:
    """Update an existing goal."""

    update_data = goal.model_dump(exclude_unset=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")
    client = get_data_client()
    response = (
        client.table(GOALS_TABLE)
        .update(update_data)
        .eq("id", goal_id)
        .eq("user_id", current_user.id)
        .execute()
    )
    data = unwrap_response(response, "Failed to update goal")
    if not data:
        raise HTTPException(status_code=404, detail="Goal not found")
    return data[0]


@router.delete("/{goal_id}", response_model=dict)
def delete_goal(
    goal_id: str,
    current_user: AuthUser = Depends(get_current_user),
) -> dict:
    """Delete a goal."""

    client = get_data_client()
    response = (
        client.table(GOALS_TABLE)
        .delete()
        .eq("id", goal_id)
        .eq("user_id", current_user.id)
        .execute()
    )
    data = unwrap_response(response, "Failed to delete goal")
    if not data:
        raise HTTPException(status_code=404, detail="Goal not found")
    return {"status": "deleted", "id": goal_id}
