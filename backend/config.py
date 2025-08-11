"""
config.py

Configuration module for MCQ Grader backend.

- Loads environment variables using python-dotenv.
- Provides default values for MongoDB connection, JWT secret, algorithm, and token expiry.

Variables:
- MONGODB_URL: MongoDB connection string.
- SECRET_KEY: Secret key for JWT token signing.
- ALGORITHM: JWT signing algorithm.
- ACCESS_TOKEN_EXPIRE_MINUTES: Token expiry duration in minutes.

Usage:
Import these variables wherever configuration is needed.
"""
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

MONGODB_URL = os.getenv("MONGODB_URL", "mongodb://localhost:27017")
SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 3000
