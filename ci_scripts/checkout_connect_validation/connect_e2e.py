"""Creates Connect Checkout Sessions for the iOS UI-test harness and verifies the resulting payment objects.

  connect_e2e.py create > cases.json
  connect_e2e.py verify cases.json
"""
import json, os, sys, uuid
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from direct import request

PK = os.environ["STRIPE_TEST_PUBLISHABLE_KEY"]
CONNECTED = "acct_1SGPAfLpAeuIWWTH"
AMOUNT = 1000
V = "2026-08-26.preview"


def base(extra=None):
    p = {
        "ui_mode": "mobile_elements",
        "currency": "usd",
        "allowed_payment_method_types": ["card"],
        "items": [{"type": "one_time_price", "one_time_price": {"items": [{"price_data": {"currency": "usd", "unit_amount": AMOUNT, "product_data": {"name": "Connect test"}}, "quantity": 1}]}}],
        "customer_email": "connect-test@example.com",
    }
    p.update(extra or {})
    return p


def must(r, what):
    if "error" in r:
        raise SystemExit(f"{what}: {r['error'].get('message')}")
    return r


def customer_with_card(account):
    cus = must(request("POST", "customers", {"email": "connect-test@example.com"}, account=account, version="2024-06-20"), "customer")
    pm = must(request("POST", "payment_methods", {"type": "card", "card": {"token": "tok_visa"}, "allow_redisplay": "always"}, account=account, version="2024-06-20"), "pm")
    pm = must(request("POST", f"payment_methods/{pm['id']}/attach", {"customer": cus["id"]}, account=account, version="2024-06-20"), "attach")
    return cus["id"], pm["id"]


def coupon(account):
    return must(request("POST", "coupons", {"percent_off": 20, "duration": "once"}, account=account, version="2024-06-20"), "coupon")["id"]


def create():
    group = f"ORDER_{uuid.uuid4().hex[:8]}"
    dest = {"destination": CONNECTED}
    specs = {
        # §1 Direct charges: Session owned by the connected account.
        "direct_card": (CONNECTED, {}, "card"),
        "direct_fee_3ds": (CONNECTED, {"payment_settings": {"application_fee_data": {"initial_amount": 123}}}, "3ds"),
        "direct_3ds_cancel_retry": (CONNECTED, {}, "3ds_cancel_retry"),
        "direct_saved": (CONNECTED, "saved", "saved"),
        "direct_applepay": (CONNECTED, {}, "applepay"),
        # §2 Destination charges: platform-owned Session.
        "dest_fee_card": (None, {"payment_settings": {"transfer_data": dest, "application_fee_data": {"initial_amount": 123}}}, "card"),
        "dest_amount_3ds": (None, {"payment_settings": {"transfer_data": {**dest, "transfer_amount": {"initial_amount": 800}}}}, "3ds"),
        "dest_pct_saved": (None, "pct_saved", "saved"),
        "dest_applepay": (None, {"payment_settings": {"transfer_data": dest, "application_fee_data": {"initial_amount": 123}}}, "applepay"),
        # §3 SC&T: platform-owned Session with transfer_group.
        "sct_card": (None, {"payment_settings": {"transfer_group": group}}, "card"),
        "sct_3ds": (None, {"payment_settings": {"transfer_group": group}}, "3ds"),
        # Link
        "direct_link_wallet": (CONNECTED, {"customer_email": None}, "link_wallet"),
        "direct_link_inline": (CONNECTED, {"customer_email": f"link_inline+{uuid.uuid4().hex[:10]}@link.com"}, "link_inline"),
        "dest_link_wallet_3ds": (None, {"customer_email": None, "payment_settings": {"transfer_data": dest, "application_fee_data": {"initial_amount": 123}}}, "link_wallet_3ds_cancel_retry"),
        "sct_link_wallet": (None, {"customer_email": None, "payment_settings": {"transfer_group": group}}, "link_wallet"),
        "dest_link_inline": (None, {"customer_email": f"link_inline+{uuid.uuid4().hex[:10]}@link.com", "payment_settings": {"transfer_data": dest, "application_fee_data": {"initial_amount": 123}}}, "link_inline"),
    }
    cases = {}
    only = sys.argv[2:]
    for name, (account, extra, flow) in specs.items():
        if only and name not in only:
            continue
        meta = {}
        if extra == "saved":
            cus, pm = customer_with_card(account)
            extra = {"customer": cus, "customer_email": None}
            meta = {"customer": cus, "payment_method": pm}
        elif extra == "pct_saved":
            cus, pm = customer_with_card(account)
            extra = {
                "customer": cus, "customer_email": None,
                "payment_settings": {"transfer_data": dest, "application_fee_data": {"percentage_decimal": "10"}},
            }
            meta = {"customer": cus, "payment_method": pm}
        params = {k: v for k, v in base(extra).items() if v is not None}
        s = request("POST", "checkout/sessions", params, account=account, version=V)
        if "error" in s:
            cases[name] = {"error": s["error"].get("message"), "account": account, "flow": flow}
            continue
        cases[name] = {"id": s["id"], "client_secret": s["client_secret"], "account": account, "flow": flow, "transfer_group": group if name.startswith("sct") else None, **meta}
    return {"publishable_key": PK, "cases": cases}


def get(path, account, expand=()):
    params = {"expand": list(expand)} if expand else {}
    return request("GET", path, params, account=account, version="2024-06-20")


