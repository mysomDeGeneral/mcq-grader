"""
models.py

Pydantic models and custom types for MCQ Grader backend.

Features:
- Custom ObjectId type for MongoDB integration with Pydantic V2.
- Models for users, authentication, tests, scripts, and image processing requests.
- Field validation and serialization for API and database operations.

Classes:
- PyObjectId: Custom type for MongoDB ObjectId compatible with Pydantic V2.
- Script: Represents a student's answer script.
- UserBase, UserCreate, UserInDB, User, UserResponse: User models for registration, authentication, and responses.
- Token, TokenData: JWT token models.
- TestBase, TestCreate, TestUpdate, Test, TestInDB: Test models for CRUD operations.
- ImageProcessingRequest: Model for image processing API requests.

Usage:
Import these models for request validation, response formatting, and database operations.
"""
from bson import ObjectId
from pydantic import BaseModel, Field, EmailStr
from typing import List, Optional, Dict, Any
from pydantic_core import CoreSchema, PydanticCustomError, core_schema
from pydantic.json_schema import JsonSchemaValue

class PyObjectId(ObjectId):
    """
    Pydantic V2 compatible ObjectId custom type.
    """
    @classmethod
    def __get_pydantic_core_schema__(
        cls, source_type: Any, handler
    ) -> CoreSchema:
        """
        Pydantic V2 method to define a custom type's schema.
        This tells Pydantic how to validate and serialize the type.
        """
        def validate_object_id(value: str) -> ObjectId:
            if not ObjectId.is_valid(value):
                raise PydanticCustomError('invalid_object_id', 'Invalid ObjectId')
            return ObjectId(value)

        # This schema will first validate a string and then pass it to our custom validator.
        # It also specifies how to serialize the ObjectId back to a string for JSON.
        return core_schema.no_info_after_validator_function(
            validate_object_id,
            core_schema.str_schema(),
            serialization=core_schema.to_string_ser_schema(),
        )

class Script(BaseModel):
    id: Optional[PyObjectId] = Field(alias="_id")
    test_id: PyObjectId
    index_number: str
    answers: List[Any] = []
    score: int

    class Config:
        # Pydantic V2 no longer needs json_encoders for custom types defined this way.
        # The serialization is handled by __get_pydantic_core_schema__.
        # This is kept for any other potential ObjectId usage not as a PyObjectId.
        # Alternatively, you can use model_config.
        json_encoders = {ObjectId: str}
        # Pydantic V2 recommended config style.
        # model_config = ConfigDict(json_encoders={ObjectId: str})

class UserBase(BaseModel):
    email: str
    displayName: str
    # photoURL: Optional[str] = None

class UserCreate(UserBase):
    password: str = Field(..., min_length=6)

class UserInDB(UserBase):
    id: str = Field(alias="_id")
    hashed_password: str

    class Config:
        json_encoders = {ObjectId: str}

class User(UserBase):
    id: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    user_id: Optional[str] = None
    email: Optional[str] = None

class TestBase(BaseModel):
    class_: str
    course_code: str
    description: str
    name: str
    endNumber: int
    scheme: List[Any] = []

class TestUpdate(BaseModel):
    class_: Optional[str]
    course_code: Optional[str]
    description: Optional[str]
    name: Optional[str]
    endNumber: Optional[int]
    scheme: Optional[List[Any]] = []

class TestCreate(TestBase):
    pass

class Test(TestBase):
    id: str

class TestInDB(TestBase):
    id: str = Field(alias="_id")

class ImageProcessingRequest(BaseModel):
    image_url: str
    test_id: str
    end_number: int
    scheme_or_paper: bool

class UserResponse(BaseModel):
    user: User
    access_token: str
    token_type: str