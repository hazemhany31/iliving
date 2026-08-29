#!/usr/bin/env python3
import json
import hashlib
import base64
import subprocess
import urllib.request
import urllib.error
import os
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

PROJECT_ID = "iliving-app"
API_KEY = "AIzaSyCwJ5HxZs1fg_r33pmkKhraoXTmEojkbjI"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"
AUTH_SIGNIN_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
PASSWORD = "iliving2026"
EXCLUDED_CLIENT_CODES = {"93", "100", "107", "109", "113", "124", "150", "151", "154", "161", "167", "189", "197", "207"}

def convert_val(v):
    if v is None:
        return {"nullValue": None}
    elif isinstance(v, bool):
        return {"booleanValue": v}
    elif isinstance(v, int):
        return {"integerValue": str(v)}
    elif isinstance(v, float):
        return {"doubleValue": v}
    elif isinstance(v, str):
        return {"stringValue": v}
    elif isinstance(v, list):
        return {"arrayValue": {"values": [convert_val(item) for item in v]}}
    elif isinstance(v, dict):
        return {"mapValue": {"fields": {k: convert_val(val) for k, val in v.items()}}}
    return {"stringValue": str(v)}

def convert_doc(data_dict):
    fields = {}
    for k, v in data_dict.items():
        fields[k] = convert_val(v)
    return {"fields": fields}

def post_firestore_doc(path, doc_data, token=None):
    url = f"{BASE_URL}/{path}"
    json_bytes = json.dumps(convert_doc(doc_data)).encode("utf-8")
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=json_bytes, headers=headers, method="PATCH")
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            return resp.status in (200, 201)
    except urllib.error.HTTPError as e:
        print(f"HTTPError writing {path}: {e.code} {e.reason}")
        return False
    except Exception as e:
        print(f"Error writing {path}: {e}")
        return False

def make_uid(email, fallback):
    clean = email.replace("@", "_").replace(".", "_").replace("-", "_")
    return clean if clean else fallback

