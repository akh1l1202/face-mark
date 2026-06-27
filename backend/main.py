# main.py
from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import face_recognition
import numpy as np
import uvicorn
from typing import List
import io
import json
import os
import logging
import firebase_utils
import time
from fastapi.staticfiles import StaticFiles

BASE_URL = "http://192.168.0.113:8000"

# ---------------- LOGGING ----------------

logging.basicConfig(
    level=logging.INFO,
    format="\n%(asctime)s | %(levelname)s\n%(message)s\n",
)

def log_section(title: str, width: int = 60):
    line = "-" * width
    logging.info("%s\n%s\n%s", line, title, line)

# ----------------------------------------

try:
    firebase_utils.init_firebase()
except Exception as e:
    print("Warning: firebase init failed:", e)

app = FastAPI()

app.mount(
    "/profile_photos",
    StaticFiles(directory="profile_photos"),
    name="profile_photos"
)

logger = logging.getLogger("uvicorn.error")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

EMBEDDINGS_FILE = "embeddings.json"
teacher_db = {}

_last_no_face_log_time = 0.0
_NO_FACE_LOG_MIN_INTERVAL = 2.0


def load_embeddings():
    global teacher_db
    if os.path.exists(EMBEDDINGS_FILE):
        with open(EMBEDDINGS_FILE, "r") as f:
            teacher_db = json.load(f)
        log_section(f"EMBEDDINGS LOADED\nTeachers: {len(teacher_db)}")
    else:
        teacher_db = {}
        log_section("NO EMBEDDINGS FILE FOUND — STARTING FRESH")


def save_embeddings():
    with open(EMBEDDINGS_FILE, "w") as f:
        json.dump(teacher_db, f)
    logging.info("Embeddings saved to disk.")


def l2_normalize(vec: np.ndarray) -> np.ndarray:
    return vec / (np.linalg.norm(vec) + 1e-10)


def get_teacher_centroid(teacher_data: dict) -> np.ndarray:
    embs = [np.array(e) for e in teacher_data["embeddings"]]
    mean_vec = np.mean(embs, axis=0)
    return l2_normalize(mean_vec)


load_embeddings()


@app.get("/")
def root():
    log_section("ROOT HEALTH CHECK")
    return {"message": "Face backend up and running"}


@app.get("/attendance/open-session")
def has_open_session(teacherId: str):
    db = firebase_utils.get_db()

    q = (
        db.collection("attendanceSessions")
        .where("teacherId", "==", teacherId)
        .where("checkOut", "==", None)
        .limit(1)
        .get()
    )

    return {
        "hasOpenSession": len(q) > 0
    }


# ---------- TEACHER MGMT ----------

@app.get("/teachers")
def list_teachers():
    return {
        "status": "OK",
        "count": len(teacher_db),
        "teachers": [
            {
                "teacherId": tid,
                "name": d.get("name", ""),
                "phone": d.get("phone", ""),
                "profilePhoto": (
                    f"{BASE_URL}/profile_photos/{d['profile_photo']}"
                    if d.get("profile_photo") else ""
                ),
                "numEmbeddings": len(d.get("embeddings", [])),
            }
            for tid, d in teacher_db.items()
        ],
    }


@app.delete("/teacher/{teacherId}")
def delete_teacher(teacherId: str):
    if teacherId not in teacher_db:
        raise HTTPException(status_code=404, detail="Teacher not found in backend")

    log_section(f"DELETE TEACHER\nTeacherId={teacherId}")
    del teacher_db[teacherId]
    save_embeddings()

    return {"status": "OK", "deletedTeacherId": teacherId}


@app.delete("/teachers")
def delete_all_teachers():
    count = len(teacher_db)
    teacher_db.clear()
    save_embeddings()
    log_section(f"ALL TEACHERS DELETED\nCount={count}")
    return {"status": "OK", "deletedCount": count}


# ---------- REGISTER ----------

