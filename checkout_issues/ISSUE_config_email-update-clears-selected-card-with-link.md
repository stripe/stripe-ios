Summary:
With the guide's default Payment Element configuration, calling `updateEmail` after selecting a card clears the selected payment option and disables Pay. The same interaction preserves the card when Link is disabled in Payment Element. This happens before any confirmation attempt.

Repro:
1. Create a Session without server email, with US shipping collection and a $50 item. Use default Payment Element configuration.
2. Save a shipping address. Open Payment Element, choose Card, enter 4242, decline the optional Link signup, and continue. The merchant screen shows Visa •••• 4242 and enables Pay.
3. Enter `guide-fresh@example.com` in the merchant-owned email field and call `checkout.updateEmail`.
4. The payment-method button returns to “Select payment method” and Pay disables. No payment has been attempted and the controller/Session were not replaced.
5. Repeat with only `configuration.paymentElement?.linkConfiguration = .init(display: .never)` changed: the selected card remains.

Test:
`CheckoutGuideUITests.testEmailUpdatePreservesCard` failed on the real example-app UI: “Select payment method” replaced “Visa, •••• 4242.” `testEmailUpdatePreservesCardWithoutLink` passed in the same run, `/tmp/checkout-guide-final-flows.xcresult`. Both tests use the same raw Session parameters and customer interactions. The test field asserts the exact submitted email, so this is not a mistyped address or a keyboard covering Pay.

The separate missing-email recovery flow also captured the [reopened card form](images/card-form-after-email-update.png): card details remain, but Link signup is checked again and Continue is disabled until the customer declines it again. That recovery then completes payment. Compare [selection after the email update](images/email-update-clears-card.png) with the [Link-disabled control](images/email-update-no-link-control.png).

Elaboration:
The call path is `CheckoutController.updateEmail` → `performUnqueuedUpdate` → `updateForSessionChange` → `PaymentElement.apply`. That rebuilds the FlowController with `applyLoadResult`, then derives Checkout's payment option from the rebuilt form. Preserve a valid accepted card and the customer's Link opt-out across this rebuild.

This is an SDK behavior found while following the guide's supported editable-email instructions, not a request to document disabling Link as the integration recipe. The existing stale-Link-email report concerns a web handoff carrying the old email; this repro performs no Link web handoff and concerns loss of an accepted card selection during an ordinary update.
