"""
database.py

MongoDB connection setup for MCQ Grader backend.

- Uses Motor (async MongoDB driver) for non-blocking database operations.
- Loads MongoDB connection string from config.py.

Usage:
Import 'db' to access the database in your FastAPI routes and modules.
"""
from motor.motor_asyncio import AsyncIOMotorClient
from config import MONGODB_URL
# from pymongo.server_api import ServerApi # Not needed if you're not using it directly

client = AsyncIOMotorClient(MONGODB_URL)
db = client.mcq_grader