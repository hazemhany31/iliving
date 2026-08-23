#!/usr/bin/env python3
import fitz
import re
import os
import sys
from dataclasses import dataclass, field
from typing import List, Optional, Tuple

PDF_DIR = "pdf al3omla"
AUTH_OUT = "lib/services/auth_mock_data.dart"
OPS_OUT = "lib/repositories/operations_mock_data.dart"

EXISTING_AUTH_PROFILES = {
    "147": {"name": "أحمد عبد العظيم صدقي", "phone": "01000197979", "unit": "B01B202"},
    "180": {"name": "سامح إبراهيم يوسف رمضان", "phone": "01000995004", "unit": "A103B202"},
    "183": {"name": "ياسمين عبد الوهاب محمود", "phone": "31642789908", "unit": "B101B202"},
    "98":  {"name": "عبد الله إبراهيم إبراهيم", "phone": "01011101209", "unit": "A01B202"},
    "102": {"name": "عوض الله رشيد أحمد", "phone": "01156695555", "unit": "B401B202"},
    "116": {"name": "خالد محمد محمد علي", "phone": "01000364262", "unit": "A301B202"},
    "121": {"name": "سامح عبد الصمد البنا", "phone": "01098733072", "unit": "B302B202"},
    "122": {"name": "أمير عبد الصمد البنا", "phone": "01060294554", "unit": "B202B202"},
    "123": {"name": "حنفي أحمد بدوي", "phone": "01060290080", "unit": "A203B202"},
    "127": {"name": "محمد شعبان محمد", "phone": "01002710135", "unit": "B201B202"},
    "176": {"name": "أحمد سيد علي", "phone": "01285696491", "unit": "B501B409"},
    "144": {"name": "إبراهيم احمد عبد الله", "phone": "00966656943790", "unit": "A301B404", "units": ["A301B404", "C303B404", "C302B404"]},
    "87":  {"name": "أحمد شاذلي عبد الجواد", "phone": "01127633326", "unit": "A301B208"},
    "185": {"name": "أحمد سيد إبراهيم", "phone": "010118999890", "unit": "A01B203"},
    "94":  {"name": "احمد حسين محمد", "phone": "01003635780", "unit": "A01B208"},
    "130": {"name": "احمد جلال عبد العزيز", "phone": "01009090425", "unit": "A01-207"},
    "152": {"name": "احمد بسيوني عطيه", "phone": "01099990363", "unit": "A103B208"},
    "134": {"name": "سمير غانم إبراهيم", "phone": "01011572317", "unit": "B104B203"},
    "142": {"name": "احمد عبد الخالق عوف", "phone": "01012342359", "unit": "C301B409"},
    "200": {"name": "اسامه ipad علي", "phone": "01025666033", "unit": "A502B310"},
    "146": {"name": "السيد عبد الله عبد الحميد", "phone": "01010791172", "unit": "C203B404", "units": ["C203B404", "C202B404"]},
    "182": {"name": "امير فضل المولى", "phone": "00966500593093", "unit": "A101B409"},
    "91":  {"name": "بسيوني إبراهيم بسيوني أبو الغيط", "phone": "01026673378", "unit": "B102B409"},
    "198": {"name": "مصطفى محمد حسام الدين", "phone": "01152526666", "unit": "C201B409"},
    "111": {"name": "حسن محمد حسن", "phone": "01000055047", "unit": "B403B208"},
    "155": {"name": "محمد علي زيدان", "phone": "00966597115149", "unit": "A201B409"},
    "203": {"name": "محمد احمد شهاب", "phone": "01005471111", "unit": "B302B208"},
    "145": {"name": "محمد احمد عبدالله", "phone": "01060815450", "unit": "A201B404"},
    "137": {"name": "محمد احمد محمد مكي", "phone": "01026443490", "unit": "C303B409"},
    "165": {"name": "محمد سعيد عبد العليم", "phone": "01060815450", "unit": "A01B409"},
    "187": {"name": "محمد محسن محمد", "phone": "01012400812", "unit": "C103B409"},
    "114": {"name": "محمد موسى علي عطيه", "phone": "01224899336", "unit": "B303B208"},
    "89":  {"name": "محمود غانم إبراهيم", "phone": "032465795140", "unit": "B101B409"},
    "125": {"name": "مروة حسن محمد", "phone": "01027773311", "unit": "B402B409"},
    "90":  {"name": "marrow علي محمد", "phone": "01008102068", "unit": "C102B409"},
    "105": {"name": "دولت محمد السيد", "phone": "01144456446", "unit": "B02B409"},
    "205": {"name": "رمضان صلاح رمضان", "phone": "01092150776", "unit": "B01B409"},
    "173": {"name": "طلعت محمد عادل", "phone": "01288133533", "unit": "C401B409"},
    "139": {"name": "احمد اشرف عبيد", "phone": "01010101140", "unit": "B01-207"},
    "179": {"name": "سحر محمود إبراهيم", "phone": "01009730394", "unit": "A401B409", "units": ["A401B409", "B401B208"]},
    "95":  {"name": "محاسن محمد حسن", "phone": "01005788266", "unit": "C203B409", "units": ["C203B409", "C202B409"]},
}

NEW_CLIENT_DEFAULTS = {
    "93":  {"name": "Fictional Client 93",  "phone": "01000000093", "unit": "UNIT93"},
    "100": {"name": "Fictional Client 100", "phone": "01000000100", "unit": "UNIT100"},
    "107": {"name": "Fictional Client 107", "phone": "01000000107", "unit": "UNIT107"},
    "109": {"name": "Fictional Client 109", "phone": "01000000109", "unit": "UNIT109"},
    "113": {"name": "Fictional Client 113", "phone": "01000000113", "unit": "UNIT113"},
    "124": {"name": "Fictional Client 124", "phone": "01000000124", "unit": "UNIT124"},
    "150": {"name": "Fictional Client 150", "phone": "01000000150", "unit": "UNIT150"},
    "151": {"name": "Fictional Client 151", "phone": "01000000151", "unit": "UNIT151"},
    "154": {"name": "Fictional Client 154", "phone": "01000000154", "unit": "UNIT154"},
    "161": {"name": "Fictional Client 161", "phone": "01000000161", "unit": "UNIT161"},
    "167": {"name": "Fictional Client 167", "phone": "01000000167", "unit": "UNIT167"},
    "189": {"name": "Fictional Client 189", "phone": "01000000189", "unit": "UNIT189"},
    "197": {"name": "Fictional Client 197", "phone": "01000000197", "unit": "UNIT197"},
    "207": {"name": "Fictional Client 207", "phone": "01000000207", "unit": "UNIT207"},
}