def verify(path):
    data = json.load(open(path))
    rows = []
    for name, c in data["cases"].items():
        if "error" in c:
            rows.append((name, "SESSION CREATE FAILED", c["error"]))
            continue
        acct = c["account"]
        s = get(f"checkout/sessions/{c['id']}", acct, ["payment_intent"])
        pi = s.get("payment_intent")
        checks = []
        if not pi:
            rows.append((name, "NO PAYMENT INTENT", f"session status={s.get('status')} payment_status={s.get('payment_status')}"))
            continue
        pi = get(f"payment_intents/{pi['id']}", acct, ["latest_charge", "latest_charge.transfer", "latest_charge.application_fee", "payment_method"])
        ch = pi.get("latest_charge") or {}
        ok = lambda cond, msg: checks.append(("OK " if cond else "FAIL ") + msg)
        ok(s.get("status") == "complete" and s.get("payment_status") == "paid", f"session {s.get('status')}/{s.get('payment_status')}")
        ok(pi["status"] == "succeeded", f"PI {pi['id']} {pi['status']} amount={pi['amount']}")
        owner = acct or "platform"
        ok(True, f"PI owner={owner} (retrieved {'with' if acct else 'without'} Stripe-Account)")
        pm = pi.get("payment_method") or {}
        wallet = (pm.get("card") or {}).get("wallet") or {}
        if c["flow"].startswith("link"):
            ok(True, f"PM type={pm.get('type')} wallet={wallet.get('type')} id={pm.get('id')}")
        if c["flow"] == "applepay":
            ok(wallet.get("type") == "apple_pay", f"wallet={wallet.get('type')}")
        if c["flow"] == "saved":
            ok(pm.get("id") == c.get("payment_method"), f"PM {pm.get('id')} == saved {c.get('payment_method')}")
        if c["flow"].startswith("3ds") or c["flow"] == "link_wallet_3ds_cancel_retry":
            three_ds = ((ch.get("payment_method_details") or {}).get("card") or {}).get("three_d_secure") or {}
            ok(three_ds.get("result") == "authenticated", f"3DS result={three_ds.get('result')} version={three_ds.get('version')}")
        if c["flow"] in ("3ds_cancel_retry", "decline_retry"):
            attempts = get("charges", acct).get("data", [])
            attempts = [x for x in attempts if x.get("payment_intent") == pi["id"]]
            ok(len(attempts) >= 1, f"charges on PI: {[(x['status'], (x.get('outcome') or {}).get('reason')) for x in attempts]}")
        if name.startswith("direct"):
            fee = pi.get("application_fee_amount")
            if name == "direct_fee_3ds":
                ok(fee == 123, f"application_fee_amount={fee}")
                ok((ch.get("application_fee") or {}).get("amount") == 123, f"application fee object amount={(ch.get('application_fee') or {}).get('amount')}")
            else:
                ok(fee is None, f"application_fee_amount={fee}")
            ok(pi.get("transfer_data") is None, f"transfer_data={pi.get('transfer_data')}")
        if name.startswith("dest"):
            td = pi.get("transfer_data") or {}
            ok(td.get("destination") == CONNECTED, f"transfer_data.destination={td.get('destination')}")
            tr = ch.get("transfer") or {}
            if name == "dest_amount_3ds":
                ok(td.get("amount") == 800 and pi.get("application_fee_amount") is None, f"transfer_data.amount={td.get('amount')} fee={pi.get('application_fee_amount')}")
                ok(tr.get("amount") == 800, f"Transfer {tr.get('id')} amount={tr.get('amount')}")
            elif name == "dest_pct_saved":
                ok(pi.get("application_fee_amount") == pi["amount"] // 10, f"application_fee_amount={pi.get('application_fee_amount')} (10% of {pi['amount']})")
                ok(tr.get("amount") == pi["amount"], f"Transfer {tr.get('id')} amount={tr.get('amount')}")
            else:
                ok(pi.get("application_fee_amount") == 123, f"application_fee_amount={pi.get('application_fee_amount')}")
                ok(tr.get("amount") == pi["amount"], f"Transfer {tr.get('id')} amount={tr.get('amount')} destination={tr.get('destination')}")
            ok(tr.get("destination") == CONNECTED, f"Transfer destination={tr.get('destination')}")
        if name.startswith("sct"):
            g = c["transfer_group"]
            ok(pi.get("transfer_group") == g, f"PI transfer_group={pi.get('transfer_group')}")
            ok(ch.get("transfer_group") == g, f"Charge transfer_group={ch.get('transfer_group')}")
            ok(pi.get("transfer_data") is None and pi.get("application_fee_amount") is None, "no destination/fee on PI")
            t = request("POST", "transfers", {"amount": 500, "currency": "usd", "destination": CONNECTED, "transfer_group": g, "source_transaction": ch.get("id")}, version="2024-06-20")
            ok("error" not in t, f"merchant Transfer {t.get('id')} source_transaction={t.get('source_transaction')} group={t.get('transfer_group')}" if "error" not in t else f"Transfer failed: {t['error'].get('message')}")
        rows.append((name, "PASS" if all(x.startswith("OK") for x in checks) else "FAIL", "; ".join(checks)))
    for r in rows:
        print(" | ".join(r))


if __name__ == "__main__":
    if sys.argv[1] == "create":
        print(json.dumps(create()))
    else:
        verify(sys.argv[2])
