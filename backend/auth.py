"""
auth.py

Authentication and authorization utilities for the MCQ Grader backend.

Features:
- Password hashing and verification using bcrypt via Passlib.
- JWT token creation and decoding for secure user sessions.
- FastAPI dependency for extracting and validating the current user from a JWT token.
- User authentication against MongoDB.

Functions:
- verify_password(plain_password, hashed_password): Verifies a password against its hash.
- get_password_hash(password): Hashes a password for storage.
- get_user(email): Retrieves a user by email from the database.
- authenticate_user(email, password): Authenticates a user by email and password.
- create_access_token(data, expires_delta): Creates a JWT access token.
- get_current_user(token): FastAPI dependency to get the current authenticated user from a JWT token.

Dependencies:
- FastAPI
- Passlib (bcrypt)
- PyJWT
- MongoDB (Motor)
- Pydantic models

Usage:
Import and use these functions for authentication in your FastAPI routes.
"""
from datetime import datetime, timedelta
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
import jwt
from passlib.context import CryptContext
from config import SECRET_KEY, ALGORITHM, ACCESS_TOKEN_EXPIRE_MINUTES
from database import db
from models import TokenData, UserInDB
from bson import ObjectId

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="users/token")


def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password):
    return pwd_context.hash(password)


async def get_user(email: str):
    user = await db.users.find_one({"email": email})
    if user:
        user["_id"] = str(user["_id"])
        return UserInDB(**user)


async def authenticate_user(email: str, password: str):
    user = await get_user(email)
    if not user or not verify_password(password, user.hashed_password):
        return False
    return user


def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    expire = datetime.now() + (expires_delta or timedelta(minutes=15))
    to_encode.update({"exp": expire})
    return jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)


async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        email = payload.get("email")
        if not user_id or not email:
            raise credentials_exception
        token_data = TokenData(user_id=user_id, email=email)
    except jwt.PyJWTError:
        raise credentials_exception

    user = await db.users.find_one({"_id": ObjectId(token_data.user_id)})
    if not user:
        raise credentials_exception
    user["_id"] = str(user["_id"])
    return UserInDB(**user)
