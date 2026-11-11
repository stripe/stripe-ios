Summary: After a merchant awaits `checkout.updateEmail(newEmail)`, Link's web handoff can still contain the initial email. The Checkout Session and Payment Element configuration expose the new email, but the Link URL parameters use the cached email from initialization.

Repro:

1. Create a session with card and Link enabled, without `customer_email` or a Customer email. Configure Payment Element and set `configuration.defaults.email` to email A.
2. Initialize `CheckoutController` and let its Link lookup for A complete.
3. Await `checkout.updateEmail(B)` before presenting a payment sheet. The session and Payment Element billing defaults now contain B.
4. On the Link web path, the generated `customerInfo.email` remains A.

Test: `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/Checkout/CheckoutSupportedFlowsLiveTests.swift`, `testUpdatedEmailReachesLinkWebParameters` fails after creating a real session and performing the real initial Link lookup. It verifies that the session and Payment Element configuration contain B, then invokes the same `LinkURLGenerator.linkParams` used by web presentation and observes A. No network responses are mocked. This test checks the handoff parameters; it does not open the web sheet or confirm a payment.

Elaboration: `updateEmail` refreshes local session state and Payment Element configuration but leaves `LinkAccountContext.shared.account` unchanged; the method already has a TODO for refreshing Link lookup. `LinkURLGenerator` prefers that cached account's email over the updated billing default. `PayWithLinkController` and `PayWithLinkWebController` do not refresh the lookup before generating the URL. This report does not claim that a payment is charged to the wrong account.
