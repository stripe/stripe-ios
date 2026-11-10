"""Prints Link-related fields from CheckoutClient /init for a platform and a connected-account Session."""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from direct import request, session_params
import urllib.parse, urllib.request
from direct import encode
PK = os.environ["STRIPE_TEST_PUBLISHABLE_KEY"]


def client(path, params, account=None):
    pairs = []
    encode("", params, pairs)
    req = urllib.request.Request("https://api.stripe.com/v1/" + path, data=urllib.parse.urlencode(pairs).encode(), method="POST")
    req.add_header("Authorization", "Bearer " + PK)
    if account:
        req.add_header("Stripe-Account", account)
    try:
        with urllib.request.urlopen(req) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.loads(e.read())


def find(obj, path=""):
    if isinstance(obj, dict):
        for k, v in obj.items():
            p = f"{path}.{k}" if path else k
            if "link" in k.lower():
                print(" ", p, "=", json.dumps(v)[:300])
            find(v, p)
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            if isinstance(v, str) and v == "link":
                print(" ", f"{path}[{i}]", "= link")
            find(v, f"{path}[{i}]")


for label, account in [("platform", None), ("connected", "acct_1SGPAfLpAeuIWWTH")]:
    s = request("POST", "checkout/sessions", session_params(), account=account)
    r = client(f"checkout_client/{s['id']}/init", {"client_secret": s["client_secret"], "locale": "en-US", "timezone": "UTC", "adaptive_pricing": {"allowed": False}}, account)
    print(label, s["id"], r.get("error", {}).get("message") if "error" in r else "")
    find(r)
