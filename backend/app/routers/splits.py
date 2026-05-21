"""Split bill endpoints."""

from fastapi import APIRouter, Depends, HTTPException
from collections import defaultdict
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
    SplitOverviewOut,
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

def _ensure_group_access(group_id: str, current_user: AuthUser) -> None:
    """Ensure the current user owns the group OR is a member of it."""
    client = get_data_client()
    
    # 1. 檢查是否為 Owner
    group_resp = client.table(GROUPS_TABLE).select("id").eq("id", group_id).eq("owner_id", current_user.id).execute()
    if unwrap_response(group_resp):
        return # 是 Owner，放行
        
    # 2. 如果不是 Owner，檢查是否在成員表中 (透過 email 對應)
    member_resp = client.table(MEMBERS_TABLE).select("id").eq("group_id", group_id).eq("email", current_user.email).execute()
    if unwrap_response(member_resp):
        return # 是成員，放行
        
    # 兩者皆非，拒絕存取
    raise HTTPException(status_code=403, detail="Not authorized to access this group")

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

    _ensure_group_access(group_id, current_user)
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
    """List split expenses for a specific group, or all user's expenses."""
    client = get_data_client()
    query = client.table(EXPENSES_TABLE).select("*")
    
    if group_id:
        # 如果指定了群組，先檢查權限，然後撈取該群組的「所有」花費 (不限於 current_user)
        _ensure_group_access(group_id, current_user)
        query = query.eq("group_id", group_id)
    else:
        # 如果沒有指定群組，則只撈取該使用者自己創建的花費
        query = query.eq("user_id", current_user.id)
        
    response = query.order("occurred_at", desc=True).execute()
    data = unwrap_response(response, "Failed to fetch split expenses")
    return data or []


@router.post("/expenses", response_model=SplitExpenseOut)
def create_expense(
    expense: SplitExpenseCreate,
    current_user: AuthUser = Depends(get_current_user),
) -> SplitExpenseOut:
    """Create a split expense."""

    _ensure_group_access(expense.group_id, current_user)
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

@router.get("/groups/{user_id}", response_model=list[SplitOverviewOut])
def get_user_groups_overview(
    user_id: str, 
    current_user: AuthUser = Depends(get_current_user)
) -> list[SplitOverviewOut]:
    """為前端 SplitPage 提供群組列表與個人結餘摘要（高效批次版）。"""
    
    # 🛡️ 安全性防護：確保使用者只能查詢自己的分帳列表
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to access this user's groups")
        
    client = get_data_client()
    
    # 1. 找出使用者透過 Email 參與的所有群組 ID
    memberships_resp = client.table(MEMBERS_TABLE).select("group_id").eq("email", current_user.email).execute()
    participated_groups = unwrap_response(memberships_resp, "Failed to fetch memberships") or []
    my_group_ids = [m["group_id"] for m in participated_groups]
    
    # 2. 一併找出使用者自己建立的群組 ID，合併並去重複
    owned_resp = client.table(GROUPS_TABLE).select("id").eq("owner_id", user_id).execute()
    owned_groups = unwrap_response(owned_resp, "Failed to fetch owned groups") or []
    for g in owned_groups:
        if g["id"] not in my_group_ids:
            my_group_ids.append(g["id"])

    if not my_group_ids:
        return []
        
    # --- 🧠 效能優化：批次撈取，總共只打 3 次資料庫 ---
    groups_resp = client.table(GROUPS_TABLE).select("*").in_("id", my_group_ids).execute()
    groups = unwrap_response(groups_resp, "Failed to fetch groups detail") or []
    
    all_members_resp = client.table(MEMBERS_TABLE).select("*").in_("group_id", my_group_ids).execute()
    all_members = unwrap_response(all_members_resp, "Failed to fetch all members") or []
    
    all_expenses_resp = client.table(EXPENSES_TABLE).select("*").in_("group_id", my_group_ids).execute()
    all_expenses = unwrap_response(all_expenses_resp, "Failed to fetch all expenses") or []
    
    # --- 💾 記憶體內資料結構映射 ---
    members_by_group = defaultdict(list)
    for m in all_members:
        members_by_group[m["group_id"]].append(m)
        
    expenses_by_group = defaultdict(list)
    for e in all_expenses:
        expenses_by_group[e["group_id"]].append(e)
    
    overview_data = []
    
    # 3. 高速數據分流與結算
    for group in groups:
        group_id = group["id"]
        group_members = members_by_group[group_id]
        group_expenses = expenses_by_group[group_id]
        
        member_count = len(group_members)
        if member_count == 0:
            continue
            
        # 尋找當前使用者的 member_id
        my_member_id = next((m["id"] for m in group_members if m.get("email") == current_user.email), None)
        
        total_expense = 0.0
        user_paid = 0.0
        
        for exp in group_expenses:
            amount = float(exp.get("amount", 0))
            total_expense += amount
            if my_member_id and exp.get("paid_by") == my_member_id:
                user_paid += amount
                
        user_share = total_expense / member_count
        net_balance = user_paid - user_share if my_member_id else -user_share 
        
        # 4. 格式化輸出以完美對齊前端 SplitItem
        if net_balance > 0.01:
            amount_str = f"待收 ${net_balance:.0f}"
        elif net_balance < -0.01:
            amount_str = f"待付 ${abs(net_balance):.0f}"
        else:
            amount_str = "已結清"
            
        desc = group.get("description") or ""
        subtitle_text = f"{member_count} 人 - {desc}" if desc else f"{member_count} 人"
        
        icon_type = "group"
        if "旅行" in group["name"] or "飛" in group["name"]:
            icon_type = "flight"
        elif "買" in group["name"] or "購物" in group["name"]:
            icon_type = "shopping"
            
        overview_data.append(
            SplitOverviewOut(
                group_id=group_id,
                title=group["name"],
                subtitle=subtitle_text,
                amount=amount_str,
                net_balance=net_balance,
                icon_type=icon_type
            )
        )
        
    return overview_data

