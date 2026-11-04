Summary:
The Mobile Checkout Elements integration guide's return-URL step tells iOS integrators to create and configure `EmbeddedPaymentElement.Configuration`. That object is not used by this integration. The actual return URL belongs to `CheckoutController.Configuration`, introduced afterward. A fresh reader is left with two configuration objects and no explanation of where the first goes.

Repro:
1. Follow the iOS guide's “Set up a return URL” step. The included `ios-return-url-embedded.md` ends with “Additionally, set the returnURL on your EmbeddedPaymentElement.Configuration object” and a snippet creating that object.
2. Continue to “Configure the controller.” It creates a different `CheckoutController.Configuration` and passes only that object to `CheckoutController`.
3. Follow “Add the Payment Element.” This creates `PaymentElement.Configuration` and assigns it to the controller configuration. There is no step that consumes the earlier `EmbeddedPaymentElement.Configuration`, for either the sheet or embedded path.

Test:
Read the raw included partial at docs revision `de7108d190d32c9c7f82b6ae80e8be698f412931`, lines 71–76, and assembled the guide in `Example/PaymentSheet Example/PaymentSheet Example/Checkout Guide/CheckoutGuideContainer.swift`. The assembly uses the controller's returnURL and has no consumer for the embedded configuration. This is a wrong-API instruction, not a demonstrated redirect failure: setup.md line 108 also tells readers to pass the URL to the controller, so following that later instruction can recover.

Elaboration:
Replace the shared EmbeddedPaymentElement-specific ending with CheckoutController configuration, or parameterize the included partial. Keep the custom-scheme registration and callback-forwarding instructions, which apply to this integration. This issue is separate from the preview SPI import defect and does not concern unfinished preview functionality.

See the guide source: https://stripe.sourcegraphcloud.com/stripe-internal/mint@de7108d190d32c9c7f82b6ae80e8be698f412931/-/blob/pay-server/docs/content/partials/mobile/ios-return-url-embedded.md?L71-76
