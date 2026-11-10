"""Creates a test-mode mobile_elements Checkout Session directly on a connected account (direct charge)."""
import json, os, sys, urllib.parse, urllib.request

# Test-mode secret key for the playground US platform (acct_1HvTI7Lu5o3P18Zp).
# See stripe-internal/sandbox-apps stripe-mobile-playground-backend/server-keys.js.
SK = os.environ["STRIPE_TEST_SECRET_KEY"]


def encode(prefix, value, out):
    if isinstance(value, dict):
        for k, v in value.items():
            encode(f"{prefix}[{k}]" if prefix else k, v, out)
    elif isinstance(value, list):
        for i, v in enumerate(value):
            encode(f"{prefix}[{i}]", v, out)
    else:
        out.append((prefix, str(value).lower() if isinstance(value, bool) else str(value)))


def request(method, path, params=None, account=None, version="2026-08-26.preview"):
    pairs = []
    encode("", params or {}, pairs)
    data = urllib.parse.urlencode(pairs)
    url = "https://api.stripe.com/v1/" + path
    if method == "GET" and data:
        url += "?" + data
    req = urllib.request.Request(url, data=data.encode() if method == "POST" else None, method=method)
    req.add_header("Authorization", "Bearer " + SK)
    req.add_header("Stripe-Version", version)
    if account:
        req.add_header("Stripe-Account", account)
    try:
        with urllib.request.urlopen(req) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.loads(e.read())


def session_params(extra=None):
    params = {
        "ui_mode": "mobile_elements",
        "currency": "usd",
        "allowed_payment_method_types": ["card"],
        "items": [{"type": "one_time_price", "one_time_price": {"items": [{"price_data": {"currency": "usd", "unit_amount": 1000, "product_data": {"name": "Test"}}, "quantity": 1}]}}],
        "customer_email": "test@example.com",
    }
    params.update(extra or {})
    return {k: v for k, v in params.items() if v is not None}


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "accounts":
        r = request("GET", "accounts", {"limit": 10}, version="2024-06-20")
        for a in r.get("data", []):
            print(a["id"], a.get("type"), a.get("country"), a.get("charges_enabled"), a.get("controller", {}).get("type"))
        if "error" in r:
            print(r["error"])
    elif cmd == "create":
        account = None if sys.argv[2] == "-" else sys.argv[2]
        extra = json.loads(sys.argv[3]) if len(sys.argv) > 3 else None
        r = request("POST", "checkout/sessions", session_params(extra), account=account)
        print(json.dumps({k: r.get(k) for k in ("id", "client_secret", "error")}))
    elif cmd == "get":
        path, account = sys.argv[2], (sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] != "-" else None)
        print(json.dumps(request("GET", path, account=account, version="2024-06-20"), indent=1))
