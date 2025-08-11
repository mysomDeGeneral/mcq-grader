# MCQ Grader (Mobile App)

MCQ Grader is a mobile application built with Flutter to streamline the grading of multiple-choice question (MCQ) scripts. It enables educators to create tests, scan answer sheets, mark scripts, view results, and export summaries. The app integrates with a backend for authentication, test management, and automated grading.

---

## Features

- **User Authentication:** Secure login and registration.
- **Test Management:** Create, view, and delete MCQ tests.
- **Marking Scheme:** Add marking schemes for each test.
- **Script Scanning:** Scan answer sheets using device camera.
- **Automated Grading:** Automatically grade scanned scripts.
- **Results & Statistics:** View individual and summary results.
- **Export to Excel:** Download results as Excel files.

---

## Important Note

**Marking is performed in the backend using a YOLO model.**  
An active internet connection is required for the app to communicate with the backend and process scanned answer sheets.

---

## Folder Structure

```
mobile/
├── lib/
│   ├── main.dart                # App entry point and root widget
│   ├── models/
│   │   └── answer.dart          # Data model for answers
│   ├── providers/
│   │   └── provider.dart        # State management for user and test data
│   ├── screens/
│   │   ├── answers_screen.dart      # Displays answers for a script
│   │   ├── create_test_screen.dart  # UI for creating a new test
│   │   ├── login_screen.dart        # User login screen
│   │   ├── preview_screen.dart      # Preview scanned images before processing
│   │   ├── register_screen.dart     # User registration screen
│   │   ├── results_screen.dart      # Shows summary statistics and charts
│   │   ├── scan_screen.dart         # Camera interface for scanning scripts
│   │   ├── test_screen.dart         # Main dashboard for managing tests
│   │   └── testdetail_screen.dart   # Detailed view for a single test
│   ├── services/
│   │   ├── api_service.dart         # Handles API requests
│   │   ├── auth_service.dart        # Authentication logic
│   │   ├── camera_service.dart      # Camera and image processing
│   │   ├── export_service.dart      # Export results to Excel
│   │   └── test_service.dart        # Test CRUD operations
│   ├── utils/                   # Utility functions
│   └── widgets/
│       └── summary_tab.dart     # Widget for displaying summary statistics and score distribution
├── assets/                      # Images, fonts, etc.
├── pubspec.yaml                 # Dependencies and assets
└── README.md                    # Project documentation
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Android/iOS device or emulator
- Backend server running (see backend setup)

### Installation

1.  **Navigate to the Flutter project folder:**
    ```sh
    cd mobile
    ```

2.  **Install dependencies:**
    ```sh
    flutter pub get
    ```

3. **Configure environment:**
   - Copy `.env.example` to `.env` and set value for the API URL `BASE_URL`
     

4. **Run the app:**
   ```sh
   flutter run
   ```

---

## API Integration

The app communicates with the backend via RESTful APIs for authentication, test management, and grading.  
**Note:** Ensure the backend is running and accessible at the API URL configured in your environment.

---

## Exporting Results

- Navigate to the test detail screen.
- Tap the **Export** button to download results as an Excel file.
- Files are saved to the device and can be shared.

---

## Troubleshooting

- **Network Error:** Check backend server status and API URL.
- **Build Issues:** Run `flutter clean` and try again.
- **Camera Issues:** Ensure device permissions are granted.

---
## FAQ

**Q:** How do I connect the app to a different backend?  
**A:** Change the `BASE_URL` in your `.env` file.

**Q:** Can I use the app offline?  
**A:** No, marking requires an internet connection to communicate with the backend YOLO model.

**Q:** Where can I report bugs?  
**A:** Open an issue on the [GitHub repository](https://github.com/mysomDeGeneral/mcq-grader/issues).

---

## Contributing

1. Fork the repository.
2. Create your feature branch (`git checkout -b feature/my-feature`).
3. Commit your changes (`git commit -am 'Add new feature'`).
4. Push to the branch (`git push origin feature/my-feature`).
5. Open a pull request.

---

## License

This project is licensed under the MIT License.

---

## Related Projects

- [MCQ Grader Backend](../backend/README.md)