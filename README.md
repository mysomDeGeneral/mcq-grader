# MCQ Grader

MCQ Grader is a comprehensive system designed to automate the grading of multiple-choice question (MCQ) answer sheets. It consists of a mobile application built with Flutter and a powerful backend API developed with FastAPI. The system enables educators to create tests, scan answer sheets, and receive instant, automated grading using a YOLO model for mark detection.

---

### Features

-   **Mobile Application (Flutter):** Provides a user-friendly interface for test management, script scanning, results viewing, and data export.
-   **Backend API (FastAPI):** Handles core logic, including user authentication, test data storage, and the crucial automated grading process using a custom-trained YOLO model.
-   **Automated Grading:** Utilizes a YOLO model to accurately detect shaded answers and index numbers on scanned answer sheets.
-   **Data Management:** Securely stores test details, user information, and grading results using MongoDB.
-   **Results Export:** Allows educators to export grading results to an Excel file for easy record-keeping.

---

### Architecture

The system follows a client-server architecture:

-   **Client:** The Flutter mobile application handles all user interactions and sends requests to the backend API.
-   **Server:** The FastAPI backend processes these requests, communicates with the MongoDB database, and runs the YOLO model for computer vision tasks. The backend returns the graded results to the app.

---

### Getting Started

To run the full project, you will need to clone the repository and then set up both the backend and the Flutter application.

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/mysomDeGeneral/mcq-grader.git
    cd mcq-grader
    ```

2.  **Set up the Backend:**
    Navigate to the backend folder and follow its setup instructions.
    ```sh
    cd backend
    ```
    (See [**Backend README**](./backend/README.md) for details)

3.  **Set up the Flutter App:**
    Navigate to the Flutter app folder and follow its setup instructions.
    ```sh
    cd mobile
    ```
    (See [**Mobile App README**](./mobile/README.md) for details)
---

### License

This project is licensed under the MIT License.