# Changelog

All notable changes to the **Facemark** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-06-27

This is the initial release of **Facemark**, a touchless, AI-powered attendance system using facial recognition.

### Added
* **FastAPI Backend**:
  * Face registration endpoint (`/register`) to extract face landmarks, compute L2-normalized embeddings, and save the best cropped profile picture.
  * Face identification endpoint (`/identify`) using Euclidean L2-distance centroids and self-learning adjustments on high confidence matches.
  * Attendance logging endpoints (`/attendance/entry`, `/attendance/exit`) with automatic entry/exit session tracking and duplicate prevention.
  * Firebase Admin SDK integrations (`firebase_utils.py`) to synchronize sessions with Cloud Firestore and trigger push notifications.
* **Flutter Frontend (Android-Only)**:
  * Teacher registration screen for creating records, capturing multiple face angles, and submitting data.
  * Camera-based kiosk screen using Google ML Kit for real-time face detection, capturing frames, and verifying check-ins.
  * Administration dashboard containing status summary cards, live attendance list streams, and teacher lookup directories.
* **Documentation**:
  * Set up PRD, System Architecture, Database Schema, Feature Specifications, API Specifications, Security guidelines, and Development/Deployment guides.
* **Project Tooling**:
  * MIT License file.
  * Multi-platform root `.gitignore` excluding system logs, IDE folders, Flutter build caches, and private user files (`embeddings.json`, `profile_photos/`).
  * Contributing guidelines (`CONTRIBUTING.md`).

### Changed
* **Project Restructuring**:
  * Unified the project layout by merging the backend FastAPI repository and frontend Flutter repository into a single mono-repo tracked by Git.
  * Rebranded all project files, READMEs, and specifications to use the **Facemark** name.

### Removed
* **Unused Client Platforms**:
  * Deleted `ios/` and `web/` platforms from the Flutter client application to keep the code lightweight and focused entirely on Android.