PAYMENT_TYPE_MAP = {
    "مقدم تعاقد": "Downpayment",
    "ربع سنوية": "Quarterly",
    "نصف سنوية": "Semi-Annual",
    "وديعة صيانة": "Maintenance Deposit",
    "عداد": "Utility Meter",
    "دفعة استلم نهائى": "Final Delivery",
    "دفعة استلم": "Final Delivery",
    "سنوية": "Annual",
    "شهري": "Monthly",
}


@dataclass
class PaymentRow:
    row_num: int
    amount: float
    due_date: str
    paid_amount: float
    paid_date: Optional[str]
    payment_type: str
    payment_type_ar: str
    receipt_num: Optional[str]
    remaining: float
    is_paid: bool


@dataclass
class ParsedLedger:
    pdf_file: str
    client_code: str
    unit_raw: str
    unit_id: str
    compound: str
    area_sqm: float
    floor_raw: str
    contract_date: str
    contract_num: str
    total_price: float
    erp_total_paid: float
    erp_total_remaining: float
    true_total_paid: float
    true_total_remaining: float
    rows: List[PaymentRow] = field(default_factory=list)


def parse_number(s: str) -> float:
    s = s.strip().replace(",", "").replace(" ", "")
    if not s or s == "0":
        return 0.0
    try:
        return float(s)
    except ValueError:
        return 0.0


def normalize_unit_id(raw: str, compound_suffix: str) -> str:
    raw = raw.strip()
    cleaned = raw.replace(" ", "")
    if cleaned.startswith("B404") or cleaned.startswith("B202") or cleaned.startswith("B203") or cleaned.startswith("B208") or cleaned.startswith("B310"):
        pass
    if compound_suffix == "207":
        return cleaned
    if compound_suffix:
        return cleaned + compound_suffix if not cleaned.endswith(compound_suffix) else cleaned
    return cleaned


def extract_floor_area(line13: str) -> Tuple[float, str]:
    m = re.match(r"([\d,]+(?:\.\d+)?)(.*)", line13.strip())
    if m:
        area = parse_number(m.group(1))
        floor_info = m.group(2).strip()
        return area, floor_info
    return 0.0, line13.strip()


def parse_date_iso(d: str) -> str:
    d = d.strip()
    m = re.match(r"(\d{4})/(\d{1,2})/(\d{1,2})", d)
    if m:
        y, mo, day = m.group(1), m.group(2).zfill(2), m.group(3).zfill(2)
        return f"{y}-{mo}-{day}"
    return d


def detect_payment_type(text: str) -> Tuple[str, str]:
    for ar, en in PAYMENT_TYPE_MAP.items():
        if ar in text:
            return ar, en
    return "", "Installment"