@app.post("/register")
async def register_teacher(
    teacherId: str = Form(...),
    name: str = Form(...),
    phone: str = Form(...),
    images: List[UploadFile] = File(...),
    profileIndex: int = Form(0),
):
    log_section(
        f"REGISTER TEACHER\n"
        f"TeacherId={teacherId}\n"
        f"Name={name}\n"
        f"Phone={phone}\n"
        f"ProfileIndex={profileIndex}"
    )

    try:
        from PIL import Image
    except Exception:
        logging.error("Pillow (PIL) missing.")
        raise HTTPException(status_code=500, detail="Server missing Pillow")

    try:
        import cv2
        _HAS_CV2 = True
    except Exception:
        cv2 = None
        _HAS_CV2 = False

    PROFILE_DIR = "profile_photos"
    os.makedirs(PROFILE_DIR, exist_ok=True)

    if teacherId not in teacher_db:
        teacher_db[teacherId] = {"name": name, "embeddings": [], "phone": phone, "profile_photo": None}
    else:
        teacher_db[teacherId]["name"] = name
        teacher_db[teacherId]["phone"] = phone

    num_added = 0
    best_score = -1.0
    best_profile_image_bytes = None
    best_face_location = None

    processed_image_bytes = []
    processed_face_locations = []

    for idx, img_file in enumerate(images):
        try:
            img_bytes = await img_file.read()
            processed_image_bytes.append(img_bytes)
            processed_face_locations.append(None)

            image = face_recognition.load_image_file(io.BytesIO(img_bytes))
            face_locations = face_recognition.face_locations(image)
            encodings = face_recognition.face_encodings(image, face_locations)

            if not encodings:
                logging.warning(
                    "\n--- IMAGE SKIPPED ---\n"
                    f"File   : {img_file.filename}\n"
                    "Reason : NO FACE DETECTED\n"
                    "----------------------"
                )
                continue

            encoding = l2_normalize(encodings[0])
            teacher_db[teacherId]["embeddings"].append(encoding.tolist())
            num_added += 1

            face_location = face_locations[0]
            processed_face_locations[-1] = face_location

            top, right, bottom, left = face_location
            face_width = max(1, right - left)
            face_height = max(1, bottom - top)
            face_area = face_width * face_height

            sharpness = 0.0
            try:
                if _HAS_CV2:
                    img_bgr = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)
                    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
                    sharpness = float(cv2.Laplacian(gray, cv2.CV_64F).var())
                else:
                    gray = np.mean(image, axis=2).astype("float32")
                    gy, gx = np.gradient(gray)
                    mag = np.sqrt(gx * gx + gy * gy)
                    sharpness = float(mag.var())
            except Exception as e:
                logging.debug(f"Sharpness calc failed for {img_file.filename}: {e}")

            score = face_area * (1.0 + sharpness / (1.0 + sharpness))

            if score > best_score:
                best_score = score
                best_profile_image_bytes = img_bytes
                best_face_location = face_location

        except Exception as e:
            logging.exception(f"Error processing image {img_file.filename}: {e}")

    if not teacher_db[teacherId]["embeddings"]:
        raise HTTPException(status_code=400, detail="No faces found in any image")

    try:
        if 0 <= profileIndex < len(processed_image_bytes):
            chosen_bytes = processed_image_bytes[profileIndex]
            chosen_face_loc = processed_face_locations[profileIndex]
            if chosen_face_loc is not None:
                best_profile_image_bytes = chosen_bytes
                best_face_location = chosen_face_loc
                logging.info(f"Using user-selected profileIndex={profileIndex}")
    except Exception as e:
        logging.debug(f"profileIndex override failed: {e}")

    save_embeddings()

    profile_photo_path = None
    try:
        if best_profile_image_bytes and best_face_location:
            pil_img = Image.open(io.BytesIO(best_profile_image_bytes)).convert("RGB")
            top, right, bottom, left = best_face_location

            face_cx = int((left + right) / 2)
            face_cy = int((top + bottom) / 2)
            face_w = int(right - left)
            face_h = int(bottom - top)
            half_side = max(int(max(face_w, face_h) * 0.9), 64)

            crop_left = max(0, face_cx - half_side)
            crop_top = max(0, face_cy - half_side)
            crop_right = min(pil_img.width, face_cx + half_side)
            crop_bottom = min(pil_img.height, face_cy + half_side)

            cropped = pil_img.crop((crop_left, crop_top, crop_right, crop_bottom))
            cropped = cropped.resize((256, 256), Image.LANCZOS)

            filename = f"{teacherId}_{int(time.time() * 1000)}.jpg"
            profile_photo_path = os.path.join(PROFILE_DIR, filename)
            cropped.save(profile_photo_path, "JPEG", quality=85)

            teacher_db[teacherId]["profile_photo"] = filename

            logging.info(
                "\n--- PROFILE PHOTO SAVED ---\n"
                f"TeacherId : {teacherId}\n"
                f"Path      : {profile_photo_path}\n"
                "--------------------------"
            )
    except Exception as e:
        logging.exception(f"Failed to save profile photo: {e}")

    log_section(
        f"REGISTRATION COMPLETE\n"
        f"TeacherId={teacherId}\n"
        f"TotalEmbeddings={len(teacher_db[teacherId]['embeddings'])}\n"
        f"AddedThisRequest={num_added}\n"
        f"ProfileSaved={bool(profile_photo_path)}"
    )

    profile_filename = teacher_db[teacherId].get("profile_photo")
    profile_url = (
        f"{BASE_URL}/profile_photos/{profile_filename}"
        if profile_filename else None
    )

    return {
        "status": "OK",
        "teacherId": teacherId,
        "name": name,
        "phone": phone,
        "numEmbeddings": len(teacher_db[teacherId]["embeddings"]),
        "addedThisRequest": num_added,
        "profilePhoto": profile_url,
    }


# ---------- IDENTIFY ----------

