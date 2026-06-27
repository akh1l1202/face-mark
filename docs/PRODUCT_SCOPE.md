# Product Scope

**Project:** Face-Mark

**Version:** 1.0 (MVP)

**Status:** Draft

---

# Purpose

This document defines the scope of the first production release of Face-Mark. It outlines the features that are included in Version 1.0, the intended users, supported platforms, and features intentionally deferred to future releases.

The goal of the MVP is to provide a reliable, touchless attendance system for teachers using facial recognition while keeping the implementation focused and maintainable.

---

# Target Environment

* Educational institutions
* Schools
* Colleges
* Training centers
* Small to medium organizations

---

# Supported Platforms

## Included

* Android (Flutter)

## Backend

* FastAPI
* Python
* Firebase Cloud Firestore
* Firebase Authentication
* Firebase Cloud Messaging

---

# Primary Users

### Teachers

Teachers interact with the kiosk application by standing in front of the camera. The system automatically recognizes the teacher and records attendance without manual input.

### Administrators

Administrators manage teacher records, register faces, monitor attendance, and receive notifications through the admin interface.

---

# MVP Features

## Authentication

* Secure administrator login
* Session management

---

## Teacher Management

* Register teachers
* Update teacher information
* Delete teachers
* Search teachers
* View teacher list

---

## Face Enrollment

* Capture teacher face
* Generate facial embeddings
* Store embeddings locally
* Validate enrollment quality

---

## Face Recognition

* Detect faces
* Generate embeddings
* Compare against registered teachers
* Identify teacher
* Handle unknown faces

---

## Attendance

* Automatic attendance marking
* Entry timestamp
* Exit timestamp
* Duplicate attendance prevention
* Attendance history

---

## Notifications

* Attendance alerts
* Registration confirmations
* Recognition failures

---

# Technical Scope

The MVP includes:

* Flutter Android application
* FastAPI backend
* Firebase integration
* Firestore synchronization
* Local embedding storage
* REST API communication

---

# Out of Scope

The following features are intentionally excluded from Version 1.0:

* Student attendance
* iOS support
* Web dashboard
* Offline facial recognition
* Face anti-spoofing
* Multi-campus management
* Payroll integration
* Leave management
* Attendance analytics
* Report generation
* QR code attendance
* Geofencing
* Multi-factor authentication

---

# Success Criteria

Version 1.0 is considered successful when:

* Teachers can be enrolled successfully.
* Teachers are recognized accurately.
* Attendance is recorded automatically.
* Administrators can manage teachers.
* Attendance data synchronizes correctly.
* Push notifications function reliably.

---

# Known Limitations

* Internet connection required.
* Recognition quality depends on lighting conditions.
* Android-only client.
* Local embedding storage on the backend.
* One organization per deployment.

---

# Future Releases

## Version 1.1

* Attendance reports
* Advanced search and filtering
* Export attendance records
* Dashboard improvements

## Version 2.0

* Anti-spoofing and liveness detection
* Student attendance
* Multi-campus support
* Web administration portal
* Cloud-based embedding storage
* Analytics dashboard
* Offline synchronization
