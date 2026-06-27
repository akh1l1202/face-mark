import os
from datetime import datetime
from zoneinfo import ZoneInfo

import firebase_admin
from firebase_admin import credentials, firestore, messaging


# =========================
# Timezone (Mumbai / IST)
# =========================

IST = ZoneInfo("Asia/Kolkata") # Change accordingly to your timezone


# =========================
# Firebase Initialization
# =========================

def init_firebase():
    if firebase_admin._apps:
        return

    sa_path = "C:\\Users\\Akhil Tyagi\\Documents\\teacher-attendance-5489f-firebase-adminsdk-fbsvc-0c71b13ac9.json"

    if not os.path.exists(sa_path):
        raise RuntimeError("Firebase service account key not found")

    cred = credentials.Certificate(sa_path)
    firebase_admin.initialize_app(cred)


def get_db():
    if not firebase_admin._apps:
        raise RuntimeError("Firebase not initialized")
    return firestore.client()


def _today_date_string() -> str:
    return datetime.now(tz=IST).strftime("%Y-%m-%d")


# =========================
# ENTRY  (EXACT Flutter logic)
# =========================

def create_entry_session_sync(
    teacherId: str,
    teacherName: str,
    mode: str = "FACE",
):
    """
    Backend equivalent of Flutter logic:

    WHERE teacherId == X
    WHERE checkOut == null
    (NO date filter — overnight allowed)

    If exists → DO NOT create new
    Else → create new session
    """

    db = get_db()
    now = datetime.now(tz=IST)

    # === SAME CHECK AS FLUTTER ===
    q = (
        db.collection("attendanceSessions")
        .where("teacherId", "==", teacherId)
        .where("checkOut", "==", None)
        .limit(1)
        .get()
    )

    if q:
        doc = q[0]
        return {
            "status": "ALREADY_OPEN",
            "docId": doc.id,
        }

    # === SAME CREATE AS FLUTTER ===
    doc_ref = db.collection("attendanceSessions").document()
    doc_ref.set({
        "teacherId": teacherId,
        "teacherName": teacherName,
        "date": _today_date_string(),
        "checkIn": now,                  # Firestore Timestamp (IST)
        "checkOut": None,
        "mode": mode,
        "createdAt": firestore.SERVER_TIMESTAMP,
    })

    # === High-priority notification ===
    send_notification_topic_sync(
        title=f"Teacher entered: {teacherName}",
        body=f"Check-in at {now.strftime('%H:%M')} ({mode})",
    )

    return {
        "status": "CREATED",
        "docId": doc_ref.id,
    }


# =========================
# EXIT  (EXACT Flutter logic)
# =========================

def close_open_session_for_teacher_sync(teacherId: str):
    """
    Backend equivalent of Flutter closeSession:

    - Find open session (checkOut == null)
    - Calculate durationMinutes
    - Update same document
    """

    db = get_db()
    now = datetime.now(tz=IST)

    q = (
        db.collection("attendanceSessions")
        .where("teacherId", "==", teacherId)
        .where("checkOut", "==", None)
        .limit(1)
        .get()
    )

    if not q:
        return {
            "status": "NO_OPEN_SESSION"
        }

    doc = q[0]
    check_in = doc.get("checkIn")

    duration_minutes = int(
        (now - check_in).total_seconds() / 60
    )

    doc.reference.update({
        "checkOut": now,                 # Firestore Timestamp (IST)
        "durationMinutes": duration_minutes,
        "updatedAt": firestore.SERVER_TIMESTAMP,
    })

    teacherName = doc.get("teacherName") or teacherId

    # === High-priority notification ===
    send_notification_topic_sync(
        title=f"Teacher exited: {teacherName}",
        body=f"Duration: {duration_minutes} minutes",
    )

    return {
        "status": "CLOSED",
        "docId": doc.id,
    }


# =========================
# NOTIFICATIONS (HIGH PRIORITY)
# =========================

def send_notification_topic_sync(
    title: str,
    body: str,
    topic: str = "admins",
):
    """
    Sends a HIGH-PRIORITY, SOUND-ENABLED OS-level push notification.
    Works even when app is killed.
    """
    try:
        message = messaging.Message(
            topic=topic,

            notification=messaging.Notification(
                title=title,
                body=body,
            ),

            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id="admin_alerts",   # MUST match Android channel
                    sound="default",
                    default_sound=True,
                    visibility="public",
                ),
            ),

            data={
                "click_action": "FLUTTER_NOTIFICATION_CLICK",
            },
        )

        return messaging.send(message)

    except Exception as e:
        # Attendance must never fail due to notification
        print("FCM send failed (non-fatal):", e)
        return None
