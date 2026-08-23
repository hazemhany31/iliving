#!/usr/bin/env python3
import json
import urllib.request
import urllib.error

PROJECT_ID = "iliving-app"
BASE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"
SEED_FILE = "assets/erp_seed_data.json"

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

def post_document(path, doc_data):
    url = f"{BASE_URL}/{path}"
    json_bytes = json.dumps(convert_doc(doc_data)).encode("utf-8")
    req = urllib.request.Request(url, data=json_bytes, headers={"Content-Type": "application/json"}, method="PATCH")
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status in (200, 201)
    except urllib.error.HTTPError as e:
        print(f"HTTPError writing {path}: {e.code} {e.reason}")
        return False
    except Exception as e:
        print(f"Error writing {path}: {e}")
        return False

def main():
    print(f"Loading {SEED_FILE}...")
    with open(SEED_FILE, "r", encoding="utf-8") as f:
        seed = json.load(f)

    print("Uploading to Firestore REST API...")

    # Projects
    for p in seed.get("projects", []):
        post_document(f"projects/{p['id']}", p)

    # Compounds
    for c in seed.get("compounds", []):
        post_document(f"compounds/{c['id']}", c)

    # Buildings
    for b in seed.get("buildings", []):
        post_document(f"compounds/{b['compoundId']}/buildings/{b['id']}", b)

    # Users
    for u in seed.get("users", []):
        post_document(f"users/{u['uid']}", u)

    # Units
    for un in seed.get("units", []):
        post_document(f"units/{un['id']}", un)

    # Contracts
    for ct in seed.get("contracts", []):
        post_document(f"contracts/{ct['id']}", ct)

    # Installments
    for inst in seed.get("installments", []):
        post_document(f"contracts/{inst['contractId']}/installments/{inst['id']}", inst)

    # Payments
    for pay in seed.get("payments", []):
        post_document(f"payments/{pay['id']}", pay)

    # Ledgers
    for led in seed.get("ledgers", []):
        post_document(f"ledgers/{led['unitId']}", led)

    # Documents
    for doc in seed.get("documents", []):
        post_document(f"documents/{doc['id']}", doc)

    print("Done uploading seed dataset!")

if __name__ == "__main__":
    main()
