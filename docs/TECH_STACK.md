# Technology Stack

**Project:** Face-Mark

**Version:** 1.0

---

# 1. Overview

Face-Mark is built using a modern cross-platform mobile stack combined with a Python backend and Firebase cloud services. The selected technologies prioritize rapid development, maintainability, performance, and scalability while remaining accessible for student and educational projects.

---

# 2. Technology Overview

| Layer                  | Technology               | Purpose                                            |
| ---------------------- | ------------------------ | -------------------------------------------------- |
| Frontend               | Flutter                  | Cross-platform mobile UI                           |
| Language               | Dart                     | Frontend programming language                      |
| Backend                | FastAPI                  | REST API server                                    |
| Language               | Python                   | Backend business logic                             |
| Face Detection         | Google ML Kit            | Detect faces on-device                             |
| Face Recognition       | face_recognition (dlib)  | Generate and compare facial embeddings             |
| Image Processing       | OpenCV                   | Image preprocessing                                |
| Numerical Computing    | NumPy                    | Embedding manipulation and similarity calculations |
| Database               | Cloud Firestore          | Store application data                             |
| Authentication         | Firebase Authentication  | Secure administrator login                         |
| Notifications          | Firebase Cloud Messaging | Push notifications                                 |
| Package Manager        | pub                      | Flutter dependency management                      |
| Python Package Manager | pip                      | Backend dependency management                      |
| Version Control        | Git                      | Source control                                     |
| Repository Hosting     | GitHub                   | Collaboration and code hosting                     |

---

# 3. Frontend

## Flutter

### Purpose

Flutter is used to build the Android application that provides the user interface for administrators and the attendance kiosk.

### Why Flutter?

* High-performance rendering
* Rich widget ecosystem
* Single codebase for potential future iOS support
* Excellent Firebase integration
* Strong community support

### Responsibilities

* Authentication UI
* Camera interface
* Navigation
* Attendance screens
* Teacher management
* API communication

---

## Dart

### Purpose

Primary language for frontend development.

### Benefits

* Null safety
* Modern syntax
* Excellent tooling
* Fast compilation
* Tight integration with Flutter

---

# 4. Backend

## FastAPI

### Purpose

Expose REST endpoints and coordinate face recognition, attendance processing, and Firebase operations.

### Why FastAPI?

* High performance
* Automatic OpenAPI documentation
* Built-in request validation
* Asynchronous request handling
* Easy integration with Python ML libraries

### Responsibilities

* Receive camera images
* Register teachers
* Identify teachers
* Record attendance
* Trigger notifications

---

## Python

### Purpose

Implements business logic and machine learning workflows.

### Why Python?

* Rich AI ecosystem
* Mature computer vision libraries
* Excellent support for FastAPI
* Easy prototyping and maintenance

---

# 5. Artificial Intelligence

## Google ML Kit

### Purpose

Detect faces on the mobile device before sending images to the backend.

### Advantages

* On-device processing
* Fast detection
* Reduced backend workload
* Better user experience

---

## face_recognition

### Purpose

Generate facial embeddings and compare them with registered teachers.

### Features

* High-quality facial encodings
* Reliable comparison algorithms
* Easy integration with Python

---

## dlib

### Purpose

Underlying library powering face encoding and landmark detection.

### Advantages

* Accurate facial feature extraction
* Mature and widely adopted
* Proven performance in recognition tasks

---

## OpenCV

### Purpose

Image preprocessing before recognition.

### Responsibilities

* Image loading
* Cropping
* Color conversion
* Frame manipulation

---

## NumPy

### Purpose

Perform mathematical operations on facial embeddings.

### Responsibilities

* Vector normalization
* Distance calculations
* Similarity computations

---

# 6. Firebase Services

## Firebase Authentication

### Purpose

Authenticate administrators securely.

### Benefits

* Managed authentication
* Secure token handling
* Easy Flutter integration
* Minimal backend implementation

---

## Cloud Firestore

### Purpose

Primary cloud database for application data.

### Stores

* Teacher information
* Attendance records
* Application metadata

### Advantages

* Real-time synchronization
* Scalable NoSQL database
* Offline capabilities (future use)
* Managed infrastructure

---

## Firebase Cloud Messaging

### Purpose

Send push notifications to administrator devices.

### Notification Types

* Attendance recorded
* Teacher registered
* Recognition failures
* System alerts

---

# 7. Local Storage

## embeddings.json

### Purpose

Store generated facial embeddings locally on the backend.

### Current Implementation

* JSON-based storage
* Loaded during recognition
* Updated after teacher enrollment

### Future Improvements

* Vector database
* Cloud storage
* Encryption at rest

---

## profile_photos/

### Purpose

Store cropped teacher profile images.

### Uses

* Recognition reference
* Administrator interface
* Debugging and validation

---

# 8. Development Tools

## Git

Used for:

* Version control
* Branch management
* Collaboration
* History tracking

---

## GitHub

Used for:

* Repository hosting
* Issue tracking
* Documentation
* Release management

---

## Android Studio

Primary IDE for Flutter development.

### Responsibilities

* Emulator management
* Debugging
* APK generation
* Gradle configuration

---

## Visual Studio Code

Alternative lightweight development environment.

### Used For

* Flutter development
* Python backend
* Documentation
* Git integration

---

# 9. Dependency Management

## Flutter

Dependencies are managed using:

```bash
flutter pub get
```

Configuration file:

```text
pubspec.yaml
```

---

## Python

Dependencies are managed using:

```bash
pip install -r requirements.txt
```

Configuration file:

```text
requirements.txt
```

---

# 10. Technology Decisions

| Requirement      | Selected Technology      | Reason                          |
| ---------------- | ------------------------ | ------------------------------- |
| Mobile UI        | Flutter                  | Cross-platform, performant      |
| Backend API      | FastAPI                  | Fast, typed, easy to document   |
| Face Detection   | Google ML Kit            | On-device, efficient            |
| Face Recognition | face_recognition         | Proven facial embedding library |
| Image Processing | OpenCV                   | Industry standard               |
| Database         | Firestore                | Managed, scalable, real-time    |
| Authentication   | Firebase Authentication  | Secure and simple               |
| Notifications    | Firebase Cloud Messaging | Native push notifications       |

---

# 11. Alternatives Considered

| Requirement      | Alternative          | Reason Not Chosen                                         |
| ---------------- | -------------------- | --------------------------------------------------------- |
| Backend          | Flask                | Less performant and fewer built-in features than FastAPI  |
| Database         | PostgreSQL           | More operational overhead for the MVP                     |
| Mobile Framework | React Native         | Flutter offers more consistent UI and performance         |
| Face Detection   | OpenCV Haar Cascades | Less accurate than ML Kit                                 |
| Authentication   | Custom JWT System    | Firebase Authentication reduces implementation complexity |

---

# 12. Future Technology Improvements

Planned enhancements include:

* Docker for containerization
* GitHub Actions for CI/CD
* Cloud Run or VPS deployment
* Vector database for embeddings
* Liveness detection models
* TensorFlow Lite optimization
* Redis for caching
* Monitoring with Prometheus or Grafana

---

# End of Document
