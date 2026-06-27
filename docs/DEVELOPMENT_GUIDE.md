# Development Guide

**Project:** Face-Mark

**Version:** 1.0

---

# 1. Introduction

This guide explains how to set up a local development environment for Face-Mark.

It is intended for:

* Contributors
* Maintainers
* New developers
* Students learning from the project

After completing this guide, you should be able to:

* Clone the project
* Configure Firebase
* Run the backend
* Run the Flutter application
* Connect both applications
* Begin development

---

# 2. Prerequisites

Install the following software before starting.

## Required

| Software             | Version               |
| -------------------- | --------------------- |
| Flutter              | Latest Stable         |
| Dart                 | Included with Flutter |
| Python               | 3.10+                 |
| Git                  | Latest                |
| Android Studio       | Latest                |
| VS Code *(optional)* | Latest                |

---

# 3. Clone Repository

```bash
git clone https://github.com/akh1l1202/face-mark.git

cd face-mark
```

---

# 4. Repository Structure

```text
face-mark/

frontend/
backend/
docs/
README.md
```

---

# 5. Backend Setup

Navigate to backend.

```bash
cd backend
```

Create virtual environment.

```bash
python -m venv venv
```

Activate virtual environment.

Windows

```bash
venv\Scripts\activate
```

Linux / macOS

```bash
source venv/bin/activate
```

Install dependencies.

```bash
pip install -r requirements.txt
```

Run backend.

```bash
uvicorn main:app --reload
```

Backend should now be available at:

```text
http://localhost:8000
```

Swagger documentation:

```text
http://localhost:8000/docs
```

---

# 6. Frontend Setup

Navigate to frontend.

```bash
cd frontend
```

Install dependencies.

```bash
flutter pub get
```

Run application.

```bash
flutter run
```

---

# 7. Firebase Configuration

Before running the application, configure Firebase.

Requirements:

* Firebase Project
* Android Application
* Firestore Database
* Firebase Authentication
* Firebase Cloud Messaging

Download:

* `google-services.json`

Place it inside:

```text
frontend/android/app/
```

---

# 8. Firestore

Deploy Firestore rules.

```bash
firebase deploy --only firestore
```

Deploy indexes.

```bash
firebase deploy --only firestore:indexes
```

---

# 9. Connecting Frontend to Backend

The frontend communicates with FastAPI through `api_service.dart`.

During development, update the base URL to match your backend.

Example:

```dart
const baseUrl = "http://localhost:8000";
```

For physical Android devices, use your computer's local IP address instead of `localhost`.

---

# 10. Running the Complete System

Start services in this order:

1. Backend
2. Firebase
3. Flutter Application

Verify:

* Backend reachable
* Firebase initialized
* Camera permissions granted
* Login successful
* Face recognition functioning

---

# 11. Debugging

Common issues include:

### Backend not starting

Check:

* Python version
* Installed dependencies
* Virtual environment activation

---

### Flutter build fails

Run:

```bash
flutter clean

flutter pub get
```

---

### Camera unavailable

Verify:

* Camera permission
* Device hardware
* Emulator configuration

---

### Firebase connection issues

Check:

* `google-services.json`
* Firebase project configuration
* Firestore rules

---

### Backend connection errors

Ensure:

* Backend is running
* Correct base URL
* Same network for physical devices

---

# 12. Recommended Development Workflow

1. Create a feature branch.
2. Implement the feature.
3. Test locally.
4. Update documentation.
5. Commit changes.
6. Push branch.
7. Open a pull request.

---

# 13. Coding Standards

## Flutter

* Use meaningful widget names.
* Keep business logic out of UI.
* Reuse widgets where possible.
* Separate networking into services.

---

## Python

* Keep API routes focused.
* Validate all input.
* Use descriptive function names.
* Log meaningful errors.

---

## Documentation

Whenever functionality changes:

* Update the relevant document in `docs/`.
* Keep diagrams synchronized with implementation.

---

# 14. Git Workflow

Example:

```bash
git checkout -b feature/teacher-registration

git add .

git commit -m "Add teacher registration feature"

git push origin feature/teacher-registration
```

---

# 15. Project Checklist

Before submitting changes:

* Backend builds successfully.
* Flutter builds successfully.
* No sensitive files committed.
* Documentation updated.
* Code formatted.
* Tests pass.

---

# 16. Useful Commands

### Flutter

```bash
flutter pub get
flutter clean
flutter analyze
flutter test
```

### Python

```bash
pip install -r requirements.txt

uvicorn main:app --reload
```

### Git

```bash
git status

git pull

git push
```

---

# 17. Future Improvements

Future versions of the development workflow may include:

* Docker support
* GitHub Actions CI/CD
* Pre-commit hooks
* Automated formatting
* Automated testing
* Development containers

---

# End of Document
