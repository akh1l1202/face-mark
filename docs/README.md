# 📸 Facemark

> A modern, AI-powered attendance management system built with **Flutter**, **FastAPI**, and **Firebase**, using facial recognition to automate attendance for educational institutions and organizations.

![Status](https://img.shields.io/badge/status-active-success)
![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-Python-green)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-orange)
![License](https://img.shields.io/badge/License-MIT-lightgrey)

---

# Overview

Facemark is an AI-powered attendance platform that replaces traditional attendance methods with automated facial recognition.

The system consists of two primary applications:

* **Teacher/Kiosk App** – Automatically detects and recognizes teachers using the device camera and records attendance.
* **Admin App** – Allows administrators to manage teachers, monitor attendance in real time, receive notifications, and access attendance history.

The backend is powered by **FastAPI** and a facial recognition engine built using Python. Facial embeddings are generated during enrollment and matched during attendance to identify teachers with high accuracy.

---

# Features

## Face Recognition

* Automatic face detection
* Face enrollment
* Face identification
* Multiple face encoding support
* Unknown face detection
* Confidence threshold matching

## Attendance

* Automatic attendance marking
* Entry & exit logging
* Real-time attendance updates
* Attendance history
* Duplicate attendance prevention

## Teacher Management

* Register teachers
* Edit teacher information
* Delete teachers
* Face re-enrollment

## Admin Dashboard

* Live teacher status
* Search teachers
* Attendance analytics
* Real-time updates
* Push notifications

## Notifications

* Firebase Cloud Messaging
* Attendance alerts
* Registration notifications
* System updates

---

# Tech Stack

| Layer               | Technology               |
| ------------------- | ------------------------ |
| Frontend            | Flutter                  |
| Language            | Dart                     |
| Backend             | FastAPI                  |
| Backend Language    | Python                   |
| Database            | Cloud Firestore          |
| Authentication      | Firebase Authentication  |
| Face Detection      | Google ML Kit            |
| Face Recognition    | face_recognition + dlib  |
| Notifications       | Firebase Cloud Messaging |
| Networking          | REST APIs                |
| Image Processing    | OpenCV                   |
| Numerical Computing | NumPy                    |

---

# System Architecture

```text
                +----------------------+
                |     Flutter App      |
                +----------+-----------+
                           |
                     REST API Calls
                           |
                           v
                +----------------------+
                |    FastAPI Backend   |
                +----------+-----------+
                           |
         +-----------------+------------------+
         |                                    |
         v                                    v
 Face Recognition Engine             Cloud Firestore
         |                                    |
         +-----------------+------------------+
                           |
                           v
                 Firebase Cloud Messaging
```

---

# Project Structure

```text
facemark/

├── frontend/
│   ├── lib/
│   ├── assets/
│   └── pubspec.yaml
│
├── backend/
│   ├── routes/
│   ├── services/
│   ├── models/
│   ├── utils/
│   ├── embeddings/
│   └── main.py
│
├── docs/
│
└── README.md
```

---

# Documentation

Complete project documentation can be found in the `docs` directory.

| Document             | Description                   |
| -------------------- | ----------------------------- |
| PRD.md               | Product Requirements Document |
| FEATURE_SPEC.md      | Functional specifications     |
| TECH_STACK.md        | Technology decisions          |
| ARCHITECTURE.md      | System architecture           |
| PROJECT_STRUCTURE.md | Folder organization           |
| DATABASE_SCHEMA.md   | Firestore schema              |
| API_SPEC.md          | Backend API documentation     |
| UI_UX_SPEC.md        | Screen specifications         |
| FACE_RECOGNITION.md  | Recognition engine            |
| SECURITY.md          | Security architecture         |
| DEVELOPMENT_GUIDE.md | Local development             |
| DEPLOYMENT.md        | Production deployment         |

---

# Getting Started

## Clone the Repository

```bash
git clone https://github.com/<username>/facemark.git
cd facemark
```

---

## Backend

```bash
cd backend

python -m venv venv

source venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Run the backend:

```bash
uvicorn main:app --reload
```

Backend URL:

```
http://localhost:8000
```

Swagger UI:

```
http://localhost:8000/docs
```

---

## Frontend

```bash
cd frontend

flutter pub get

flutter run
```

---

# Screenshots

> Screenshots will be added once the UI is finalized.

---

# Roadmap

* Face Anti-Spoofing
* Offline Attendance Sync
* Attendance Analytics
* Multi-Campus Support
* QR Code Fallback
* Export Reports
* Role-Based Access Control
* Attendance Reports
* Dashboard Analytics

---

# Contributing

Contributions, issues, and feature requests are welcome.

Please read the contribution guidelines before submitting pull requests.

---

# License

This project is licensed under the MIT License.

---

# Author

**Akhil Tyagi**

Computer Engineering Student
Flutter Developer • Backend Developer • AI Enthusiast