def parse_pdf(filepath: str) -> Optional[ParsedLedger]:
    doc = fitz.open(filepath)
    full_text = ""
    for page in doc:
        full_text += page.get_text()
    doc.close()

    lines = full_text.split("\n")
    lines = [l.strip() for l in lines]

    code_match = re.search(r"كود العميل\s*\n\s*(\d+)", full_text)
    if not code_match:
        for i, l in enumerate(lines):
            if "كود العميل" in l and i + 1 < len(lines):
                code_match_val = lines[i + 1].strip()
                if re.match(r"\d+", code_match_val):
                    client_code = code_match_val
                    break
        else:
            print(f"  WARNING: Could not extract client code from {filepath}", file=sys.stderr)
            return None
    else:
        client_code = code_match.group(1)

    unit_raw = ""
    compound_suffix = ""
    for i, l in enumerate(lines):
        if l.startswith("SKYHILLS"):
            rest = l[len("SKYHILLS"):].strip()
            if rest:
                unit_raw = rest
            else:
                unit_raw = ""
            break

    for i, l in enumerate(lines):
        if l.startswith("SKYHILLS"):
            full_unit_str = l[len("SKYHILLS"):].strip()
            if "207" in full_unit_str:
                compound_suffix = "207"
            elif "B404" in full_unit_str or "B 404" in full_unit_str:
                compound_suffix = "B404"
            elif "B202" in full_unit_str or "B 202" in full_unit_str:
                compound_suffix = "B202"
            elif "B203" in full_unit_str or "B 203" in full_unit_str:
                compound_suffix = "B203"
            elif "B208" in full_unit_str or "B 208" in full_unit_str:
                compound_suffix = "B208"
            elif "B409" in full_unit_str or "B 409" in full_unit_str:
                compound_suffix = "B409"
            elif "B310" in full_unit_str or "B 310" in full_unit_str:
                compound_suffix = "B310"
            unit_raw = full_unit_str.replace(" ", "")
            break

    area_sqm = 0.0
    floor_raw = ""
    for i, l in enumerate(lines):
        if "الطابق" in l:
            a, f = extract_floor_area(l)
            area_sqm = a
            floor_raw = f
            break

    contract_date = ""
    contract_num = ""
    for i, l in enumerate(lines):
        if "تاريخ العقد" in l:
            for j in range(i + 1, min(i + 4, len(lines))):
                if re.match(r"\d{4}/\d{1,2}/\d{1,2}", lines[j]):
                    contract_date = lines[j]
                    break
                if lines[j] in ("الرضى", "+", "مساحة الوحده"):
                    continue
            break

    if not contract_date:
        for i, l in enumerate(lines):
            if "مساحة الوحده" in l and i + 1 < len(lines):
                next_l = lines[i + 1]
                if re.match(r"\d{4}/\d{1,2}/\d{1,2}", next_l):
                    contract_date = next_l
                elif i + 2 < len(lines) and re.match(r"\d{4}/\d{1,2}/\d{1,2}", lines[i + 2]):
                    contract_date = lines[i + 2]
                break

    for i, l in enumerate(lines):
        m = re.match(r"(\d+)رقم العقد", l)
        if m:
            contract_num = m.group(1)
            break

    start_idx = None
    for i, l in enumerate(lines):
        if l == "مبلغ  الدفعة" or l == "مبلغ الدفعة":
            start_idx = i + 1
            break

    rows: List[PaymentRow] = []
    if start_idx is not None:
        idx = start_idx
        while idx < len(lines):
            l = lines[idx]
            if "اجمالى" in l:
                break

            if not re.match(r"^\d+$", l):
                idx += 1
                continue

            row_num = int(l)

            if idx + 1 >= len(lines):
                break
            amount_str = lines[idx + 1]
            amount = parse_number(amount_str)

            if idx + 2 >= len(lines):
                break
            due_date_line = lines[idx + 2]

            due_date_match = re.match(r"(\d{4}/\d{1,2}/\d{1,2})", due_date_line)
            if due_date_match:
                due_date = due_date_match.group(1)
            else:
                idx += 1
                continue

            if idx + 3 >= len(lines):
                break
            paid_line = lines[idx + 3]

            is_paid = False
            paid_amount = 0.0
            paid_date = None
            payment_type_ar = ""
            payment_type_en = "Installment"
            receipt_num = None
            remaining = 0.0

            paid_date_match = re.match(r"(\d{4}/\d{1,2}/\d{1,2})(.*)", paid_line)
            zero_type_match = re.match(r"0(.+)", paid_line)

            if paid_date_match:
                paid_date_str = paid_date_match.group(1)
                type_suffix = paid_date_match.group(2).strip()
                paid_amount_str = lines[idx + 1]
                paid_amount_candidate = parse_number(lines[idx + 3 - 1]) if idx + 3 - 1 >= 0 else 0

                actual_paid_line = lines[idx + 3]
                check_paid = lines[idx + 2 + 1]

                paid_date_in_check = re.match(r"(\d{4}/\d{1,2}/\d{1,2})(.*)", check_paid)
                if paid_date_in_check:
                    pass

                is_paid = True
                paid_amount = amount
                paid_date = paid_date_str
                payment_type_ar, payment_type_en = detect_payment_type(type_suffix)

                if idx + 4 < len(lines) and re.match(r"^\d+$", lines[idx + 4]):
                    receipt_num = lines[idx + 4]
                    if idx + 5 < len(lines):
                        remaining = parse_number(lines[idx + 5])
                    idx = idx + 6
                else:
                    idx = idx + 4
                    remaining = 0.0

            elif zero_type_match:
                type_text = zero_type_match.group(1).strip()
                payment_type_ar, payment_type_en = detect_payment_type(type_text)
                is_paid = False
                paid_amount = 0.0
                paid_date = None
                if idx + 4 < len(lines):
                    remaining = parse_number(lines[idx + 4])
                idx = idx + 5

            else:
                paid_val = parse_number(paid_line)
                if paid_val > 0:
                    is_paid = True
                    paid_amount = paid_val
                    if idx + 4 < len(lines):
                        type_line = lines[idx + 4]
                        ptype_date = re.match(r"(\d{4}/\d{1,2}/\d{1,2})(.*)", type_line)
                        if ptype_date:
                            paid_date = ptype_date.group(1)
                            payment_type_ar, payment_type_en = detect_payment_type(ptype_date.group(2))
                            if idx + 5 < len(lines) and re.match(r"^\d+$", lines[idx + 5]):
                                receipt_num = lines[idx + 5]
                                if idx + 6 < len(lines):
                                    remaining = parse_number(lines[idx + 6])
                                idx = idx + 7
                            else:
                                idx = idx + 5
                        else:
                            payment_type_ar, payment_type_en = detect_payment_type(type_line)
                            idx = idx + 5
                    else:
                        idx = idx + 4
                else:
                    idx += 1
                    continue

            rows.append(PaymentRow(
                row_num=row_num,
                amount=amount,
                due_date=due_date,
                paid_amount=paid_amount,
                paid_date=paid_date,
                payment_type=payment_type_en,
                payment_type_ar=payment_type_ar,
                receipt_num=receipt_num,
                remaining=remaining,
                is_paid=is_paid,
            ))

    total_price = 0.0
    erp_total_paid = 0.0
    erp_total_remaining = 0.0

    for i, l in enumerate(lines):
        if "اجمالى سعر الوحدة" in l:
            for j in range(i + 1, min(i + 6, len(lines))):
                if re.match(r"اجمالى", lines[j]):
                    continue
                val = parse_number(lines[j])
                if val > 0:
                    total_price = val
                    break
            break

    summary_values = []
    found_summary = False
    for i, l in enumerate(lines):
        if "اجمالى سعر الوحدة" in l:
            found_summary = True
            continue
        if found_summary:
            if "اجمالى" in l:
                continue
            val = parse_number(l)
            if val > 0 or l.strip() == "0":
                summary_values.append(val)
            if len(summary_values) >= 3:
                break
            if "نهاية" in l or "TAB" in l:
                break

    if len(summary_values) >= 3:
        total_price = summary_values[0]
        erp_total_remaining = summary_values[1]
        erp_total_paid = summary_values[2]
    elif len(summary_values) == 2:
        erp_total_remaining = summary_values[0]
        erp_total_paid = summary_values[1]

    true_total_paid = sum(r.paid_amount for r in rows if r.is_paid)
    true_total_remaining = total_price - true_total_paid if total_price > 0 else sum(r.remaining for r in rows)

    if client_code == "125":
        for r in rows:
            if r.payment_type == "Utility Meter" and r.amount == 247600:
                r.is_paid = False
                r.paid_amount = 0.0
                r.paid_date = None
                r.receipt_num = None
                r.remaining = 247600.0

        true_total_paid = sum(r.paid_amount for r in rows if r.is_paid)
        true_total_remaining = total_price - true_total_paid if total_price > 0 else sum(r.remaining for r in rows)

    return ParsedLedger(
        pdf_file=filepath,
        client_code=client_code,
        unit_raw=unit_raw,
        unit_id=unit_raw,
        compound="SKYHILLS",
        area_sqm=area_sqm,
        floor_raw=floor_raw,
        contract_date=contract_date,
        contract_num=contract_num,
        total_price=total_price,
        erp_total_paid=erp_total_paid,
        erp_total_remaining=erp_total_remaining,
        true_total_paid=true_total_paid,
        true_total_remaining=true_total_remaining,
        rows=rows,
    )


def resolve_unit_id_for_auth(code: str, ledgers: List[ParsedLedger]) -> str:
    if code in EXISTING_AUTH_PROFILES:
        return EXISTING_AUTH_PROFILES[code]["unit"]
    for led in ledgers:
        if led.client_code == code:
            return led.unit_id
    if code in NEW_CLIENT_DEFAULTS:
        return NEW_CLIENT_DEFAULTS[code]["unit"]
    return f"UNIT{code}"


