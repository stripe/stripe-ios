Summary:
The Mobile Checkout Elements guide tells merchants to fulfill on `checkout.session.completed` without checking whether the Session is paid or making fulfillment safe to run more than once. It mentions delayed-payment success/failure events, but does not explain when to fulfill versus wait. Following this literally can deliver an order before a delayed payment succeeds, or deliver it again on another event/delivery.

Repro:
1. Follow “Fulfill the order”: “Listen for checkout.session.completed on your server to fulfill the order.” Implement fulfillment in that event handler.
2. Enable a delayed payment method, as the guide allows, and complete checkout. A completed Checkout Session is not necessarily a paid Session. The guide's next instruction to “also handle” asynchronous success/failure does not tell the merchant to withhold fulfillment while the payment is unpaid.
3. Deliver the same event twice, or handle the later success event for the same Session. Nothing in this section tells the merchant to identify the order by Session ID and atomically prevent repeated fulfillment.

Test:
The source omission is present in `partials/build-a-checkout-page.md` lines 1068–1075 at docs revision `de7108d190d32c9c7f82b6ae80e8be698f412931`. Compare Stripe's dedicated fulfillment instructions, which explicitly require checking `payment_status`, handling repeated/concurrent calls for the same Session, and recording fulfillment status. `CheckoutGuideUITests.testDelayedSEPA` also completed a real test-mode SEPA checkout using the guide's `AT321904300235473204` IBAN. The actual result was [`.completed(.unpaid)`](guide_repros/images/sepa-completed-unpaid.png). That test passed in `/tmp/checkout-guide-final-flows.xcresult`. Its Session uses a EUR item and explicitly enables SEPA for this test merchant; otherwise it uses the guide's configuration. No actual goods were delivered and no deployed merchant webhook handler was exercised in this audit.

Elaboration:
Explain that `.completed` / `checkout.session.completed` means the checkout flow completed, not necessarily that the payment succeeded. Fulfill paid or no-payment-required Sessions once; retain unpaid delayed payments as pending, fulfill on asynchronous success, and handle asynchronous failure without fulfillment. Deduplicate by Session/order identity across retries and event types. Link to an appropriate fulfillment implementation guide rather than only to the event type and signature-verification references.

This also clarifies what the client should do with the `paymentStatus` passed to the guide's `showOrderConfirmation` placeholder. The current section never explains its unpaid result.

The relevant source passages are:
- https://stripe.sourcegraphcloud.com/stripe-internal/mint@de7108d190d32c9c7f82b6ae80e8be698f412931/-/blob/pay-server/docs/content/payments/mobile/checkout-sessions/partials/build-a-checkout-page.md?L1068-1075
- https://stripe.sourcegraphcloud.com/stripe-internal/mint@d244b1c12216bec693ecdf5fa54886c49bbb41b2/-/blob/pay-server/docs/content/payments/checkout/partials/fulfillment/create-fulfillment-function.md?L1-16
- https://stripe.sourcegraphcloud.com/stripe-internal/mint@d244b1c12216bec693ecdf5fa54886c49bbb41b2/-/blob/pay-server/docs/content/payments/checkout/partials/fulfillment/create-payment-event-handler.md?L1-7
