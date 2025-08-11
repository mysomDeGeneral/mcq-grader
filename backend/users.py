"""
users.py

User authentication and management endpoints for the MCQ Grader backend.

Features:
- User registration with password hashing and duplicate email check.
- JWT-based login and token generation.
- Endpoint to retrieve the current authenticated user's profile.

Endpoints:
- POST /users/register: Register a new user and return access token.
- POST /users/token: Login and obtain JWT token.
- GET /users/users/me: Get current authenticated user's profile.

Usage:
Import and include this router in your FastAPI app for user management.
"""
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from database import db
from models import UserCreate, User, Token, UserResponse
from auth import get_password_hash, authenticate_user, create_access_token, get_current_user
from datetime import timedelta
from config import ACCESS_TOKEN_EXPIRE_MINUTES

router = APIRouter()

@router.post("/register", response_model=UserResponse)
async def register_user(user: UserCreate):
    existing_user = await db.users.find_one({"email": user.email})
    if existing_user:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered")

    hashed_password = get_password_hash(user.password)

    user_dict = user.dict()
    user_dict.pop("password")
    user_dict["hashed_password"] = hashed_password

    result = await db.users.insert_one(user_dict)

    user_dict["id"] = str(result.inserted_id)

    access_token = create_access_token(
        data={"sub": user_dict['id'], "email": user.email},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )

    user_dict.pop("hashed_password")

    return {
        "user": user_dict,
        "access_token": access_token,
        "token_type": "bearer"
    }

@router.post("/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    user = await authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Incorrect email or password")

    print(user)
    access_token = create_access_token(
        data={"sub": str(user.id), "email": user.email},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES),
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/users/me", response_model=User)
async def read_users_me(current_user: User = Depends(get_current_user)):
    return current_user
