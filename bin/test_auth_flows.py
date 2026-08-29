#!/usr/bin/env python3
import json
import urllib.request
import urllib.error
import base64
import sys

API_KEY = "AIzaSyCwJ5HxZs1fg_r33pmkKhraoXTmEojkbjI"
PROJECT_ID = "iliving-app"
AUTH_SIGNIN_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={API_KEY}"
AUTH_UPDATE_URL = f"https://identitytoolkit.googleapis.com/v1/accounts:update?key={API_KEY}"
FIRESTORE_URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents"

def sign_in(email, password):
    data = json.dumps({"email": email, "password": password, "returnSecureToken": True}).encode("utf-8")
    req = urllib.request.Request(AUTH_SIGNIN_URL, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))

def decode_token(id_token):
    payload_b64 = id_token.split(".")[1]
    # Add padding
    rem = len(payload_b64) % 4
    if rem > 0:
        payload_b64 += "=" * (4 - rem)
    return json.loads(base64.urlsafe_b64decode(payload_b64).decode("utf-8"))

def change_auth_password(id_token, new_password):
    data = json.dumps({"idToken": id_token, "password": new_password, "returnSecureToken": True}).encode("utf-8")
    req = urllib.request.Request(AUTH_UPDATE_URL, data=data, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))

def get_firestore_user(uid, id_token):
    url = f"{FIRESTORE_URL}/users/{uid}"
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {id_token}"})
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))

def update_must_change_password(uid, id_token, must_change):
    url = f"{FIRESTORE_URL}/users/{uid}?updateMask.fieldPaths=mustChangePassword"
    data = json.dumps({
        "fields": {
            "mustChangePassword": {"booleanValue": must_change}
        }
    }).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={"Authorization": f"Bearer {id_token}", "Content-Type": "application/json"}, method="PATCH")
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read().decode("utf-8"))

def test_account(role_name, email, uid, expected_role):
    print(f"\n========================================================")
    print(f"Testing Flow for: {role_name} ({email})")
    print(f"========================================================")

    # 1. First login with initial password iliving2026
    print(f"[Step 1] Attempting initial login with password 'iliving2026'...")
    res = sign_in(email, "iliving2026")
    id_token = res["idToken"]
    claims = decode_token(id_token)
    print(f"  ✓ Signed in successfully! UID: {res.get('localId')}")
    print(f"  ✓ Custom claims verified: role = '{claims.get('role')}', userRole = '{claims.get('userRole')}'")
    assert claims.get("role") == expected_role, f"Expected role {expected_role}, got {claims.get('role')}"

    # 2. Check Firestore profile mustChangePassword
    print(f"[Step 2] Fetching Firestore profile /users/{uid}...")
    user_doc = get_firestore_user(uid, id_token)
    fields = user_doc.get("fields", {})
    must_change = fields.get("mustChangePassword", {}).get("booleanValue")
    full_name = fields.get("fullName", {}).get("stringValue")
    print(f"  ✓ Firestore profile retrieved! Name: '{full_name}', mustChangePassword: {must_change}")
    assert must_change is True, f"mustChangePassword should be True for fresh account!"

    # 3. Simulate forced password change
    temp_pass = "iLivingSecurePass2026!"
    print(f"[Step 3] Performing mandatory password change to '{temp_pass}'...")
    change_res = change_auth_password(id_token, temp_pass)
    new_id_token = change_res["idToken"]
    print(f"  ✓ Password changed in Firebase Auth successfully!")

    # 4. Update Firestore mustChangePassword: false
    print(f"[Step 4] Updating Firestore mustChangePassword to False...")
    update_must_change_password(uid, new_id_token, False)
    updated_doc = get_firestore_user(uid, new_id_token)
    updated_mcp = updated_doc.get("fields", {}).get("mustChangePassword", {}).get("booleanValue")
    print(f"  ✓ Firestore mustChangePassword updated to: {updated_mcp}")
    assert updated_mcp is False, "mustChangePassword should now be False!"

    # 5. Subsequent login with new password
    print(f"[Step 5] Logging back in with new password '{temp_pass}'...")
    login2_res = sign_in(email, temp_pass)
    login2_token = login2_res["idToken"]
    login2_doc = get_firestore_user(uid, login2_token)
    login2_mcp = login2_doc.get("fields", {}).get("mustChangePassword", {}).get("booleanValue")
    print(f"  ✓ Successfully signed in with new password! mustChangePassword: {login2_mcp}")
    print(f"  ✓ User will go STRAIGHT to home screen (no forced change screen).")

    # 6. Reset password back to iliving2026 and mustChangePassword to True for clean state
    print(f"[Step 6] Resetting account back to standard state ('iliving2026' / mustChangePassword: True)...")
    change_auth_password(login2_token, "iliving2026")
    reset_login = sign_in(email, "iliving2026")
    update_must_change_password(uid, reset_login["idToken"], True)
    print(f"  ✓ Account cleanly reset to initial state for user testing.")
    print(f"✓ All tests for {role_name} PASSED successfully!")

def main():
    print("=== RUNNING LIVE E2E AUTHENTICATION & FORCED PASSWORD CHANGE TESTS ===")

    # 1. Admin Flow
    test_account("Super Admin", "admin@new-build-egypt.com", "admin_new_build", "SUPER_ADMIN")

    # 2. Broker Flow
    test_account("Broker", "sterling@iliving.com.eg", "broker_sterling", "BROKER")

    # 3. Client Flow (Client 87)
    test_account("Client (87)", "ahmed.shazly.abdelgawad@new-build-egypt.com", "client_87", "CUSTOMER")

    print("\n========================================================")
    print("🎉 ALL 3 ROLES (ADMIN, BROKER, CLIENT) PASSED E2E VERIFICATION!")
    print("========================================================")

if __name__ == "__main__":
    main()