def resolve_units_list_for_auth(code: str, ledgers: List[ParsedLedger]) -> Optional[List[str]]:
    if code in EXISTING_AUTH_PROFILES and "units" in EXISTING_AUTH_PROFILES[code]:
        return EXISTING_AUTH_PROFILES[code]["units"]
    client_ledgers = [l for l in ledgers if l.client_code == code]
    if len(client_ledgers) > 1:
        return [l.unit_id for l in client_ledgers]
    return None


def get_profile_for_code(code: str) -> dict:
    if code in EXISTING_AUTH_PROFILES:
        return EXISTING_AUTH_PROFILES[code]
    if code in NEW_CLIENT_DEFAULTS:
        return NEW_CLIENT_DEFAULTS[code]
    return {"name": f"Client {code}", "phone": f"01000000{code.zfill(3)}", "unit": f"UNIT{code}"}


def fmt_amount(val: float) -> str:
    if val == int(val):
        return f"{int(val)}.0"
    return f"{val}"


# Name mapping dictionary to translate Arabic names to natural English equivalents
NAME_MAPPINGS = {
    "أحمد": "ahmed", "احمد": "ahmed", "محمد": "mohamed", "محمود": "mahmoud",
    "علي": "ali", "حسن": "hasan", "حسين": "hussein", "إبراهيم": "ibrahim",
    "ابراهيم": "ibrahim", "مصطفى": "mostafa", "خالد": "khaled", "سامح": "sameh",
    "أمير": "amir", "امير": "amir", "حنفي": "hanafy", "مروة": "marwa",
    "شعبان": "shaban", "جلال": "jalal", "سمير": "samir", "غانم": "ghanem",
    "مكي": "mekky", "اشرف": "ashraf", "أشرف": "ashraf", "عبيد": "obeid",
    "عبد الخالق": "abdelkhalek", "عوف": "ouf", "عبد الله": "abdallah",
    "عبد الحميد": "abdelhamid", "السيد": "elsayed", "سعيد": "said",
    "عبد العليم": "abdelalim", "طلعت": "talaat", "عادل": "adel",
    "سيد": "sayed", "سحر": "sahar", "رمضان": "ramadan", "ياسمين": "yasmin",
    "عبد الوهاب": "abdelwahab", "محسن": "mohsen", "اسامه": "osama",
    "أسامة": "osama", "شهاب": "shehab", "صلاح": "salah", "شاذلي": "shazly",
    "الجواد": "gawad", "عبد الجواد": "abdelgawad", "بسيوني": "basyouni",
    "أبو الغيط": "aboulgheit", "ابو الغيط": "aboulgheit", "عوض الله": "awadallah",
    "رشيد": "rashid", "دولت": "dowlat", "موسى": "mousa", "عطيه": "atiya",
    "عطية": "atiya", "البنا": "elbanna", "بدوي": "badawy", "فضل المولى": "fadlelmawla",
    "فضل": "fadl", "المولى": "mawla", "رشاد": "rashad", "أحمد عبد العظيم صدقي": "ahmed.abdelazim"
}

def get_english_name_for_sync(name):
    # Check if name contains Arabic characters
    has_arabic = any(u'\u0600' <= c <= u'\u06FF' for c in name)
    if not has_arabic:
        clean = re.sub(r'[^a-zA-Z0-9\s]', '', name).lower().strip()
        return re.sub(r'\s+', '.', clean)

    # Normalize name helper
    name_norm = name.replace("أ", "ا").replace("إ", "ا").replace("آ", "ا")
    
    # Replace compound names first
    compounds = {
        "عبد الجواد": "abdelgawad",
        "عبد الخالق": "abdelkhalek",
        "عبد الله": "abdallah",
        "عبد الحميد": "abdelhamid",
        "عبد العليم": "abdelalim",
        "عبد الوهاب": "abdelwahab",
        "أبو الغيط": "aboulgheit",
        "ابو الغيط": "aboulgheit",
        "عوض الله": "awadallah",
        "فضل المولى": "fadlelmawla",
        "أحمد عبد العظيم صدقي": "ahmed.abdelazim"
    }
    for comp, eng in compounds.items():
        normalized_comp = comp.replace("أ", "ا").replace("إ", "ا")
        if normalized_comp in name_norm:
            name_norm = name_norm.replace(comp, eng)

    # Split into words
    words = name_norm.split()
    translated_words = []
    for word in words:
        if re.search(r'[a-zA-Z]', word):
            translated_words.append(word.lower())
            continue
            
        if word in NAME_MAPPINGS:
            translated_words.append(NAME_MAPPINGS[word])
        else:
            # Fallback transliteration
            char_map = {
                'ب': 'b', 'ت': 't', 'ة': 'a', 'ث': 'th', 'ج': 'j', 'ح': 'h', 'خ': 'kh',
                'د': 'd', 'ذ': 'z', 'ر': 'r', 'ز': 'z', 'س': 's', 'ش': 'sh', 'ص': 's',
                'ض': 'd', 'ط': 't', 'ظ': 'z', 'ع': 'a', 'غ': 'gh', 'ف': 'f', 'ق': 'q',
                'ك': 'k', 'ل': 'l', 'م': 'm', 'ن': 'n', 'ه': 'h', 'و': 'w', 'ي': 'y',
                'ى': 'a', 'ئ': 'y', 'ؤ': 'w', 'ء': 'a', 'ا': 'a'
            }
            trans_word = "".join(char_map.get(c, '') for c in word)
            trans_word = trans_word.replace("aa", "a").replace("oo", "o").replace("ee", "e")
            if trans_word:
                translated_words.append(trans_word)
            
    translated_words = [w for w in translated_words if w]
    translated_words = translated_words[:3] # Limit to first three names
    return ".".join(translated_words)

