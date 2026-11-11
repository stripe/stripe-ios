Summary:
The iOS guide's Pay-button snippets enable confirmation without the required checkout email. A merchant who chooses the documented “collect or edit an email” path can copy the complete button implementation, leave email empty, enter shipping/card details, and get an enabled Pay button followed by a generic confirmation error.

Repro:
1. Follow “If you need to collect or edit an email”: omit `customer_email` and do not supply a Customer with an email. Start without an initial email and add a merchant-owned email field.
2. Use the guide's default Shipping Address Element and Payment Element configurations and copy its SwiftUI Pay button or UIKit `updatePayButton`.
3. Leave checkout email empty, save a shipping address, and select a valid test card. Pay enables because the sample checks only `isUpdating`, `paymentOption`, and `shippingAddress`.
4. Tap Pay. Following the guide's error handler displays “An error has occurred confirming the Checkout Session.” It does not tell the customer to supply the missing email.

Test:
Reproduced in the fresh `CheckoutGuideContainer` example-app route with `STP_CHECKOUT_GUIDE=email`. The first phase of `CheckoutGuideUITests.testEditableEmail` verifies the button is enabled before supplying email and captures the actual confirmation error. The test then supplies a valid email, reselects the payment method when prompted, and completes payment; the full test passed in `/tmp/checkout-guide-final-flows.xcresult`. This uses the guide-derived server parameters with `customer_email` removed, not a playground fixture with an injected email or Customer.

Elaboration:
The email section correctly says a valid email is required before confirmation. The complete Pay-button snippets contradict that requirement. Include email readiness in those snippets, distinguish checkout email from payment-method billing email, and show how validation/update failures affect the button. Preserve the existing instruction to disable while an update is pending.

This is distinct from the existing unconditional-shipping issue: this scenario collects shipping exactly as the main example does. It is also distinct from saving payment methods to a Customer.

Sources at docs revision `de7108d190d32c9c7f82b6ae80e8be698f412931`: `partials/collect-customer-email.md` lines 13–15 and 25–52; `partials/build-a-checkout-page.md` lines 242–247 and 967–978.
