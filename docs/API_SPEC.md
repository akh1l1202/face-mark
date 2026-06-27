# API Specification

**Project:** Face-Mark

**Version:** 1.0

---

# 1. Overview

Face-Mark exposes a RESTful API implemented using **FastAPI** to orchestrate teacher registration, face identification, and attendance sessions.

*   All endpoints communicate over HTTP (local development) and HTTPS (production).
*   Requests targeting the `/register` and `/identify` endpoints utilize `multipart/form-data` encoding to upload images.
*   Other endpoints consume and return standard JSON payloads.

---

# 2. Base URL

## Development
```text
http://192.168.0.113:8000
```
*(Configure the local IP address in the Flutter client code to enable communication with physical Android devices).*

---

# 3. API Conventions

### Success Response Format
Responses return a status code indicator string `"status"` along with response payload parameters:
```json
{
    "status": "OK",
    "message": "Operation completed.",
    "data": {}
}
```

---

### Error Response Format
If a request fails validation or hits an internal server exception, it throws standard HTTP error codes:
```json
{
    "detail": "Error description message."
}
```

---

# 4. Endpoint Summary

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| GET | `/` | Root health check. |
| POST | `/register` | Create teacher profile and enroll facial embeddings. |
| POST | `/identify` | Match frame image against teacher database. |
| GET | `/attendance/open-session` | Query if teacher has an active check-in session. |
| POST | `/attendance/entry` | Log check-in entry session. |
| POST | `/attendance/exit` | Log check-out exit session. |
| GET | `/teachers` | List all registered teachers. |
| DELETE | `/teacher/{teacherId}` | Delete specific teacher by ID. |
| DELETE | `/teachers` | Clear all teachers from the database. |

---

# 5. API Definitions

## 5.1. Root Health Check
*   **Method**: `GET`
*   **Endpoint**: `/`
*   **Purpose**: Verify if the backend server is running.
*   **Response**:
    ```json
    {
        "message": "Face backend up and running"
    }
    ```

---

## 5.2. Register Teacher & Face
*   **Method**: `POST`
*   **Endpoint**: `/register`
*   **Content-Type**: `multipart/form-data`
*   **Request Parameters (Form fields)**:
    *   `teacherId` (String, Required) — Unique teacher ID.
    *   `name` (String, Required) — Teacher's full name.
    *   `phone` (String, Required) — Contact phone number.
    *   `images` (List of Files, Required) — One or more face images to register.
    *   `profileIndex` (Int, Optional) — Index of the image to use for the cropped profile photo (default `0`).
*   **Response**:
    ```json
    {
        "status": "OK",
        "teacherId": "TCH001",
        "name": "John Doe",
        "phone": "9876543210",
        "numEmbeddings": 3,
        "addedThisRequest": 3,
        "profilePhoto": "http://192.168.0.113:8000/profile_photos/TCH001_1719472930222.jpg"
    }
    ```

---

## 5.3. Identify Face
*   **Method**: `POST`
*   **Endpoint**: `/identify`
*   **Content-Type**: `multipart/form-data`
*   **Request Parameters**:
    *   `image` (File, Required) — Camera frame snapshot.
*   **Success Response (Match Confirmed)**:
    ```json
    {
        "status": "OK",
        "teacherId": "TCH001",
        "name": "John Doe",
        "distance": 0.1245,
        "confidenceLevel": "HIGH",
        "suggestReRegister": false
    }
    ```
*   **Response (No Match)**:
    ```json
    {
        "status": "NO_MATCH",
        "bestDistance": 0.3842,
        "candidateTeacherId": "TCH001",
        "candidateTeacherName": "John Doe",
        "suggestReRegister": true
    }
    ```
*   **Response (No Face Detected)**:
    ```json
    {
        "status": "NO_FACE"
    }
    ```

---

## 5.4. Query Open Session
*   **Method**: `GET`
*   **Endpoint**: `/attendance/open-session`
*   **Query Parameters**:
    *   `teacherId` (String, Required) — Unique teacher ID.
*   **Response**:
    ```json
    {
        "hasOpenSession": true
    }
    ```

---

## 5.5. Attendance Entry (Check-In)
*   **Method**: `POST`
*   **Endpoint**: `/attendance/entry`
*   **Content-Type**: `application/x-www-form-urlencoded` or JSON
*   **Request Parameters (Form fields)**:
    *   `teacherId` (String, Required) — Identified teacher ID.
    *   `teacherName` (String, Required) — Identified teacher name.
    *   `mode` (String, Optional) — Check-in verification mode (defaults to `"FACE"`).
*   **Response (Session Created)**:
    ```json
    {
        "status": "CREATED",
        "docId": "attendance_doc_uid_123"
    }
    ```
*   **Response (Already Checked In)**:
    ```json
    {
        "status": "ALREADY_OPEN",
        "docId": "existing_attendance_doc_uid"
    }
    ```

---

## 5.6. Attendance Exit (Check-Out)
*   **Method**: `POST`
*   **Endpoint**: `/attendance/exit`
*   **Content-Type**: `application/x-www-form-urlencoded` or JSON
*   **Request Parameters (Form fields)**:
    *   `teacherId` (String, Required) — Identified teacher ID.
*   **Response (Session Closed)**:
    ```json
    {
        "status": "CLOSED",
        "docId": "attendance_doc_uid_123"
    }
    ```
*   **Response (No Open Session Found)**:
    ```json
    {
        "status": "NO_OPEN_SESSION"
    }
    ```

---

## 5.7. List Teachers
*   **Method**: `GET`
*   **Endpoint**: `/teachers`
*   **Response**:
    ```json
    {
        "status": "OK",
        "count": 1,
        "teachers": [
            {
                "teacherId": "TCH001",
                "name": "John Doe",
                "phone": "9876543210",
                "profilePhoto": "http://192.168.0.113:8000/profile_photos/TCH001_1719472930222.jpg",
                "numEmbeddings": 3
            }
        ]
    }
    ```

---

## 5.8. Delete Teacher
*   **Method**: `DELETE`
*   **Endpoint**: `/teacher/{teacherId}`
*   **Response**:
    ```json
    {
        "status": "OK",
        "deletedTeacherId": "TCH001"
    }
    ```

---

## 5.9. Clear All Teachers
*   **Method**: `DELETE`
*   **Endpoint**: `/teachers`
*   **Response**:
    ```json
    {
        "status": "OK",
        "deletedCount": 20
    }
    ```

---

# 6. HTTP Status Codes

| Code | Status | Meaning |
| :--- | :--- | :--- |
| `200` | OK | Success |
| `400` | Bad Request | Missing inputs or invalid facial capture |
| `404` | Not Found | Teacher profile not found |
| `500` | Internal Server Error | Firebase errors or OpenCV failures |