def generate_auth_mock_data(all_codes: List[str], ledgers: List[ParsedLedger]) -> str:
    lines = []
    lines.append("class AuthMockData {")
    lines.append("  static const String defaultMasterPassword = 'iliving2026';")
    lines.append("")
    lines.append("  static const List<Map<String, dynamic>> mockUsers = [")

    existing_emails = set()
    for code in all_codes:
        profile = get_profile_for_code(code)
        name = profile["name"]
        phone = profile["phone"]
        unit = resolve_unit_id_for_auth(code, ledgers)
        units_list = resolve_units_list_for_auth(code, ledgers)
        
        email_prefix = get_english_name_for_sync(name)
        email = f"{email_prefix}@new-build-egypt.com"
        if email in existing_emails:
            email = f"{email_prefix}.{code}@new-build-egypt.com"
        existing_emails.add(email)

        if units_list:
            units_str = ", ".join([f"'{u}'" for u in units_list])
            lines.append(f"    {{'name': '{name}', 'phone': '{phone}', 'code': '{code}', 'unit': '{unit}', 'email': '{email}', 'units': [{units_str}]}},")
        else:
            lines.append(f"    {{'name': '{name}', 'phone': '{phone}', 'code': '{code}', 'unit': '{unit}', 'email': '{email}'}},")

    lines.append("  ];")
    lines.append("")
    lines.append("  static Map<String, dynamic>? findProfile(String emailOrPhone) {")
    lines.append("    final cleanInput = emailOrPhone.trim().toLowerCase();")
    lines.append("    if (cleanInput.isEmpty) return null;")
    lines.append("    ")
    lines.append("    // 1. Match by exact email string")
    lines.append("    for (final u in mockUsers) {")
    lines.append("      if (u['email'] != null && u['email'] == cleanInput) {")
    lines.append("        return u;")
    lines.append("      }")
    lines.append("    }")
    lines.append("    ")
    lines.append("    // 2. Match by clean phone digits or code")
    lines.append("    final digits = cleanInput.replaceAll(RegExp(r'[^0-9]'), '');")
    lines.append("    if (digits.isNotEmpty) {")
    lines.append("      for (final u in mockUsers) {")
    lines.append("        final cleanPhone = (u['phone'] as String).replaceAll(RegExp(r'[^0-9]'), '');")
    lines.append("        if (digits == u['code'] ||")
    lines.append("            digits.endsWith(cleanPhone) ||")
    lines.append("            cleanPhone.endsWith(digits)) {")
    lines.append("          return u;")
    lines.append("        }")
    lines.append("      }")
    lines.append("    }")
    lines.append("    return null;")
    lines.append("  }")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def get_unit_type(unit_id: str, area: float) -> str:
    unit_clean = unit_id.replace("-", "").replace(" ", "").upper()
    if "B01" in unit_clean and "B202" in unit_clean:
        return "Luxury Ground Villa"
    if "A01" in unit_clean and ("B202" in unit_clean or "B203" in unit_clean or "207" in unit_clean):
        return "2 BR Garden Apartment"
    if "A01" in unit_clean and "B208" in unit_clean:
        return "2 BR Garden Apartment"
    if "A01" in unit_clean and "B409" in unit_clean:
        return "2 BR Garden Apartment"
    if "501" in unit_clean or "502" in unit_clean:
        return "5th Floor Penthouse"
    if "401" in unit_clean or "402" in unit_clean or "403" in unit_clean:
        return "4th Floor Sky Penthouse"
    if "301" in unit_clean or "302" in unit_clean or "303" in unit_clean:
        return "3rd Floor Sky Suite"
    if "201" in unit_clean or "202" in unit_clean or "203" in unit_clean:
        return "2nd Floor Luxury Suite"
    if "101" in unit_clean or "102" in unit_clean or "103" in unit_clean or "104" in unit_clean:
        return "1st Floor Suite"
    if "B01" in unit_clean or "B02" in unit_clean:
        return "Ground Floor Villa"
    if area > 160:
        return "Premium Suite"
    return "Standard Suite"


def determine_milestone(payment_type: str, row_num: int) -> str:
    if payment_type == "Downpayment":
        return "Contract Signing"
    if payment_type == "Maintenance Deposit":
        return "Maintenance Escrow"
    if payment_type == "Utility Meter":
        return "Utility Installation"
    if payment_type == "Final Delivery":
        return "Delivery Milestone"
    if row_num <= 2:
        return "Within 30 days of SPA"
    if row_num <= 5:
        return "Foundation Phase"
    if row_num <= 10:
        return "Structure Phase"
    if row_num <= 15:
        return "Finishing Phase"
    if row_num <= 20:
        return "Pre-Delivery Phase"
    return "Extended Payment"


def row_title(payment_type: str, row_num: int, installment_counter: int) -> str:
    if payment_type == "Downpayment":
        return "Contract Downpayment"
    if payment_type == "Maintenance Deposit":
        return "Maintenance Fund Deposit"
    if payment_type == "Utility Meter":
        return "Utility Meter Installation"
    if payment_type == "Final Delivery":
        return "Final Delivery Payment"
    return f"Installment {installment_counter}"


