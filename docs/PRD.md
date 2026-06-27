# Product Requirements Document (PRD)

**Project Name:** Facemark (Smart Attendance System)

**Version:** 1.0

**Status:** Draft

**Owner:** Akhil Tyagi

---

# 1. Executive Summary

Facemark is an AI-powered attendance management platform that automates attendance recording using facial recognition technology. It eliminates manual attendance methods such as paper registers, ID cards, and biometric scanners by providing a touchless, camera-based solution.

The system consists of a Flutter-based mobile application, a FastAPI backend for face recognition and business logic, and Firebase services for authentication, real-time data synchronization, and notifications.

---

# 2. Problem Statement

Most educational institutions and organizations still rely on manual attendance systems or fingerprint scanners that have several limitations:

* Time-consuming attendance process.
* Human errors during manual entry.
* Proxy attendance.
* Hygiene concerns with touch-based biometric devices.
* Difficult attendance tracking and reporting.
* No real-time visibility for administrators.

These issues reduce operational efficiency and increase administrative workload.

---

# 3. Product Vision

Build a fast, reliable, and scalable attendance management platform that can identify teachers using facial recognition and automatically record attendance with minimal user interaction.

The platform should provide real-time monitoring, secure data storage, and an intuitive administrative interface.

---

# 4. Goals

## Primary Goals

* Fully automate attendance.
* Reduce attendance time.
* Prevent proxy attendance.
* Provide real-time attendance visibility.
* Simplify teacher management.
* Minimize administrative effort.

## Secondary Goals

* Support multiple institutions.
* Enable analytics and reporting.
* Provide cloud synchronization.
* Scale to thousands of users.

---

# 5. Target Users

## Primary Users

* Teachers
* School administrators
* College administrators
* HR departments

## Secondary Users

* IT administrators
* System maintainers
* Developers

---

# 6. User Personas

### Teacher

**Needs**

* Quick attendance process.
* No manual interaction.
* Reliable recognition.
* Fast entry.

### Administrator

**Needs**

* Register teachers.
* Monitor attendance.
* Manage users.
* Receive notifications.
* View attendance history.

---

# 7. Scope

## In Scope

* Teacher registration.
* Face enrollment.
* Face recognition.
* Automatic attendance marking.
* Entry and exit logging.
* Attendance history.
* Teacher management.
* Firebase authentication.
* Push notifications.
* Firestore integration.
* FastAPI backend.
* Flutter mobile application.

## Out of Scope

* Student attendance.
* Payroll management.
* Leave management.
* Timetable management.
* Classroom scheduling.
* Web application.
* Offline facial recognition (initial release).

---

# 8. Functional Requirements

### Authentication

* Admin login.
* Secure authentication.
* Session management.

---

### Teacher Management

* Add teacher.
* Edit teacher.
* Delete teacher.
* View teacher list.
* Search teacher.
* Update profile.
* Register face.

---

### Face Registration

The system shall:

* Capture multiple facial images.
* Detect facial landmarks.
* Generate embeddings.
* Store embeddings securely.
* Validate image quality.
* Reject invalid registrations.

---

### Face Recognition

The system shall:

* Detect faces automatically.
* Generate embeddings.
* Compare embeddings.
* Calculate similarity score.
* Identify teacher.
* Handle unknown users.
* Prevent duplicate attendance.

---

### Attendance

The system shall:

* Automatically mark attendance.
* Record timestamp.
* Record entry and exit.
* Prevent duplicate entries.
* Display attendance history.

---

### Notifications

The system shall:

* Notify administrators when attendance is recorded.
* Notify registration completion.
* Notify recognition failures.
* Notify important system events.

---

# 9. Non-Functional Requirements

## Performance

* Recognition under 2 seconds.
* API response under 500 ms (excluding recognition).
* Support concurrent requests.

---

## Reliability

* 99% uptime target.
* Automatic retry for failed requests.
* Graceful error handling.

---

## Security

* Secure authentication.
* Protected APIs.
* Encrypted communication.
* Firestore security rules.
* Secure storage of face embeddings.

---

## Scalability

Support:

* Thousands of teachers.
* Multiple campuses.
* Multiple administrators.
* Cloud deployment.

---

## Usability

* Minimal user interaction.
* Clean interface.
* Simple navigation.
* Fast onboarding.

---

# 10. User Stories

### Teacher

As a teacher, I want my attendance to be recorded automatically when I stand in front of the kiosk so that I don't need to manually mark attendance.

---

### Administrator

As an administrator, I want to register new teachers so that they can use the system.

---

As an administrator, I want to receive notifications whenever attendance is recorded.

---

As an administrator, I want to search attendance history by teacher and date.

---

# 11. Success Metrics

The project will be considered successful if it achieves:

* Recognition accuracy above 95%.
* Attendance process under 5 seconds.
* Less than 1% duplicate attendance.
* High administrator satisfaction.
* Significant reduction in manual attendance effort.

---

# 12. Constraints

* Requires internet connectivity.
* Camera quality affects recognition accuracy.
* Lighting conditions influence performance.
* Firebase service availability.
* Mobile device compatibility.

---

# 13. Assumptions

* Teachers complete face enrollment before use.
* Administrators maintain teacher records.
* Devices have functional cameras.
* Users have authenticated access.

---

# 14. Risks

| Risk              | Impact | Mitigation                  |
| ----------------- | ------ | --------------------------- |
| Poor lighting     | High   | Image quality validation    |
| Camera failure    | High   | Error handling and retry    |
| Network outage    | Medium | Retry mechanisms            |
| False recognition | High   | Similarity threshold tuning |
| Firebase downtime | Medium | Graceful failure handling   |

---

# 15. Future Enhancements

* Face anti-spoofing.
* Liveness detection.
* Offline recognition.
* Student attendance.
* Attendance analytics.
* Export reports.
* Web dashboard.
* Multi-language support.
* Multi-campus management.
* QR code fallback.
* Geofencing.
* AI-powered attendance insights.

---

# 16. Release Plan

## MVP (Version 1.0)

* Admin authentication.
* Teacher registration.
* Face enrollment.
* Face recognition.
* Attendance marking.
* Attendance history.
* Push notifications.

## Version 1.1

* Analytics dashboard.
* Export attendance.
* Improved search and filtering.

## Version 2.0

* Offline support.
* Anti-spoofing.
* Multi-campus support.
* Student attendance.
* Web administration portal.

---

# 17. Acceptance Criteria

The MVP is complete when:

* Teachers can be registered.
* Facial data can be enrolled successfully.
* Teachers are recognized accurately.
* Attendance is automatically recorded.
* Administrators can monitor attendance in real time.
* Notifications are delivered successfully.
* Attendance history is searchable.
* All APIs function as specified.