@router.get("/settle/{group_id}", response_model=list[dict])
def settle_group(group_id: str, current_user: AuthUser = Depends(get_current_user)) -> list[dict]:
    """Calculate minimum transactions to settle up a group."""
    
    _ensure_group_access(group_id, current_user)
    client = get_data_client()
    
    # 1. 取得成員清單
    members_resp = client.table(MEMBERS_TABLE).select("id, name").eq("group_id", group_id).execute()
    members = unwrap_response(members_resp, "Failed to fetch members") or []
    if not members:
        return []
        
    num_members = len(members)
    member_names = {m["id"]: m["name"] for m in members}
    
    # 2. 取得所有支出紀錄
    expenses_resp = client.table(EXPENSES_TABLE).select("amount, paid_by").eq("group_id", group_id).execute()
    expenses = unwrap_response(expenses_resp, "Failed to fetch expenses") or []
    
    # 3. 計算每位成員的淨餘額
    balances: dict[str, float] = defaultdict(float)
    for exp in expenses:
        amount = float(exp.get("amount", 0))
        paid_by = exp.get("paid_by")
        share = amount / num_members
        
        balances[paid_by] += amount
        for m in members:
            balances[m["id"]] -= share
            
    # 4. 分離債務人與債權人
    debtors = [{"id": k, "amount": abs(v)} for k, v in balances.items() if v < -0.01]
    creditors = [{"id": k, "amount": v} for k, v in balances.items() if v > 0.01]
            
    debtors.sort(key=lambda x: x["amount"], reverse=True)
    creditors.sort(key=lambda x: x["amount"], reverse=True)
    
    # 5. 貪婪演算法：搓合轉帳
    transactions = []
    i, j = 0, 0
    
    while i < len(debtors) and j < len(creditors):
        debtor = debtors[i]
        creditor = creditors[j]
        
        settle_amount = min(debtor["amount"], creditor["amount"])
        
        transactions.append({
            "from_member": member_names.get(debtor["id"], debtor["id"]),
            "to_member": member_names.get(creditor["id"], creditor["id"]),
            "amount": round(settle_amount, 2)
        })
        
        debtor["amount"] -= settle_amount
        creditor["amount"] -= settle_amount
        
        if debtor["amount"] < 0.01:
            i += 1
        if creditor["amount"] < 0.01:
            j += 1
            
    return transactions