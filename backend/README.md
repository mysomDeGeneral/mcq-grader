# MCQ Grader Backend

## Overview

This backend provides an API for automated grading of multiple-choice question (MCQ) answer sheets using computer vision and deep learning. It supports user authentication, test management, and image-based mark detection using a YOLO model. Built with FastAPI and MongoDB.

## Features

- **User Authentication:** Register, login, and manage users securely.
- **Test Management:** Create, update, delete, and retrieve tests and scripts.
- **Automated Mark Detection:** Detect shaded bubbles and extract answers/index numbers from scanned answer sheets using YOLO.
- **Mark Scheme Generation:** Generate marking schemes from correctly shaded answer sheets.
- **Student Grading:** Automatically grade student answer sheets against a mark scheme.
- **Cloud Integration:** Download YOLO model weights from AWS S3.
- **Image Processing:** Uses OpenCV and Ultralytics YOLO.

## Directory Structure

```
backend/
│
├── main.py                  # FastAPI application entry point
├── users.py                 # User authentication endpoints
├── tests.py                 # Test and script management endpoints
├── models.py                # Pydantic models for API and database
├── auth.py                  # Authentication logic (JWT, password hashing)
├── database.py              # MongoDB connection setup
├── config.py                # Configuration and environment variables
├── yolo_based_mark_detection.py # Mark detection logic using YOLO
├── requirements.txt         # Python dependencies
├── Dockerfile               # Containerization setup
├── .env                     # Environment variables
└── ...
```
### Setup & Installation

1.  **Navigate to the backend folder:**
    ```sh
    cd backend
    ```
2.  **Install dependencies:**
    ```sh
    pip install -r requirements.txt
    ```
3. **Configure environment variables**
   - Copy `.env.example` to `.env` and set values for MongoDB, and JWT secret.
4. **Run the API**
   ```sh
   uvicorn main:app --reload
   ```
5. **Docker (optional)**
   ```sh
   docker build -t mcq-grader-backend .
   docker run -p 8000:8000 mcq-grader-backend
   ```

## API Endpoints

- `/users/register` - Register a new user
- `/users/token` - Login and obtain JWT token
- `/users/me` - Get current user info
- `/tests/` - Manage tests
- `/tests/scripts` - Manage scripts (student answer sheets)
- `/process_direct` - Upload and process an answer sheet image

## Dependencies

- FastAPI
- Motor (MongoDB async driver)
- Ultralytics YOLO
- OpenCV
- Boto3 (AWS S3)
- Passlib (bcrypt)
- PyJWT
- Pydantic

## Contributing

1. Fork the repository.
2. Create a feature branch.
3. Commit your changes.
4. Submit a pull request.

## License

MIT License


## Related Projects

-   [**Main Project README**](../README.md)


