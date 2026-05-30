from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from ..database import get_db_connection
from ..schemas import GoalCreate, GoalResponse, GoalUpdate
from pydantic import BaseModel
from datetime import datetime

class GoalAchieveResponse(BaseModel):
    goal_id: int
    completion_date: datetime

router = APIRouter(prefix="/goals", tags=["目標管理"])

@router.post("/", response_model=GoalResponse, status_code=status.HTTP_201_CREATED)
def create_goal(goal: GoalCreate, conn=Depends(get_db_connection)): # 💡 改用 Depends
    cursor = conn.cursor()
    try:
        insert_query = """
            INSERT INTO goals (user_id, goal_name, description, target_amount, deadline)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING goal_id, user_id, goal_name, description, target_amount, cumulative_amount, deadline;
        """
        cursor.execute(insert_query, (goal.user_id, goal.goal_name, goal.description, goal.target_amount, goal.deadline))
        new_goal = cursor.fetchone()
        conn.commit()
        return new_goal
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"新增目標失敗：{e}")
    finally:
        cursor.close()

@router.get("/detail/{goal_id}", response_model=GoalResponse)
def get_goal_detail(goal_id: int, conn=Depends(get_db_connection)):
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM goals WHERE goal_id = %s;", (goal_id,))
        goal = cursor.fetchone()
        if not goal:
            raise HTTPException(status_code=404, detail="找不到該目標")
        return goal
    finally:
        cursor.close()

@router.post("/achieve/{goal_id}", response_model=GoalAchieveResponse, status_code=status.HTTP_200_OK)
def achieve_goal(goal_id: int, conn=Depends(get_db_connection)):
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT goal_id, target_amount, cumulative_amount, deadline, status FROM goals WHERE goal_id = %s;", (goal_id,))
        goal = cursor.fetchone()
        if not goal:
            raise HTTPException(status_code=404, detail="目標不存在")
        if goal["cumulative_amount"] < goal["target_amount"]:
            raise HTTPException(status_code=400, detail="存錢進度尚未達標，還不能解鎖成就喔！")
        
        # Check if goal is already failed or achieved
        if goal["status"] == "failed":
            raise HTTPException(status_code=400, detail="目標已過期失敗，無法解鎖成就")
        if goal["status"] == "achieved":
            raise HTTPException(status_code=400, detail="目標已經解鎖成就了")
        
        # Check if deadline has passed
        if goal["deadline"] and datetime.now().date() > goal["deadline"]:
            raise HTTPException(status_code=400, detail="目標已過期失敗，無法解鎖成就")

        cursor.execute("""
            INSERT INTO achievements (goal_id, completion_date)
            VALUES (%s, CURRENT_TIMESTAMP)
            ON CONFLICT (goal_id) DO NOTHING
            RETURNING goal_id, completion_date;
        """, (goal_id,))
        achieve_data = cursor.fetchone()
        
        if not achieve_data:
            cursor.execute("SELECT goal_id, completion_date FROM achievements WHERE goal_id = %s;", (goal_id,))
            achieve_data = cursor.fetchone()

        # Update goal status to achieved
        cursor.execute("""
            UPDATE goals
            SET status = 'achieved'
            WHERE goal_id = %s;
        """, (goal_id,))

        conn.commit()
        return achieve_data
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"達成目標失敗：{e}")
    finally:
        cursor.close()

@router.get("/{user_id}", response_model=List[GoalResponse])
def get_user_goals(user_id: int, conn=Depends(get_db_connection)):
    cursor = conn.cursor()
    try:
        cursor.execute("""
            SELECT g.*, a.completion_date 
            FROM goals g
            LEFT JOIN achievements a ON g.goal_id = a.goal_id
            WHERE g.user_id = %s 
            ORDER BY g.goal_id DESC;
        """, (user_id,))
        return cursor.fetchall()
    finally:
        cursor.close()

@router.put("/{goal_id}", response_model=GoalResponse)
def update_goal(goal_id: int, payload: GoalUpdate, conn=Depends(get_db_connection)):
    """更新目標內容或調整進度。"""
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM goals WHERE goal_id = %s;", (goal_id,))
        existing = cursor.fetchone()
        if not existing:
            raise HTTPException(status_code=404, detail="找不到該目標")

        updated_goal_name = payload.goal_name if payload.goal_name is not None else existing["goal_name"]
        updated_description = (
            payload.description if payload.description is not None else existing["description"]
        )
        updated_target_amount = (
            payload.target_amount if payload.target_amount is not None else existing["target_amount"]
        )
        updated_deadline = payload.deadline if payload.deadline is not None else existing["deadline"]
        updated_cumulative_amount = (
            payload.cumulative_amount
            if payload.cumulative_amount is not None
            else existing["cumulative_amount"]
        )

        cursor.execute(
            """
            UPDATE goals
            SET goal_name = %s,
                description = %s,
                target_amount = %s,
                deadline = %s,
                cumulative_amount = %s
            WHERE goal_id = %s
            RETURNING goal_id, user_id, goal_name, description, target_amount, cumulative_amount, deadline, status;
            """,
            (
                updated_goal_name,
                updated_description,
                updated_target_amount,
                updated_deadline,
                updated_cumulative_amount,
                goal_id,
            ),
        )
        updated_goal = cursor.fetchone()

        conn.commit()
        return updated_goal
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"更新目標失敗：{e}")
    finally:
        cursor.close()

@router.delete("/{goal_id}", status_code=status.HTTP_200_OK)
def delete_goal(goal_id: int, conn=Depends(get_db_connection)):
    """刪除目標。"""
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM goals WHERE goal_id = %s;", (goal_id,))
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="找不到該目標")
        conn.commit()
        return {"status": "success", "message": "目標已刪除"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"刪除目標失敗：{e}")
    finally:
        cursor.close()
