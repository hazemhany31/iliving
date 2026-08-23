#!/usr/bin/env python3
import os
import sys
import json
import re
import zipfile
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import List, Dict, Any, Optional

# Import parse_pdf and profile helpers from sync_pipeline
import fitz  # PyMuPDF
from sync_pipeline import (
    parse_pdf,
    ParsedLedger,
    EXISTING_AUTH_PROFILES,
    NEW_CLIENT_DEFAULTS,
    get_profile_for_code,
    get_english_name_for_sync,
    resolve_unit_id_for_auth,
    resolve_units_list_for_auth,
    get_unit_type,
    row_title,
    PAYMENT_TYPE_MAP,
)

PDF_DIR = "pdf al3omla"
XLSX_PATH = "pdf al3omla/Inventory update.xlsx"
OUTPUT_JSON = "assets/erp_seed_data.json"

def parse_xlsx_inventory(filename: str) -> Dict[str, Any]:
    if not os.path.exists(filename):
        print(f"Warning: {filename} not found.")
        return {}

    with zipfile.ZipFile(filename) as z:
        shared_strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            tree = ET.fromstring(z.read('xl/sharedStrings.xml'))
            for elem in tree.iter():
                if elem.tag.endswith('t'):
                    txt = ''.join(elem.itertext())
                    shared_strings.append(txt)

        wb = ET.fromstring(z.read('xl/workbook.xml'))
        sheets = []
        for child in wb.find('{http://schemas.openxmlformats.org/spreadsheetml/2006/main}sheets'):
            sheets.append((child.attrib['name'], child.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id']))

        rels = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
        rel_map = {child.attrib['Id']: child.attrib['Target'] for child in rels}

        ns = {'ns': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}

        all_sheets_data = {}
        for sname, rId in sheets:
            target = rel_map[rId]
            if not target.startswith('xl/'):
                target = 'xl/' + target
            if target not in z.namelist():
                continue
            sheet_tree = ET.fromstring(z.read(target))
            rows = []
            for row in sheet_tree.findall('.//ns:row', ns):
                row_cells = {}
                for cell in row.findall('./ns:c', ns):
                    ref = cell.attrib.get('r')
                    col = ''.join([c for c in ref if c.isalpha()])
                    cell_type = cell.attrib.get('t')
                    val_elem = cell.find('./ns:v', ns)
                    v = val_elem.text if val_elem is not None else ''
                    if cell_type == 's' and v.isdigit() and int(v) < len(shared_strings):
                        v = shared_strings[int(v)]
                    elif cell_type == 'inlineStr':
                        is_elem = cell.find('./ns:is', ns)
                        if is_elem is not None:
                            v = ''.join(is_elem.itertext())
                    row_cells[col] = v
                if row_cells:
                    rows.append(row_cells)
            all_sheets_data[sname] = rows
        return all_sheets_data

def format_iso_date(d_str: str, default_str: str = "2024-05-20T09:00:00.000Z") -> str:
    if not d_str:
        return default_str
    d_str = d_str.strip().replace('/', '-')
    m = re.match(r"^(\d{4})-(\d{1,2})-(\d{1,2})", d_str)
    if m:
        y, mo, d = m.group(1), m.group(2).zfill(2), m.group(3).zfill(2)
        return f"{y}-{mo}-{d}T09:00:00.000Z"
    return default_str

def main():
    print("Starting ERP & Inventory Parsing...")
    
    # 1. Parse all 54 PDFs
    pdf_files = [f for f in os.listdir(PDF_DIR) if f.endswith(".pdf")]
    pdf_files.sort(key=lambda x: int(re.sub(r"\D", "", x)) if re.sub(r"\D", "", x) else 0)

    ledgers: List[ParsedLedger] = []
    for pdf_f in pdf_files:
        path = os.path.join(PDF_DIR, pdf_f)
        parsed = parse_pdf(path)
        if parsed:
            ledgers.append(parsed)

    print(f"Parsed {len(ledgers)} customer statement PDFs successfully.")

    # Collect all client codes
    all_codes = list(set([l.client_code for l in ledgers]))
    all_codes.sort(key=lambda x: int(x) if x.isdigit() else x)

    # 2. Parse Excel Inventory
    xlsx_data = parse_xlsx_inventory(XLSX_PATH)
    print(f"Parsed Excel Inventory with sheets: {list(xlsx_data.keys())}")

    # Build Project
    project = {
        "id": "skyhills",
        "developerId": "dev_skyhills",
        "code": "SKYHILLS",
        "name": "Sky Hills",
        "nameAr": "سكي هيلز",
        "description": "Premium elevated architecture in New October City featuring floor-to-ceiling glass, high-altitude unit allocations, and panoramic skyline views.",
        "city": "Greater Cairo",
        "district": "New October City",
        "totalCompounds": 1,
        "totalUnits": 0, # Will compute below
        "status": "ACTIVE",
        "createdAt": "2026-01-01T00:00:00.000Z",
        "updatedAt": "2026-08-02T10:00:00.000Z"
    }

    # Build Compound
    compound = {
        "id": "dev_1",
        "title": "Sky Hills (سكي هيلز)",
        "location": "New October City, Greater Cairo",
        "category": "Residential",
        "description": "Premium elevated architecture in New October City featuring floor-to-ceiling glass, high-altitude unit allocations, and panoramic skyline views.",
        "basePriceEGP": 45000000.0,
        "areaSqFt": 1800.0,
        "completionPercentage": 45.0,
        "heroImageUrl": "images/skyhills/ski-hills-overview.jpg",
        "cardImageUrl": "images/skyhills/ski-hills.jpg",
        "primaryView": "New October City Skyline",
        "droneVideoUrl": None,
        "walkthrough3DUrl": None,
        "galleryPhotos": [
            {"title": "Overview", "url": "images/skyhills/ski-hills-overview.jpg"},
            {"title": "Sky Hills Main", "url": "images/skyhills/ski-hills.jpg"},
            {"title": "Pricing View", "url": "images/skyhills/ski-hills-pricing.jpg"},
            {"title": "Services View", "url": "images/skyhills/ski-hills-services.jpg"},
            {"title": "Units View", "url": "images/skyhills/ski-hills-units.jpg"}
        ],
        "droneClips": [
            {"title": "Overview WebP", "url": "images/skyhills/ski-hills-overview.webp"},
            {"title": "Main WebP", "url": "images/skyhills/ski-hills.webp"}
        ],
        "walkthroughs": [
            {"title": "3D Tour", "room": "Master Suite", "url": "https://my.matterport.com/show/?m=skyhills"}
        ],
        "brochures": [
            {"title": "Master Brochure", "url": "pdf al3omla/1.pdf"}
        ]
    }

    # Build Buildings & Units
    buildings_map: Dict[str, Dict[str, Any]] = {}
    units_list: List[Dict[str, Any]] = []
    users_map: Dict[str, Dict[str, Any]] = {}
    contracts_list: List[Dict[str, Any]] = []
    installments_list: List[Dict[str, Any]] = []
    payments_list: List[Dict[str, Any]] = []
    ledgers_list: List[Dict[str, Any]] = []
    documents_list: List[Dict[str, Any]] = []

    # Map unitId -> owner user id & pdf ledger
    unit_to_ledger: Dict[str, ParsedLedger] = {}
    for led in ledgers:
        code = led.client_code
        unit_id = led.unit_id
        if code in EXISTING_AUTH_PROFILES:
            unit_id = EXISTING_AUTH_PROFILES[code].get("unit", unit_id)
        elif code in NEW_CLIENT_DEFAULTS:
            unit_id = NEW_CLIENT_DEFAULTS[code].get("unit", unit_id)
        unit_to_ledger[unit_id] = led

    # Seed Admin User
    admin_user = {
        "uid": "admin_master",
        "email": "admin@iliving.com",
        "phoneNumber": "+201000000000",
        "fullName": "System Administrator",
        "nationalIdOrPassport": "00000000000000",
        "nationality": "Egyptian",
        "clientCode": "ADMIN",
        "role": "SUPER_ADMIN",
        "kycStatus": "verified",
        "associatedUnitIds": [],
        "fcmTokens": [],
        "preferredLanguage": "ar",
        "accountStatus": "active",
        "createdAt": "2026-01-01T00:00:00.000Z",
        "lastLoginAt": "2026-08-02T10:00:00.000Z"
    }
    users_map[admin_user["uid"]] = admin_user

    # Seed 54 Users from PDF Client Statements
    existing_emails = set()
    code_to_uid: Dict[str, str] = {}
    
    for code in all_codes:
        profile = get_profile_for_code(code)
        name = profile["name"]
        phone = profile["phone"]
        primary_unit = resolve_unit_id_for_auth(code, ledgers)
        units_owned = resolve_units_list_for_auth(code, ledgers) or [primary_unit]
        
        email_prefix = get_english_name_for_sync(name)
        email = f"{email_prefix}@new-build-egypt.com"
        if email in existing_emails:
            email = f"{email_prefix}.{code}@new-build-egypt.com"
        existing_emails.add(email)

        uid = f"client_{code}"
        code_to_uid[code] = uid

        user_profile = {
            "uid": uid,
            "email": email,
            "phoneNumber": phone,
            "fullName": name,
            "nationalIdOrPassport": f"2950101{code.zfill(7)}",
            "nationality": "Egyptian",
            "clientCode": code,
            "role": "CUSTOMER",
            "kycStatus": "verified",
            "associatedUnitIds": units_owned,
            "fcmTokens": [],
            "preferredLanguage": "ar",
            "accountStatus": "active",
            "createdAt": "2024-01-01T00:00:00.000Z",
            "lastLoginAt": "2026-08-02T09:00:00.000Z"
        }
        users_map[uid] = user_profile

    # Process PDF Ledgers to generate Units, Contracts, Installments, Payments, UnitLedgers, Documents
    processed_unit_ids = set()

    for led in ledgers:
        code = led.client_code
        unit_id = led.unit_id
        if code in EXISTING_AUTH_PROFILES:
            unit_id = EXISTING_AUTH_PROFILES[code].get("unit", unit_id)
        elif code in NEW_CLIENT_DEFAULTS:
            unit_id = NEW_CLIENT_DEFAULTS[code].get("unit", unit_id)

        processed_unit_ids.add(unit_id)
        owner_uid = code_to_uid.get(code, f"client_{code}")

        # Determine Building ID from unit_id
        # Examples: B01B202 -> B202, A301B404 -> B404, A01-207 -> B207
        bld_code = "B202"
        for b_candidate in ["B202", "B203", "B208", "B310", "B404", "B409", "207"]:
            if b_candidate in unit_id:
                bld_code = f"B{b_candidate}" if not b_candidate.startswith("B") else b_candidate
                break
        
        if bld_code not in buildings_map:
            buildings_map[bld_code] = {
                "id": bld_code,
                "compoundId": "dev_1",
                "code": bld_code,
                "name": f"Building {bld_code}",
                "nameAr": f"مبنى {bld_code}",
                "totalFloors": 5,
                "totalUnits": 0,
                "amenities": ["Elevator", "Security", "Underground Parking", "Smart Access"],
                "createdAt": "2024-01-01T00:00:00.000Z",
                "updatedAt": "2026-08-02T10:00:00.000Z"
            }
        buildings_map[bld_code]["totalUnits"] += 1

        unit_type = get_unit_type(unit_id, led.area_sqm)
        area_sqm = led.area_sqm if led.area_sqm > 0 else 150.0
        area_sqft = area_sqm * 10.7639
        price_egp = led.total_price if led.total_price > 0 else 4500000.0
        price_per_sqft = price_egp / area_sqft if area_sqft > 0 else 2500.0

        floor_tier = "Ground Floor"
        if "5" in unit_id[:3]:
            floor_tier = "Fifth Floor"
        elif "4" in unit_id[:3]:
            floor_tier = "Fourth Floor"
        elif "3" in unit_id[:3]:
            floor_tier = "Third Floor"
        elif "2" in unit_id[:3]:
            floor_tier = "Second Floor"
        elif "1" in unit_id[:3]:
            floor_tier = "First Floor"

        unit_model = {
            "id": unit_id,
            "unitNumber": unit_id,
            "configuration": "2 Bedroom Suite",
            "areaSqFt": area_sqft,
            "priceEGP": price_egp,
            "isVacant": False,
            "assetClass": "Residential Suite",
            "furnishingStatus": "Semi-Finished",
            "pricePerSqFt": price_per_sqft,
            "parkingSpaces": 1,
            "constructionPhase": "Superstructure",
            "parentCompoundId": "dev_1",
            "compoundId": "dev_1",
            "paymentMilestones": [
                {"title": "Contract Downpayment", "percentageDue": 10.0, "isPaid": True},
                {"title": "Structure Completion", "percentageDue": 40.0, "isPaid": True},
                {"title": "Final Delivery", "percentageDue": 50.0, "isPaid": False}
            ],
            "floorTier": floor_tier,
            "areaSquareMeters": area_sqm,
            "gardenArea": 35.0 if "B01" in unit_id or "A01" in unit_id else None,
            "orientation": "Landscape",
            "block": "Block A" if "A" in unit_id else "Block B",
            "status": "CONTRACTED",
            "currentOwnerId": owner_uid,
            "buildingId": bld_code
        }
        units_list.append(unit_model)

        # Build Contract
        contract_id = f"CNT-{code}"
        contract_date_iso = format_iso_date(led.contract_date)
        dp_row = next((r for r in led.rows if r.payment_type == "Downpayment"), None)
        maint_row = next((r for r in led.rows if r.payment_type == "Maintenance Deposit"), None)
        
        dp_amount = dp_row.amount if dp_row else (price_egp * 0.1)
        maint_amount = maint_row.amount if maint_row else 0.0

        contract_model = {
            "id": contract_id,
            "contractNumber": led.contract_num if led.contract_num else f"CNT-{code}",
            "unitId": unit_id,
            "compoundId": "dev_1",
            "buyerUserId": owner_uid,
            "salesAgentUserId": "admin_master",
            "agreedTotalPrice": price_egp,
            "downPaymentAmount": dp_amount,
            "maintenanceDepositAmount": maint_amount,
            "handoverPaymentAmount": 0.0,
            "clientCode": code,
            "installmentDurationYears": 4,
            "totalInstallmentsCount": len(led.rows),
            "startDate": contract_date_iso,
            "endDate": "2028-12-31T00:00:00.000Z",
            "deliveryDateExpected": "2027-06-30T00:00:00.000Z",
            "pdfContractUrl": f"pdf al3omla/{os.path.basename(led.pdf_file)}",
            "signatureStatus": "fullyExecuted",
            "signedByCustomerAt": contract_date_iso,
            "signedByDeveloperAt": contract_date_iso,
            "createdAt": contract_date_iso,
            "updatedAt": "2026-08-02T10:00:00.000Z"
        }
        contracts_list.append(contract_model)

        # Build Document
        doc_model = {
            "id": f"DOC-{code}",
            "title": f"ERP Statement - Client {code} ({unit_id})",
            "description": f"Official TAB ERP Customer Statement PDF for Client {code}",
            "category": "contract",
            "fileUrl": f"pdf al3omla/{os.path.basename(led.pdf_file)}",
            "fileExtension": "pdf",
            "fileSizeBytes": os.path.getsize(led.pdf_file) if os.path.exists(led.pdf_file) else 95000,
            "ownerUserId": owner_uid,
            "associatedUnitId": unit_id,
            "createdAt": contract_date_iso
        }
        documents_list.append(doc_model)

        # Build Installments and Payments
        inst_records_for_ledger = []
        inst_counter = 0

        for r in led.rows:
            inst_counter += 1
            inst_id = f"INST-{contract_id}-{r.row_num}"
            due_date_iso = format_iso_date(r.due_date)
            paid_date_iso = format_iso_date(r.paid_date) if r.paid_date else None

            # Installment Type mapping
            itype = "regularQuarterly"
            if r.payment_type == "Downpayment":
                itype = "downPayment"
            elif r.payment_type == "Semi-Annual":
                itype = "semiAnnual"
            elif r.payment_type == "Annual":
                itype = "annual"
            elif r.payment_type == "Maintenance Deposit":
                itype = "maintenanceFund"
            elif r.payment_type == "Final Delivery":
                itype = "deliveryPayment"

            # Status
            status_str = "PAID" if r.is_paid else "UNPAID"

            installment_model = {
                "id": inst_id,
                "contractId": contract_id,
                "unitId": unit_id,
                "buyerUserId": owner_uid,
                "sequenceNumber": r.row_num,
                "installmentType": itype,
                "dueDate": due_date_iso,
                "gracePeriodEndDate": due_date_iso,
                "principalAmount": r.amount,
                "penaltyFeeAmount": 0.0,
                "paidAmount": r.paid_amount,
                "remainingAmount": r.remaining,
                "currency": "EGP",
                "status": status_str,
                "paidAt": paid_date_iso,
                "paymentMethodLastUsed": "bankWire" if r.is_paid else None,
                "receiptNumber": r.receipt_num
            }
            installments_list.append(installment_model)

            # Record for UnitLedger
            inst_title = row_title(r.payment_type, r.row_num, inst_counter)
            inst_records_for_ledger.append({
                "id": inst_id,
                "title": inst_title,
                "isPaid": r.is_paid,
                "amountEGP": r.amount,
                "dueDateIso": due_date_iso[:10],
                "dueDateLabel": due_date_iso[:10],
                "paidTimestamp": paid_date_iso,
                "receiptUrl": f"pdf al3omla/{os.path.basename(led.pdf_file)}" if r.is_paid else None,
                "milestoneTag": "Contracting" if r.payment_type == "Downpayment" else "Scheduled"
            })

            # Payment log if paid
            if r.is_paid and r.paid_amount > 0:
                payment_id = f"PAY-{contract_id}-{r.row_num}"
                payment_model = {
                    "id": payment_id,
                    "transactionReference": r.receipt_num if r.receipt_num else f"REC-{code}-{r.row_num}",
                    "contractId": contract_id,
                    "installmentId": inst_id,
                    "unitId": unit_id,
                    "payerUserId": owner_uid,
                    "paymentMethod": "bankWire",
                    "amountPaid": r.paid_amount,
                    "currency": "EGP",
                    "gatewayFee": 0.0,
                    "receiptPdfUrl": f"pdf al3omla/{os.path.basename(led.pdf_file)}",
                    "verifiedByUserId": "admin_master",
                    "status": "success",
                    "createdAt": paid_date_iso or contract_date_iso
                }
                payments_list.append(payment_model)

        # Build UnitLedger
        dp_is_paid = dp_row.is_paid if dp_row else False
        maint_is_paid = maint_row.is_paid if maint_row else False
        maint_balance = maint_row.amount if maint_row else 0.0

        unit_ledger = {
            "compoundId": "dev_1",
            "clientId": f"client_{code}",
            "unitId": unit_id,
            "unitType": unit_type,
            "downPayment": {
                "isPaid": dp_is_paid,
                "status": "PAID" if dp_is_paid else "PENDING",
                "percentageDue": 10.0,
                "amountEGP": dp_amount,
                "paidTimestamp": format_iso_date(dp_row.paid_date) if (dp_row and dp_row.paid_date) else None,
                "receiptUrl": f"pdf al3omla/{os.path.basename(led.pdf_file)}" if dp_is_paid else None,
                "transactionRef": dp_row.receipt_num if dp_row else None
            },
            "installments": inst_records_for_ledger,
            "maintenance": {
                "isPaid": maint_is_paid,
                "status": "Escrow Secured" if maint_is_paid else "Escrow Outstanding",
                "balanceEGP": maint_balance,
                "annualFeeEGP": maint_balance,
                "lastPaidTimestamp": format_iso_date(maint_row.paid_date) if (maint_row and maint_row.paid_date) else None,
                "nextDueDateIso": "2027-01-01",
                "escrowAccountRef": "ESCROW-SKYHILLS-001"
            },
            "floorTier": floor_tier,
            "areaSquareMeters": area_sqm
        }
        ledgers_list.append(unit_ledger)

    # 3. Add Uncontracted Units from Excel Inventory if any
    for sheet_name, rows in xlsx_data.items():
        if sheet_name not in ["201", "202", "207", "208", "306"]:
            continue
        bld_code = f"B{sheet_name}"
        if bld_code not in buildings_map:
            buildings_map[bld_code] = {
                "id": bld_code,
                "compoundId": "dev_1",
                "code": bld_code,
                "name": f"Building {bld_code}",
                "nameAr": f"مبنى {bld_code}",
                "totalFloors": 5,
                "totalUnits": 0,
                "amenities": ["Elevator", "Security", "Underground Parking"],
                "createdAt": "2024-01-01T00:00:00.000Z",
                "updatedAt": "2026-08-02T10:00:00.000Z"
            }
        
        for r_dict in rows:
            unit_num_raw = r_dict.get("E", r_dict.get("F", r_dict.get("D", "")))
            if not unit_num_raw or "INVENTORY" in unit_num_raw or "اسم" in unit_num_raw or "رقم" in unit_num_raw:
                continue
            
            clean_unit_num = unit_num_raw.replace(" ", "").upper()
            unit_id = f"{clean_unit_num}{bld_code}" if not clean_unit_num.endswith(bld_code) else clean_unit_num
            
            if unit_id not in processed_unit_ids:
                processed_unit_ids.add(unit_id)
                buildings_map[bld_code]["totalUnits"] += 1

                area_raw = r_dict.get("B", r_dict.get("C", "90 m"))
                area_m = re.search(r"(\d+)", area_raw)
                area_sqm = float(area_m.group(1)) if area_m else 90.0
                area_sqft = area_sqm * 10.7639
                price_egp = area_sqm * 45000.0

                uncontracted_unit = {
                    "id": unit_id,
                    "unitNumber": unit_id,
                    "configuration": "2 Bedroom Suite",
                    "areaSqFt": area_sqft,
                    "priceEGP": price_egp,
                    "isVacant": True,
                    "assetClass": "Residential Suite",
                    "furnishingStatus": "Semi-Finished",
                    "pricePerSqFt": 4500.0,
                    "parkingSpaces": 1,
                    "constructionPhase": "Superstructure",
                    "parentCompoundId": "dev_1",
                    "compoundId": "dev_1",
                    "paymentMilestones": [],
                    "floorTier": "Ground Floor",
                    "areaSquareMeters": area_sqm,
                    "gardenArea": None,
                    "orientation": "Landscape",
                    "block": "Block A",
                    "status": "AVAILABLE",
                    "currentOwnerId": None,
                    "buildingId": bld_code
                }
                units_list.append(uncontracted_unit)

    # Update project totalUnits
    project["totalUnits"] = len(units_list)

    # Compile final JSON structure
    seed_data = {
        "projects": [project],
        "compounds": [compound],
        "buildings": list(buildings_map.values()),
        "units": units_list,
        "users": list(users_map.values()),
        "contracts": contracts_list,
        "installments": installments_list,
        "payments": payments_list,
        "ledgers": ledgers_list,
        "documents": documents_list
    }

    os.makedirs(os.path.dirname(OUTPUT_JSON), exist_ok=True)
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(seed_data, f, ensure_ascii=False, indent=2)

    print(f"SUCCESS: Generated {OUTPUT_JSON} with:")
    print(f"  - Projects: {len(seed_data['projects'])}")
    print(f"  - Compounds: {len(seed_data['compounds'])}")
    print(f"  - Buildings: {len(seed_data['buildings'])}")
    print(f"  - Units: {len(seed_data['units'])}")
    print(f"  - Users: {len(seed_data['users'])}")
    print(f"  - Contracts: {len(seed_data['contracts'])}")
    print(f"  - Installments: {len(seed_data['installments'])}")
    print(f"  - Payments: {len(seed_data['payments'])}")
    print(f"  - Ledgers: {len(seed_data['ledgers'])}")
    print(f"  - Documents: {len(seed_data['documents'])}")

if __name__ == "__main__":
    main()
