from fastapi import APIRouter, HTTPException, Depends, status
from typing import List
from database import get_db_connection
from schemas import GoalCreate, GoalResponse
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
        check_query = """
            SELECT g.goal_id FROM goals g
            LEFT JOIN achievements a ON g.goal_id = a.goal_id
            WHERE g.user_id = %s AND a.goal_id IS NULL;
        """
        cursor.execute(check_query, (goal.user_id,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="請先完成目前的目標，再建立新的目標")

        insert_query = """
            INSERT INTO goals (user_id, goal_name, description, target_amount, deadline, image_path)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING goal_id, user_id, goal_name, description, target_amount, cumulative_amount, deadline, image_path;
        """
        cursor.execute(insert_query, (goal.user_id, goal.goal_name, goal.description, goal.target_amount, goal.deadline, goal.image_path))
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
        cursor.execute("SELECT goal_id, target_amount, cumulative_amount FROM goals WHERE goal_id = %s;", (goal_id,))
        goal = cursor.fetchone()
        if not goal:
            raise HTTPException(status_code=404, detail="目標不存在")
        if goal["cumulative_amount"] < goal["target_amount"]:
            raise HTTPException(status_code=400, detail="存錢進度尚未達標，還不能解鎖成就喔！")

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
        cursor.execute("SELECT * FROM goals WHERE user_id = %s ORDER BY goal_id DESC;", (user_id,))
        return cursor.fetchall()
    finally:
        cursor.close()