def generate_operations_mock_data(ledgers: List[ParsedLedger], all_codes: List[str]) -> str:
    code_to_ledgers: dict[str, List[ParsedLedger]] = {}
    for led in ledgers:
        code_to_ledgers.setdefault(led.client_code, []).append(led)

    out = []
    out.append("import '../models/operation_ticket_model.dart';")
    out.append("import '../models/unit_ledger_model.dart';")
    out.append("import '../models/gate_utility_model.dart';")
    out.append("import '../models/invoice_model.dart';")
    out.append("")
    out.append("class OperationsMockData {")

    out.append("  static final List<Map<String, dynamic>> dummyOpsCompounds = [")
    for led in ledgers:
        code = led.client_code
        unit_id = led.unit_id
        if code in EXISTING_AUTH_PROFILES:
            unit_id = EXISTING_AUTH_PROFILES[code].get("unit", unit_id)
        elif code in NEW_CLIENT_DEFAULTS:
            unit_id = NEW_CLIENT_DEFAULTS[code].get("unit", unit_id)

        unit_type = get_unit_type(unit_id, led.area_sqm)

        dp_row = None
        maint_row = None
        installment_rows = []
        for r in led.rows:
            if r.payment_type == "Downpayment" and dp_row is None:
                dp_row = r
            elif r.payment_type == "Maintenance Deposit":
                maint_row = r
            elif r.payment_type not in ("Utility Meter",):
                installment_rows.append(r)
            else:
                installment_rows.append(r)

        dp_amount = dp_row.amount if dp_row else 0.0
        dp_is_paid = dp_row.is_paid if dp_row else False

        out.append("    {")
        out.append("      'title': 'Sky Hills (سكي هيلز)',")
        out.append("      'location': 'New October City, Greater Cairo',")
        out.append(f"      'unit': '{unit_id}',")
        out.append(f"      'type': '{unit_type}',")
        out.append("      'downPayment': {")
        out.append(f"        'isPaid': {'true' if dp_is_paid else 'false'},")
        out.append(f"        'status': '{'PAID (10%)' if dp_is_paid else 'PENDING'}',")
        if dp_is_paid and dp_row and dp_row.paid_date:
            out.append(f"        'timestamp': '{parse_date_iso(dp_row.paid_date)} 09:00:00',")
        else:
            out.append(f"        'timestamp': '',")
        out.append(f"        'amount': {fmt_amount(dp_amount)},")
        out.append("      },")

        out.append("      'installments': [")
        inst_counter = 0
        for r in installment_rows:
            inst_counter += 1
            title = row_title(r.payment_type, r.row_num, inst_counter)
            amount_fmt = f"{r.amount:,.0f}" if r.amount == int(r.amount) else f"{r.amount:,.2f}"
            out.append("        {")
            out.append(f"          'title': '{title}',")
            out.append(f"          'isPaid': {'true' if r.is_paid else 'false'},")
            out.append(f"          'due': '{'Paid' if r.is_paid else parse_date_iso(r.due_date)}',")
            out.append(f"          'amount': '{amount_fmt} ج.م',")
            out.append(f"          'date': '{'Paid' if r.is_paid else 'Upcoming'}',")
            out.append("        },")
        out.append("      ],")

        maint_is_paid = maint_row.is_paid if maint_row else False
        maint_balance = maint_row.amount if maint_row else 0.0
        out.append("      'maintenance': {")
        out.append(f"        'isPaid': {'true' if maint_is_paid else 'false'},")
        out.append(f"        'status': '{'Escrow Secured' if maint_is_paid else 'Escrow Outstanding'}',")
        out.append(f"        'balance': {fmt_amount(maint_balance)},")
        out.append(f"        'annualFee': {fmt_amount(maint_balance)},")
        out.append("      },")
        out.append("      'activeTickets': [],")
        out.append("    },")

    out.append("  ];")
    out.append("")

    out.append("  static final List<OperationTicketModel> dummyTickets = [")
    out.append("    const OperationTicketModel(")
    out.append("      id: 'T-881',")
    out.append("      trade: TicketTrade.plumbing,")
    out.append("      description: 'Water Pressure Meter Calib',")
    out.append("      status: TicketStatus.inProgress,")
    out.append("      priority: TicketPriority.high,")
    out.append("      compoundId: 'dev_1',")
    out.append("      unitId: 'B01B202',")
    out.append("      clientId: 'client_147',")
    out.append("      reportedByName: 'أحمد عبد العظيم صدقي',")
    out.append("      contactPhone: '+201000197979',")
    out.append("      createdAtIso: '2026-05-20T09:00:00.000Z',")
    out.append("      updatedAtIso: '2026-05-22T11:30:00.000Z',")
    out.append("      statusLog: [")
    out.append("        TicketStatusEntry(")
    out.append("          status: 'requested',")
    out.append("          changedByName: 'أحمد عبد العظيم صدقي',")
    out.append("          changedByRole: 'Resident',")
    out.append("          timestampIso: '2026-05-20T09:00:00.000Z',")
    out.append("          note: 'Initial report filed via iLiving app',")
    out.append("        ),")
    out.append("        TicketStatusEntry(")
    out.append("          status: 'inProgress',")
    out.append("          changedByName: 'Ahmed Saber',")
    out.append("          changedByRole: 'Technician',")
    out.append("          timestampIso: '2026-05-22T11:30:00.000Z',")
    out.append("          note: 'Dispatched to site — calibration equipment on-site',")
    out.append("        ),")
    out.append("      ],")
    out.append("    ),")
    out.append("  ];")
    out.append("")

    out.append("  static final List<InvoiceModel> dummyInvoices = [")
    for led in ledgers:
        code = led.client_code
        unit_id = led.unit_id
        if code in EXISTING_AUTH_PROFILES:
            unit_id = EXISTING_AUTH_PROFILES[code].get("unit", unit_id)
        elif code in NEW_CLIENT_DEFAULTS:
            unit_id = NEW_CLIENT_DEFAULTS[code].get("unit", unit_id)

        dp_row = None
        inst_counter = 0
        for r in led.rows:
            if r.payment_type == "Downpayment" and dp_row is None:
                dp_row = r
                inv_id = f"INV-{unit_id}-DP"
                inv_type = "InvoiceType.downPayment"
                inv_title = "Contract Downpayment"
                receipt_type = "DP"
            elif r.payment_type == "Maintenance Deposit":
                inv_id = f"INV-{unit_id}-MF"
                inv_type = "InvoiceType.maintenanceFee"
                inv_title = "Maintenance Fund Deposit"
                receipt_type = "MF"
            elif r.payment_type == "Utility Meter":
                inv_id = f"INV-{unit_id}-UM"
                inv_type = "InvoiceType.electricity"
                inv_title = "Utility Meter Installation"
                receipt_type = "UM"
            else:
                inst_counter += 1
                inv_id = f"INV-{unit_id}-I{inst_counter}"
                inv_type = "InvoiceType.installment"
                inv_title = f"Installment {inst_counter}"
                receipt_type = f"I{inst_counter}"

            out.append("    const InvoiceModel(")
            out.append(f"      id: '{inv_id}',")
            out.append(f"      type: {inv_type},")
            out.append(f"      title: '{inv_title}',")
            out.append(f"      amountEGP: {fmt_amount(r.amount)},")
            out.append(f"      isPaid: {'true' if r.is_paid else 'false'},")
            out.append(f"      dueDate: '{parse_date_iso(r.due_date)}',")
            if r.is_paid and r.paid_date:
                out.append(f"      paidTimestamp: '{parse_date_iso(r.paid_date)} 09:00:00',")
            out.append("      compoundId: 'dev_1',")
            out.append(f"      unitId: '{unit_id}',")
            if r.is_paid:
                out.append(f"      receiptUrl: 'https://new-build-egypt.com/assets/receipts/receipt_{code}_{receipt_type}.pdf',")
            out.append("    ),")

    out.append("  ];")
    out.append("")

    out.append("  static final List<UnitLedger> dummyLedgers = [")
    for led in ledgers:
        code = led.client_code
        unit_id = led.unit_id
        if code in EXISTING_AUTH_PROFILES:
            unit_id = EXISTING_AUTH_PROFILES[code].get("unit", unit_id)
        elif code in NEW_CLIENT_DEFAULTS:
            unit_id = NEW_CLIENT_DEFAULTS[code].get("unit", unit_id)

        unit_type = get_unit_type(unit_id, led.area_sqm)

        dp_row = None
        maint_row = None
        installment_rows = []
        for r in led.rows:
            if r.payment_type == "Downpayment" and dp_row is None:
                dp_row = r
            elif r.payment_type == "Maintenance Deposit":
                maint_row = r
            else:
                installment_rows.append(r)

        out.append("    const UnitLedger(")
        out.append("      compoundId: 'dev_1',")
        out.append(f"      clientId: 'client_{code}',")
        out.append(f"      unitId: '{unit_id}',")
        out.append(f"      unitType: '{unit_type}',")

        dp_amount = dp_row.amount if dp_row else 0.0
        dp_is_paid = dp_row.is_paid if dp_row else False
        pct = round((dp_amount / led.total_price * 100), 1) if led.total_price > 0 else 10.0
        out.append("      downPayment: DownPaymentRecord(")
        out.append(f"        isPaid: {'true' if dp_is_paid else 'false'},")
        out.append(f"        status: '{'PAID' if dp_is_paid else 'PENDING'} ({pct:.0f}%)',")
        out.append(f"        percentageDue: {pct},")
        out.append(f"        amountEGP: {fmt_amount(dp_amount)},")
        if dp_is_paid and dp_row and dp_row.paid_date:
            out.append(f"        paidTimestamp: '{parse_date_iso(dp_row.paid_date)}T09:00:00.000Z',")
            out.append(f"        receiptUrl: 'https://new-build-egypt.com/assets/receipts/receipt_{code}_DP.pdf',")
        out.append(f"        transactionRef: 'BNK-EG-{code}-SH',")
        out.append("      ),")

        out.append("      installments: [")
        inst_counter = 0
        for r in installment_rows:
            inst_counter += 1
            title = row_title(r.payment_type, r.row_num, inst_counter)
            milestone = determine_milestone(r.payment_type, r.row_num)
            receipt_type = f"I{inst_counter}"
            if r.payment_type == "Utility Meter":
                receipt_type = "UM"
            elif r.payment_type == "Final Delivery":
                receipt_type = "FD"

            out.append("        InstallmentRecord(")
            out.append(f"          id: 'INV-{unit_id}-{receipt_type}',")
            out.append(f"          title: '{title}',")
            out.append(f"          isPaid: {'true' if r.is_paid else 'false'},")
            out.append(f"          amountEGP: {fmt_amount(r.amount)},")
            out.append(f"          dueDateIso: '{parse_date_iso(r.due_date)}',")
            if r.is_paid:
                out.append(f"          dueDateLabel: 'Paid',")
                if r.paid_date:
                    out.append(f"          paidTimestamp: '{parse_date_iso(r.paid_date)}T09:00:00.000Z',")
                out.append(f"          receiptUrl: 'https://new-build-egypt.com/assets/receipts/receipt_{code}_{receipt_type}.pdf',")
            else:
                label_date = parse_date_iso(r.due_date)
                if r.payment_type == "Final Delivery":
                    out.append(f"          dueDateLabel: 'On Handover',")
                else:
                    out.append(f"          dueDateLabel: '{label_date}',")
            out.append(f"          milestoneTag: '{milestone}',")
            out.append("        ),")
        out.append("      ],")

        maint_is_paid = maint_row.is_paid if maint_row else False
        maint_balance = maint_row.amount if maint_row else 0.0
        out.append("      maintenance: MaintenanceFundRecord(")
        out.append(f"        isPaid: {'true' if maint_is_paid else 'false'},")
        out.append(f"        status: '{'Escrow Secured' if maint_is_paid else 'Escrow Outstanding'}',")
        out.append(f"        balanceEGP: {fmt_amount(maint_balance)},")
        out.append(f"        annualFeeEGP: {fmt_amount(maint_balance)},")
        out.append(f"        nextDueDateIso: '2026-12-31',")
        out.append(f"        escrowAccountRef: 'ESC-SH-{unit_id}-ILIVING',")
        out.append("      ),")
        out.append("    ),")

    out.append("  ];")
    out.append("")

    out.append("  static final List<GateAccessCode> dummyGateCodes = [")
    out.append("    GateAccessCode.generate(")
    out.append("      compoundId: 'dev_1',")
    out.append("      unitId: 'B01B202',")
    out.append("      issuedByClientId: 'client_147',")
    out.append("      guestName: 'Ahmed Al-Rashid',")
    out.append("      guestPhone: '+20101555666',")
    out.append("      accessType: GateAccessType.vehicle,")
    out.append("      validity: const Duration(hours: 24),")
    out.append("      vehiclePlate: 'JKL-345',")
    out.append("      maxScans: 2,")
    out.append("      notes: 'Family visit — approved by estate manager',")
    out.append("    ),")
    out.append("  ];")
    out.append("")
    out.append("  static final List<GateAccessLog> dummyGateLogs = [];")
    out.append("")
    out.append("}")
    out.append("")
    return "\n".join(out)


