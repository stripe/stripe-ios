# Integration guide compiler repros

Source: the iOS sections of the Mobile Checkout Elements integration guide at docs commit `6389c38d3f1864c4ced050277be636f8f29f5adb`.

- `CheckoutPreviewImport.swift` copies the documented import and a minimal reference to its controller configuration.
- `CheckoutGuideAPISurface.swift` collects the guide's configuration, observation, Element presentation, embedding, and confirmation API calls. App-owned views and callbacks are supplied as scaffolding. It uses the branch's actual SPI to isolate remaining errors. It is a type-check fixture, not a runnable checkout app.

After building StripePaymentSheet for the simulator, run:

```sh
python3 guide_repros/check_swift_samples.py /path/to/Build/Products/Debug-iphonesimulator
```

The script verifies:

1. The documented `CheckoutSessionPreview` import fails to expose `CheckoutController`.
2. Replacing only that import with `InternalOnlyAPI` compiles. This is an isolation control, not a recommendation for the eventual merchant-facing import.
3. The guide's result switch fails in Swift 6 against the resilient framework.
4. Adding only `@unknown default` makes the Swift 6 scaffold compile.

The script exits successfully when both defects reproduce and both corrections compile. It uses an arm64 iOS 18.5 simulator target. The Swift 6 finding is specific to frameworks built with library evolution; it does not establish the same problem in SwiftPM builds without resilience.

Runtime guide checks are in `CheckoutSupportedFlowsLiveTests`: a copied Pay predicate blocks a real non-shipping purchase that the SDK successfully confirms, while the verbatim server creation payload loads and confirms successfully. The server helper uses the existing preview API version and test-host registered return URL.
