# 📸 Facemark

> A modern, AI-powered touchless attendance system using face recognition. Built with **Flutter**, **FastAPI**, and **Firebase Firestore** to automate attendance for institutions and organizations.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-Python-green.svg)](https://fastapi.tiangolo.com)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange.svg)](https://firebase.google.com)

---

## 📂 Project Structure

The project has been restructured as a single repository containing both the frontend and backend applications to simplify management and synchronization:

```text
face-mark/
├── frontend/                  # Flutter mobile application (Teacher & Admin views)

├── backend/                   # FastAPI server running the face recognition engine
├── docs/                      # PRD, Specifications, and Architecture documents
├── .gitignore                 # Excludes system, build, and private database files
├── LICENSE                    # MIT License file
└── README.md                  # This file
```

- [frontend/](file:///D:/GitHub/face-mark/frontend) contains the Dart and Flutter cross-platform mobile application.
- [backend/](file:///D:/GitHub/face-mark/backend) contains the Python FastAPI backend, responsible for processing and storing face embeddings and synchronizing with Cloud Firestore.
- [docs/](file:///D:/GitHub/face-mark/docs) contains all specifications, product requirements (PRDs), and design documents.

---

## ⚡ Quick Start

### 1. Prerequisites
- **Flutter SDK** (Version 3.x recommended)
- **Python 3.10+**
- **C++ Compiler Tools** (Required for compiling Python `dlib`/`face_recognition` dependencies on Windows/macOS)

---

### 2. Run the Backend

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   # On Windows:
   venv\Scripts\activate
   # On macOS/Linux:
   source venv/bin/activate
   ```
3. Install required packages:
   ```bash
   pip install -r requirements.txt
   ```
4. Start the FastAPI server using Uvicorn:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```
   - **Interactive API Documentation (Swagger UI)**: `http://localhost:8000/docs`
   - **Health Check Endpoint**: `http://localhost:8000/`

---

### 3. Run the Frontend

1. Navigate to the frontend directory:
   ```bash
   cd frontend
   ```
2. Fetch package dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app on an emulator or connected physical device:
   ```bash
   flutter run
   ```

---

## ⚙️ Configuration & Databases

### Firebase Integration
- The Flutter application directly communicates with **Firebase Firestore** for authentication, real-time logging, and notification channels.
- The FastAPI backend integrates with Firebase Admin SDK using a service account credentials JSON. Make sure to specify your service account certificate path in [firebase_utils.py](file:///D:/GitHub/face-mark/backend/firebase_utils.py).

### Face Embeddings & Security
- Face embeddings are saved locally in the backend inside [embeddings.json](file:///D:/GitHub/face-mark/backend/embeddings.json) (which is ignored by Git).
- Cropped user profiles are cached inside the `backend/profile_photos/` folder (also ignored by Git).
- For staging/production, keep your credentials secure and never commit them to source control.

---

## 📄 License
This project is licensed under the [MIT License](LICENSE).
