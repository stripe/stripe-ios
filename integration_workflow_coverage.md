# Merchant workflow coverage — audit incomplete

A guide audit must ask whether a merchant can discover and complete a supported workflow, not just whether existing snippets compile. The earlier source/simulator checks and snippet audit did not establish this coverage. The seven previously reported issues were findings, not an exhaustive list.

## Confirmed omission: saving and returning customers

[Report](checkout_issues/ISSUE_integration-guide_missing-saved-payment-method-workflow.md).

The guide's `customer_email` example does not enable merchant saving. A Customer alone does not enable it either. The verified setup replaces `customer_email` with the server's Customer ID and adds:

```javascript
customer: customerId,
saved_payment_method_options: {
  payment_method_save: 'enabled',
},
```

The server must retain/reuse that Customer ID for later Sessions. The live test selects save consent, confirms payment, loads a fresh Session with the same Customer, and verifies the saved card is available to Payment Element. Three matrix cases passed in `/tmp/checkout-guide-saved-methods.xcresult`: email only, Customer only, and Customer plus save enabled with subsequent redisplay.

Do not describe `customer_creation: 'always'` as an equivalent working SDK setup based on general Checkout behavior alone. In the fourth initial live case, the Session had no Customer ID before confirmation, so the saving helper's prerequisite failed. The separate characterization passed in `/tmp/checkout-guide-save-new-customer.xcresult`: the server save flag is enabled, but the Customer ID is nil and the SDK consent gate is disabled. This needs separate investigation before claiming a working new-customer alternative or filing another SDK issue.

The old saved-card UI test passed because Checkout Playground injects the necessary Customer/save configuration. That validates the SDK path; it does not validate the guide's completeness.

## Coverage inventory

| Merchant task | Existing evidence | Documentation/workflow status |
| --- | --- | --- |
| Associate an app customer with a Stripe Customer | Real Customer-backed Session and saved-card reuse verified | Missing from core guide as an identity workflow; included in new report. |
| Offer saving with consent during payment | Live existing-Customer save and earlier checkbox UI test | Missing server setup; included in new report. |
| Redisplay on the next checkout | New live Session exposes the saved card | Missing same-Customer instructions; included in new report. |
| Migrate existing saved cards with different redisplay eligibility | Source/API reference distinguishes `always`, `limited`, `unspecified` | End-to-end migration and guide coverage not audited. Do not recommend broadening filters without checking intended consent semantics. |
| Let customers remove saved methods | Existing live UI test removes a card; playground enables the option | Guide contains no `payment_method_remove` guidance. Required explanation belongs in saved-method documentation; removal combinations not exhaustively audited. |
| Combine an existing Customer with automatic tax and updated addresses | Playground conditionally sends `customer_update` settings | Guide prerequisite matrix not audited; no new defect claimed yet. |
| Collect/edit checkout email separately from billing email | Live stale Link handoff and existing email tests | Known SDK issue; interaction with changing Customer identity not comprehensively audited. |
| Choose supported payment methods on the server | API/SDK paths exercised by earlier tests | Migration option mapping and all server parameter names not comprehensively audited. |
| Complete redirect/mandate/delayed-payment workflows | Existing targeted tests and live Link authentication; guide names delayed webhooks | No full merchant webhook/fulfillment or all-payment-method integration audit. |
| Use only selected Elements | Non-shipping Pay predicate repro and express-only UI tests | Some combinations checked; not an exhaustive workflow matrix. |
| Install and configure the preview from a fresh app/backend | Compiler fixtures and one real server payload | Fresh installation/version/access setup not audited end to end. |

This inventory records the gaps honestly. It is not evidence that the unreviewed rows are bug-free, nor a claim that every missing optional API setting merits its own issue.
