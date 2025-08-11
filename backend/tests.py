"""
tests.py

Test and script management endpoints for the MCQ Grader backend.

Features:
- CRUD operations for tests (create, read, update, delete).
- Manage scripts (student answer sheets) associated with tests.
- Add, update, and delete scripts for a test.
- Retrieve all scripts for a test.
- Add marking schemes to tests.

Endpoints:
- POST /tests/: Create a new test.
- GET /tests/: Retrieve all tests for the current user.
- GET /tests/{test_id}: Retrieve a specific test.
- PUT /tests/{test_id}: Update a test.
- DELETE /tests/{test_id}: Delete a test and its scripts.
- DELETE /tests/: Delete all tests and their scripts for the user.
- POST /tests/scripts: Add or update a script for a test.
- GET /tests/{test_id}/scripts: Get all scripts for a test.
- DELETE /tests/{test_id}/scripts/{index_number}: Delete a specific script from a test.
- DELETE /tests/{test_id}/scripts: Delete all scripts from a test.

Helper Functions:
- add_script(test_id, script): Add or update a script in the database.
- add_scheme(test_id, scheme): Add a marking scheme to a test.

Usage:
Import and include this router in your FastAPI app for test and script management.
"""
from fastapi import APIRouter, Depends, HTTPException, Body
from typing import List, Dict, Any
from bson import ObjectId
from database import db
from models import TestCreate, Test, Script, TestUpdate
from auth import get_current_user
from models import User

router = APIRouter()

@router.post("/", response_model=Test)
async def create_test(test: TestCreate, current_user: User = Depends(get_current_user)):
    test_dict = test.dict()
    result = await db.tests.insert_one({**test_dict, "user_id": current_user.id})
    return {**test_dict, "id": str(result.inserted_id)}

@router.get("/", response_model=List[Test])
async def get_user_tests(current_user: User = Depends(get_current_user)):
    tests = []
    async for test in db.tests.find({"user_id": current_user.id}):
        tests.append({**test, "id": str(test["_id"])})
    return tests

@router.get("/{test_id}", response_model=Test)
async def get_test(test_id: str, current_user: User = Depends(get_current_user)):
    test = await db.tests.find_one({"_id": ObjectId(test_id), "user_id": current_user.id})
    if test is None:
        raise HTTPException(status_code=404, detail="Test not found")
    return {**test, "id": str(test["_id"])}

@router.put("/{test_id}", response_model=TestUpdate)
async def update_test(test_id: str, test: TestCreate, current_user: User = Depends(get_current_user)):
    test_dict = test.dict()
    await db.tests.update_one({"_id": ObjectId(test_id), "user_id": current_user.id}, {"$set": test_dict})
    return {**test_dict, "id": test_id}

@router.delete("/{test_id}")
async def delete_test(test_id: str, current_user: User = Depends(get_current_user)):
    result = await db.tests.delete_one({"_id": ObjectId(test_id), "user_id": current_user.id})
    # Also delete all scripts associated with the test
    await db.scripts.delete_many({"test_id": ObjectId(test_id)})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Test not found")
    return {"message": "Test and associated scripts deleted successfully"}

@router.delete("/")
async def delete_all_tests(current_user: User = Depends(get_current_user)):
    # Get all test IDs for the user
    test_ids = [test["_id"] async for test in db.tests.find({"user_id": current_user.id})]
    
    # Delete all tests and their associated scripts
    if test_ids:
        await db.tests.delete_many({"user_id": current_user.id})
        await db.scripts.delete_many({"test_id": {"$in": test_ids}})
    
    return {"message": "All tests and associated scripts deleted successfully"}

# New endpoint for adding a script
@router.post("/scripts", response_model=Script)
async def add_script_to_collection(script: Script, current_user: User = Depends(get_current_user)):
    test = await db.tests.find_one({"_id": ObjectId(script.test_id), "user_id": current_user.id})
    if not test:
        raise HTTPException(status_code=404, detail="Test not found or not owned by user")
    
    script_dict = script.dict(by_alias=True)

    result = await db.scripts.find_one_and_replace(
        filter={
            "test_id": ObjectId(script.test_id),
            "index_number": script.index_number
        },
        replacement=script_dict,
        upsert=True,  
        return_document=True  
    )
    
    return {**result, "_id": str(result["_id"]), "test_id": str(result["test_id"])}

@router.get("/{test_id}/scripts", response_model=List[Dict[str, Any]])
async def get_test_scripts(test_id: str, current_user: User = Depends(get_current_user)):
    test = await db.tests.find_one({"_id": ObjectId(test_id), "user_id": current_user.id})
    if test is None:
        raise HTTPException(status_code=404, detail="Test not found")
    
    scripts = []
    async for script in db.scripts.find({"test_id": ObjectId(test_id)}):
        script['_id'] = str(script['_id'])
        script['test_id'] = str(script['test_id'])
        scripts.append(script)
    return scripts

@router.delete("/{test_id}/scripts/{index_number}")
async def delete_script_from_test(test_id: str, index_number: str, current_user: User = Depends(get_current_user)):
    result = await db.scripts.delete_one({"test_id": ObjectId(test_id), "index_number": index_number})
    if result.deleted_count == 0:
        raise HTTPException(status_code=404, detail="Script not found")
    return {"message": "Script deleted successfully"}

@router.delete("/{test_id}/scripts")
async def delete_all_scripts_from_test(test_id: str, current_user: User = Depends(get_current_user)):
    result = await db.scripts.delete_many({"test_id": ObjectId(test_id)})
    return {"message": "All scripts deleted successfully"}

async def add_script(test_id, script):
    script_data = {
        "test_id": ObjectId(test_id),
        "index_number": script["index_number"],
        "score": script["score"],
        "answers": script.get("answers", []), # Use .get for robustness
        "script_file_id": script.get("script_file_id", ""),
    }

    result = await db.scripts.update_one(
        {"test_id": ObjectId(test_id), "index_number": script["index_number"]},
        {"$set": script_data},
        upsert=True
    )
    
    if result.upserted_id:
        return "Script added successfully"
    else:
        return "Script updated successfully"

async def add_scheme(test_id, scheme):
    await db.tests.update_one({"_id": ObjectId(test_id)}, {"$set": {"scheme": scheme['scheme']}})
    return "Scheme added successfully"