def main():
    print("=" * 70)
    print("iLiving Pipeline Sync — TAB ERP PDF Ingestion Engine")
    print("=" * 70)

    pdf_files = sorted(
        [f for f in os.listdir(PDF_DIR) if f.endswith(".pdf")],
        key=lambda x: int(re.match(r"(\d+)", x).group(1))
    )

    print(f"\nFound {len(pdf_files)} PDF files in '{PDF_DIR}/'")

    ledgers: List[ParsedLedger] = []
    for pf in pdf_files:
        filepath = os.path.join(PDF_DIR, pf)
        result = parse_pdf(filepath)
        if result:
            ledgers.append(result)
            paid_count = sum(1 for r in result.rows if r.is_paid)
            unpaid_count = sum(1 for r in result.rows if not r.is_paid)
            print(f"  ✓ {pf:>8} | code={result.client_code:>4} | unit={result.unit_id:<12} | rows={len(result.rows):>3} | paid={paid_count:>3} | unpaid={unpaid_count:>3} | total_price={result.total_price:>12,.0f} | true_paid={result.true_total_paid:>12,.0f} | true_rem={result.true_total_remaining:>12,.0f}")
        else:
            print(f"  ✗ {pf:>8} | PARSE FAILED")

    print(f"\nSuccessfully parsed {len(ledgers)} ledgers from {len(pdf_files)} PDFs")

    all_pdf_codes = sorted(set(l.client_code for l in ledgers), key=lambda x: int(x))
    all_auth_codes = sorted(set(list(EXISTING_AUTH_PROFILES.keys()) + all_pdf_codes), key=lambda x: int(x))

    missing_codes = [c for c in all_pdf_codes if c not in EXISTING_AUTH_PROFILES]
    print(f"\nExisting auth profiles: {len(EXISTING_AUTH_PROFILES)}")
    print(f"New profiles to add: {len(missing_codes)} -> {missing_codes}")
    print(f"Total auth profiles: {len(all_auth_codes)}")

    multi_unit_clients = {}
    for code in all_pdf_codes:
        client_ledgers = [l for l in ledgers if l.client_code == code]
        if len(client_ledgers) > 1:
            multi_unit_clients[code] = [l.unit_id for l in client_ledgers]

    if multi_unit_clients:
        print(f"\nMulti-unit clients detected:")
        for code, units in multi_unit_clients.items():
            print(f"  Client {code}: {units}")

    print("\n" + "=" * 70)
    print("Generating auth_mock_data.dart ...")
    auth_dart = generate_auth_mock_data(all_auth_codes, ledgers)
    os.makedirs(os.path.dirname(AUTH_OUT), exist_ok=True)
    with open(AUTH_OUT, "w", encoding="utf-8") as f:
        f.write(auth_dart)
    print(f"  ✓ Written to {AUTH_OUT} ({len(auth_dart)} bytes, {auth_dart.count(chr(10))} lines)")

    print("\nGenerating operations_mock_data.dart ...")
    ops_dart = generate_operations_mock_data(ledgers, all_auth_codes)
    os.makedirs(os.path.dirname(OPS_OUT), exist_ok=True)
    with open(OPS_OUT, "w", encoding="utf-8") as f:
        f.write(ops_dart)
    print(f"  ✓ Written to {OPS_OUT} ({len(ops_dart)} bytes, {ops_dart.count(chr(10))} lines)")

    print("\nGenerating prices.json ...")
    import json
    from datetime import datetime
    
    # Load existing prices.json to preserve manual edits and custom added units
    existing_units = {}
    if os.path.exists("prices.json"):
        try:
            with open("prices.json", "r", encoding="utf-8") as f:
                old_data = json.load(f)
                if isinstance(old_data, dict) and "units" in old_data:
                    for u in old_data["units"]:
                        if isinstance(u, dict) and "unit_number" in u:
                            existing_units[u["unit_number"]] = u
            print(f"  Loaded {len(existing_units)} existing units from prices.json for merging")
        except Exception as e:
            print(f"  WARNING: Could not parse existing prices.json for merge: {e}")

    units_list = []
    for led in ledgers:
        code = led.client_code
        unit_id = led.unit_id
        if code in EXISTING_AUTH_PROFILES:
            unit_id = EXISTING_AUTH_PROFILES[code].get("unit", unit_id)
        elif code in NEW_CLIENT_DEFAULTS:
            unit_id = NEW_CLIENT_DEFAULTS[code].get("unit", unit_id)
            
        compound_id = "dev_1"
        if "LM" in unit_id or "lm" in unit_id:
            compound_id = "dev_2"
        elif "ZL" in unit_id or "zl" in unit_id:
            compound_id = "dev_3"
            
        price_egp = led.total_price
        area = led.area_sqm if led.area_sqm > 0 else 1.0
        price_per_sqft = round(price_egp / area, 2)
        
        asset_detail = get_unit_type(unit_id, led.area_sqm)
        
        installments = [r for r in led.rows if r.payment_type not in ["Downpayment", "Maintenance Deposit", "Utility Meter"]]
        layout = "Quarterly"
        if installments:
            types = [r.payment_type for r in installments]
            from collections import Counter
            most_common = Counter(types).most_common(1)
            if most_common:
                layout = most_common[0][0]
                
        updated_at = datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")

        # Merge with manually edited details from prices.json if available
        existing_u = existing_units.get(unit_id)
        if existing_u:
            price_egp = existing_u.get("price_egp", price_egp)
            price_per_sqft = existing_u.get("price_per_sqft", price_per_sqft)
            layout = existing_u.get("installment_layout", layout)
            asset_detail = existing_u.get("asset_detail", asset_detail)
            updated_at = existing_u.get("updated_at", updated_at)

        units_list.append({
            "unit_number": unit_id,
            "compound_id": compound_id,
            "price_egp": price_egp,
            "price_per_sqft": price_per_sqft,
            "installment_layout": layout,
            "asset_detail": asset_detail,
            "updated_at": updated_at
        })
        
    # Append manually created units (present in existing_units but not in current parsed ledgers)
    resolved_pdf_unit_set = {u["unit_number"] for u in units_list}
    preserved_count = 0
    for u_num, u_data in existing_units.items():
        if u_num not in resolved_pdf_unit_set:
            units_list.append(u_data)
            preserved_count += 1
            
    if preserved_count > 0:
        print(f"  Preserved {preserved_count} manually created units not in PDF ledgers")

    output = {
        "units": units_list
    }
    with open("prices.json", "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)
    print(f"  ✓ Written to prices.json ({len(units_list)} units)")


    comment_count = 0
    for line in auth_dart.split("\n"):
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("///"):
            comment_count += 1
    for line in ops_dart.split("\n"):
        stripped = line.strip()
        if stripped.startswith("//") or stripped.startswith("///"):
            comment_count += 1
    print(f"\nComment verification: {comment_count} comment lines found ({'PASS ✓' if comment_count == 0 else 'FAIL ✗'})")

    print("\n" + "=" * 70)
    print("CLIENT 125 SPECIAL VERIFICATION:")
    for led in ledgers:
        if led.client_code == "125":
            for r in led.rows:
                if r.payment_type == "Utility Meter":
                    print(f"  Utility Meter Row: amount={r.amount}, isPaid={r.is_paid}, paid_amount={r.paid_amount}, remaining={r.remaining}")
            print(f"  True Total Paid: {led.true_total_paid:,.0f}")
            print(f"  True Total Remaining: {led.true_total_remaining:,.0f}")
            break

    print("\n" + "=" * 70)
    print("PIPELINE SYNC COMPLETE ✓")
    print("=" * 70)


if __name__ == "__main__":
    main()
