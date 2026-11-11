Summary: A merchant displaying `checkout.session.totals.total.amount` shows a rounded COP total. A live Checkout Session for COP 12,345.67 produces the string `COP 12,346` on iOS 18.5 with an English US locale. The numeric amount remains correct.

Repro:

1. Create a Mobile Checkout Elements session with currency `cop` and one item priced at 1,234,567 minor units.
2. Load it with `CheckoutController` and read `session.totals.total`.
3. `minorUnitsAmount` is 1,234,567, but `amount` is `COP 12,346` instead of `COP 12,345.67`.

Test: `StripePaymentSheet/StripePaymentSheetTests/PaymentSheet/Checkout/CheckoutSupportedFlowsLiveTests.swift`, `testCOPFormattedTotalPreservesFractionalAmount` fails against the real test backend without mocked responses. `testJPYFormattedTotalRemainsWholeUnits` passes as a zero-decimal control.

Elaboration: `CheckoutClientAPIResponse.makeAmount` correctly converts COP minor units using Stripe's two-decimal currency override, then formats the result using Foundation's default COP precision of zero fractional digits. The resulting string rounds away the fractional amount. This report concerns the display string; it does not claim an incorrect confirmation amount or charge.