def get_admin_token():
    auth_data = json.dumps({
        "email": "admin@new-build-egypt.com",
        "password": "iliving2026",
        "returnSecureToken": True
    }).encode("utf-8")
    req = urllib.request.Request(AUTH_SIGNIN_URL, data=auth_data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        return res.get("idToken")

def main():
    print(f"=== Starting Account & Firestore Provisioning for {PROJECT_ID} ===")

    with open("accounts_credentials.json", "r", encoding="utf-8") as f:
        acc = json.load(f)
    with open("assets/erp_seed_data.json", "r", encoding="utf-8") as f:
        erp = json.load(f)

    users_by_email = {}

    # 1. Admin accounts
    users_by_email["admin@new-build-egypt.com"] = {
        "uid": "admin_new_build",
        "email": "admin@new-build-egypt.com",
        "fullName": "System Administrator",
        "phoneNumber": "+201000000000",
        "role": "SUPER_ADMIN",
        "clientCode": "client_admin",
        "associatedUnitIds": [],
        "mustChangePassword": True,
        "kycStatus": "verified",
        "accountStatus": "active",
        "createdAt": "2026-01-01T00:00:00.000Z"
    }
    users_by_email["admin@iliving.com.eg"] = {
        "uid": "admin_iliving_eg",
        "email": "admin@iliving.com.eg",
        "fullName": "System Administrator",
        "phoneNumber": "+201000000000",
        "role": "SUPER_ADMIN",
        "clientCode": "client_admin",
        "associatedUnitIds": [],
        "mustChangePassword": True,
        "kycStatus": "verified",
        "accountStatus": "active",
        "createdAt": "2026-01-01T00:00:00.000Z"
    }

    # 2. Broker account
    users_by_email["sterling@iliving.com.eg"] = {
        "uid": "broker_sterling",
        "email": "sterling@iliving.com.eg",
        "fullName": "Alistair Sterling",
        "phoneNumber": "+201111111111",
        "role": "BROKER",
        "clientCode": "client_broker",
        "associatedUnitIds": [],
        "mustChangePassword": True,
        "kycStatus": "verified",
        "accountStatus": "active",
        "createdAt": "2026-01-01T00:00:00.000Z"
    }

    # 3. Demo owner account
    users_by_email["demo@iliving.com.eg"] = {
        "uid": "client_demo",
        "email": "demo@iliving.com.eg",
        "fullName": "أحمد عبد العظيم صدقي",
        "phoneNumber": "01000197979",
        "role": "CUSTOMER",
        "clientCode": "147",
        "associatedUnitIds": ["B01B202"],
        "mustChangePassword": True,
        "kycStatus": "verified",
        "accountStatus": "active",
        "createdAt": "2026-01-01T00:00:00.000Z"
    }

    # 4. From erp_seed_data.json
    for u in erp.get("users", []):
        em = u.get("email", "").strip().lower()
        if em and em not in users_by_email:
            code = u.get("clientCode", u.get("uid", "").replace("client_", ""))
            users_by_email[em] = {
                "uid": u.get("uid", f"client_{code}"),
                "email": em,
                "fullName": u.get("fullName", "Resident"),
                "phoneNumber": u.get("phoneNumber", ""),
                "role": u.get("role", "CUSTOMER"),
                "clientCode": code,
                "associatedUnitIds": u.get("associatedUnitIds", []),
                "mustChangePassword": True,
                "kycStatus": u.get("kycStatus", "verified"),
                "accountStatus": u.get("accountStatus", "active"),
                "createdAt": u.get("createdAt", "2026-01-01T00:00:00.000Z")
            }

    # 5. From accounts_credentials.json
    for c in acc.get("clients", []):
        code = str(c.get("code", ""))
        if code in EXCLUDED_CLIENT_CODES:
            continue
        em = c.get("email", "").strip().lower()
        if em:
            uid = f"client_{code}"
            unit = c.get("unit")
            units = [unit] if unit else []
            if em in users_by_email:
                if not users_by_email[em].get("associatedUnitIds") and units:
                    users_by_email[em]["associatedUnitIds"] = units
            else:
                users_by_email[em] = {
                    "uid": uid,
                    "email": em,
                    "fullName": c.get("name", "Resident"),
                    "phoneNumber": c.get("phone", ""),
                    "role": "CUSTOMER",
                    "clientCode": code,
                    "associatedUnitIds": units,
                    "mustChangePassword": True,
                    "kycStatus": "verified",
                    "accountStatus": "active",
                    "createdAt": "2026-01-01T00:00:00.000Z"
                }

    print(f"Total unique accounts to provision: {len(users_by_email)}")

    # Ensure every single UID is strictly unique across accounts
    used_uids = set()
    for em, u in users_by_email.items():
        uid = u["uid"]
        if uid in used_uids:
            uid = make_uid(em, f"user_{len(used_uids)}")
            u["uid"] = uid
        used_uids.add(uid)

    # ── A. Prepare Firebase Auth Import ──────────────────────────────
    pass_hash = base64.b64encode(hashlib.sha256(PASSWORD.encode("utf-8")).digest()).decode("utf-8")

    auth_users = []
    for em, u in users_by_email.items():
        role = u["role"]
        custom_attrs = json.dumps({
            "role": role,
            "userRole": role,
            "mustChangePassword": True
        })
        auth_users.append({
            "localId": u["uid"],
            "email": em,
            "passwordHash": pass_hash,
            "displayName": u["fullName"],
            "customAttributes": custom_attrs
        })

    import_payload = {"users": auth_users}
    import_file = "bin/auth_users_import.json"
    os.makedirs("bin", exist_ok=True)
    with open(import_file, "w", encoding="utf-8") as f:
        json.dump(import_payload, f, indent=2)

    print(f"Importing {len(auth_users)} accounts into Firebase Auth via CLI...")
    cmd = [
        "firebase", "auth:import", import_file,
        "--hash-algo=SHA256",
        "--rounds=1",
        f"--project={PROJECT_ID}"
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    print("Firebase Auth Import Output:")
    print(res.stdout)
    if res.stderr:
        print("Firebase Auth Import Stderr:", res.stderr)

    time.sleep(1)
    print("Authenticating as Admin to obtain authorized token for Firestore provisioning...")
    admin_token = get_admin_token()
    print(f"Admin Token obtained: {admin_token[:25]}...")

    # ── B. Provision Firestore Documents in Parallel with Admin Token ─────────────────
    print("Writing all documents to Firestore REST API in parallel with Admin authorization...")
    tasks = []

    # 1. Users
    for em, u in users_by_email.items():
        tasks.append((f"users/{u['uid']}", u))

    # 2. ERP Entities
    for p in erp.get("projects", []):
        tasks.append((f"projects/{p['id']}", p))
    for c in erp.get("compounds", []):
        tasks.append((f"compounds/{c['id']}", c))
    for b in erp.get("buildings", []):
        tasks.append((f"compounds/{b['compoundId']}/buildings/{b['id']}", b))
    for un in erp.get("units", []):
        tasks.append((f"units/{un['id']}", un))
    for ct in erp.get("contracts", []):
        tasks.append((f"contracts/{ct['id']}", ct))
    for inst in erp.get("installments", []):
        tasks.append((f"contracts/{inst['contractId']}/installments/{inst['id']}", inst))
    for pay in erp.get("payments", []):
        tasks.append((f"payments/{pay['id']}", pay))
    for led in erp.get("ledgers", []):
        tasks.append((f"ledgers/{led['unitId']}", led))
    for doc in erp.get("documents", []):
        tasks.append((f"documents/{doc['id']}", doc))

    success = 0
    with ThreadPoolExecutor(max_workers=20) as executor:
        futures = {executor.submit(post_firestore_doc, path, data, admin_token): path for path, data in tasks}
        for f in as_completed(futures):
            if f.result():
                success += 1

    print(f"Successfully uploaded {success}/{len(tasks)} documents to Firestore.")
    print("=== Provisioning Completed Successfully! ===")

if __name__ == "__main__":
    main()
