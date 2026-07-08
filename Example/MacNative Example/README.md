# Mac Native Example

A tiny AppKit SwiftPM executable that imports the local Stripe package on macOS,
fetches a PaymentIntent from the PaymentSheet example backend, and opens
`PaymentSheet`.

```bash
cd "Example/MacNative Example"
swift run MacNativeExample --smoke-test
swift run MacNativeExample
```