@app.post("/identify")
async def identify_teacher(image: UploadFile = File(...)):
    global _last_no_face_log_time

    log_section("IDENTIFY REQUEST")

    if not teacher_db:
        logging.warning("NO TEACHERS REGISTERED")
        return {"status": "NO_TEACHERS"}

    try:
        img_bytes = await image.read()
        image_arr = face_recognition.load_image_file(io.BytesIO(img_bytes))
        encodings = face_recognition.face_encodings(image_arr)

        if not encodings:
            now = time.time()
            if now - _last_no_face_log_time > _NO_FACE_LOG_MIN_INTERVAL:
                logging.info(
                    "\n--- IDENTIFY RESULT ---\n"
                    "Status : NO_FACE\n"
                    "----------------------"
                )
                _last_no_face_log_time = now
            return {"status": "NO_FACE"}

        query = l2_normalize(encodings[0])

        best_teacher = None
        best_distance = 999.0

        for teacher_id, data in teacher_db.items():
            if not data["embeddings"]:
                continue
            centroid = get_teacher_centroid(data)
            dist = np.linalg.norm(query - centroid)
            if dist < best_distance:
                best_distance = dist
                best_teacher = (teacher_id, data["name"])

        if best_teacher is None:
            logging.info("NO_MATCH: no teachers had embeddings.")
            return {"status": "NO_MATCH"}

        teacher_id, name = best_teacher

        logging.info(
            "\n--- MATCH EVALUATION ---\n"
            f"Candidate : {teacher_id}\n"
            f"Name      : {name}\n"
            f"Distance  : {best_distance:.4f}\n"
            "-----------------------"
        )

        HIGH_CONF_THRESH = 0.25
        MEDIUM_CONF_THRESH = 0.30
        REREGISTER_SUGGEST_THRESH = 0.40

        if best_distance > MEDIUM_CONF_THRESH:
            teacher_data = teacher_db.get(teacher_id, {})
            num_emb = len(teacher_data.get("embeddings", []))
            suggest_re_register = (
                (best_distance < REREGISTER_SUGGEST_THRESH) or (num_emb < 3)
            )

            logging.info(
                "\n====== NO MATCH ======\n"
                f"BestDistance : {best_distance:.4f}\n"
                f"Embeddings   : {num_emb}\n"
                f"SuggestReReg: {suggest_re_register}\n"
                "======================"
            )

            return {
                "status": "NO_MATCH",
                "bestDistance": float(best_distance),
                "candidateTeacherId": teacher_id,
                "candidateTeacherName": name,
                "suggestReRegister": suggest_re_register,
            }

        confidence_level = "HIGH" if best_distance <= HIGH_CONF_THRESH else "MEDIUM"

        MAX_EMB = 20
        if confidence_level == "HIGH":
            teacher_data = teacher_db[teacher_id]
            teacher_data["embeddings"].append(query.tolist())
            teacher_data["embeddings"] = teacher_data["embeddings"][-MAX_EMB:]
            save_embeddings()
            logging.info(
                "\n--- SELF LEARNING ---\n"
                f"TeacherId={teacher_id}\n"
                f"TotalEmbeddings={len(teacher_data['embeddings'])}\n"
                "--------------------"
            )

        logging.info(
            "\n***** MATCH CONFIRMED *****\n"
            f"TeacherId  : {teacher_id}\n"
            f"Name       : {name}\n"
            f"Distance   : {best_distance:.4f}\n"
            f"Confidence : {confidence_level}\n"
            "*************************"
        )

        return {
            "status": "OK",
            "teacherId": teacher_id,
            "name": name,
            "distance": float(best_distance),
            "confidenceLevel": confidence_level,
            "suggestReRegister": False,
        }

    except Exception as e:
        logging.exception("Error in identify endpoint")
        raise HTTPException(status_code=500, detail=str(e))



# ---------- IDENTIFY ----------

@app.post("/attendance/entry")
async def attendance_entry(
    teacherId: str = Form(...),
    teacherName: str = Form(...),
    mode: str = Form("FACE"),
):
    log_section(
        f"ATTENDANCE ENTRY\n"
        f"TeacherId={teacherId}\n"
        f"TeacherName={teacherName}\n"
        f"Mode={mode}"
    )

    try:
        result = firebase_utils.create_entry_session_sync(
            teacherId=teacherId,
            teacherName=teacherName,
            mode=mode,
        )

        # result already contains status + docId
        return result

    except Exception as e:
        logging.exception("Attendance entry failed")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/attendance/exit")
async def attendance_exit(
    teacherId: str = Form(...),
):
    log_section(
        f"ATTENDANCE EXIT\n"
        f"TeacherId={teacherId}"
    )

    try:
        result = firebase_utils.close_open_session_for_teacher_sync(
            teacherId=teacherId
        )

        return result

    except Exception as e:
        logging.exception("Attendance exit failed")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
