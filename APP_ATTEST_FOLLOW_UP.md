# StripeAttest lifecycle review

Joyce — while changing Checkout confirmation to send inline PaymentMethod data, we found two reproducible lifecycle problems and some questions about the scope of assertion serialization. Could you help confirm the intended retry contract and the production verifier's ordering requirements before we change the abstraction?

## What prompted the review

The native Checkout integration currently creates a PaymentMethod, then confirms the Checkout Session with its ID. The refactor sends `payment_method_data` directly to the session's `/confirm` endpoint. That moves the request consuming the assertion from PaymentMethod creation to Checkout confirmation.

The refactor moves `ConfirmationChallenge.complete()` accordingly: it runs after the awaited `/confirm` HTTP request returns or throws, before authentication or polling. This follows `StripeAttest.assert()`'s documented requirement to complete the handle after the network request succeeds or fails. The underlying attestation implementation is unchanged.

An existing Checkout TODO also suggested a `withRadarOptions` helper and noted that async completion does not actually await release. Investigating that TODO exposed the findings below.

## Reproduced with the existing mocks

### Reusing an AttestationChallenge after completion returns the consumed assertion

`AttestationChallenge.fetchAssertion()` caches `assertionTask`; `complete()` clears neither that task nor `assertionHandle`.

A diagnostic test using `MockAppAttestService` and `MockAttestBackend` performed:

1. Fetch an assertion and validate it with the mock backend.
2. Complete the handle.
3. Fetch an assertion from the same challenge and validate it again.

The second fetch returned the same assertion bytes, and the mock backend rejected reuse with `No challenge available`.

Checkout can retain the same challenge after an HTTP confirmation failure: without a session response, the controller does not commit refreshed session state and reload the element. That makes the challenge's retry semantics relevant even though a controller rejects overlapping confirms.

Is `AttestationChallenge` intended to be single-use, with callers responsible for replacing it after every attempt? If so, that contract needs to be explicit and enforced in retry paths. Otherwise, completion needs to invalidate the consumed assertion while preserving any intentional deduplication within an attempt.

### Completing an old handle can release a newer holder

`AssertionHandle.complete()` has no idempotence or ownership check. `StripeAttest.assertionCompleted()` unconditionally clears `assertionInProgress` and resumes a waiter.

A second diagnostic test reproduced:

1. Acquire A, complete A, and allow its release to finish.
2. Acquire B and leave it unfinished.
3. Complete A again and allow that release to finish.
4. Acquire C successfully while B is still unfinished.

A stale handle can therefore break the intended exclusivity. Release should be idempotent and apply only to the acquisition that the handle owns.

These were temporary diagnostic tests, not permanent regression coverage. They demonstrate local/mock behavior; neither reproduces a production verifier failure.

## Completion contract

`ConfirmationChallenge.complete()` is async, but `AssertionHandle.complete()` starts an unstructured `Task` to call `assertionCompleted()`. Awaiting the outer method does not establish that release has finished.

If completion remains async, it should await the actual release. That fixes the contract but does not by itself address cached assertion reuse or stale-handle release. The comment on `AttestationChallenge.complete()` also says “after signing request,” whereas `StripeAttest.assert()` requires completion after the network request; those should describe the same boundary.

## Questions about serialization

The production verifier was not inspected during this review. The mock enforces an increasing counter, consistent with [Apple's validation guidance](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server). Before choosing a replacement API, we need to establish:

- **What ordering does the verifier require?** What is the scope of counter tracking and challenge consumption? Can independently generated assertions be accepted out of order, or must requests using a key be serialized?
- **What happens after a timeout?** Holding the slot through a successful HTTP response orders requests through that coordinator. After a timeout, the server may still be processing the request. What recovery or state synchronization is supported before the next assertion-bearing request?
- **Should coordination be shared by key?** Each `STPAPIClient` owns its own `StripeAttest`, but the persisted key ID is namespaced by publishable key and optional connected account. Separate API clients can therefore use the same key with independent coordinators. If ordering is required per key, the current scope appears insufficient.

The Checkout controller's confirmation guard only prevents overlapping confirms on that controller. Link lookup and signup also acquire assertions, and other controllers can make requests. Serialization requirements therefore cannot be settled by assuming Checkout confirms are serial.

Two additional areas need an audit; neither was reproduced as a failure in this review:

- `assertionCompleted()` clears the busy flag before resuming a waiter. Check whether a new caller can acquire the slot before that waiter resumes, allowing both to proceed.
- Check cancellation while queued or after acquisition, generation failures, and abandoned handles for stranded slots or incorrect release.

## Proposed direction

First establish the verifier contract and fix the two reproduced lifecycle issues, with permanent regression tests. If request serialization is required, a scoped API could make the required lifetime explicit:

```swift
try await confirmationChallenge.withRadarOptions(for: type) { radarOptions in
    // Build and await the HTTP request using radarOptions.
}
```

The helper would own acquisition through the HTTP response or error, then release before authentication or polling. It needs an explicit gate held across suspension points, shared at the scope required by the verifier. A closure or actor alone does not provide that guarantee, and wrapping the current implementation would retain its lifecycle bugs.

If the verifier permits concurrent requests with fresh assertions, a fresh-assertion API may be simpler. The choice should follow the server contract.

Validation should cover reuse after completion, duplicate completion, actual awaited release, waiter handoff and cancellation, Link requests, multiple API clients sharing a key, and recovery after uncertain network outcomes. Physical-device verification is also needed: the Checkout refactor's live API tests and simulator recordings do not validate real App Attest behavior.

## Source references

- [StripeAttest.swift](https://github.com/stripe/stripe-ios/blob/60e6f194a1227f3f6edb6076a08cef4d99b33ea7/StripeCore/StripeCore/Source/Attestation/StripeAttest.swift): acquisition, queue handoff, and handle completion.
- [AttestationChallenge.swift](https://github.com/stripe/stripe-ios/blob/60e6f194a1227f3f6edb6076a08cef4d99b33ea7/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/ConfirmationChallenge/AttestationChallenge.swift): cached task/handle and retry lifecycle.
- [ConfirmationChallenge.swift](https://github.com/stripe/stripe-ios/blob/60e6f194a1227f3f6edb6076a08cef4d99b33ea7/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/ConfirmationChallenge/ConfirmationChallenge.swift): Radar options and async completion wrapper.
- [Checkout+Confirm.swift](https://github.com/stripe/stripe-ios/blob/60e6f194a1227f3f6edb6076a08cef4d99b33ea7/StripePaymentSheet/StripePaymentSheet/Source/PaymentSheet/Checkout/Checkout%2BConfirm.swift): controller confirmation guard and HTTP completion boundary.
- [STPAPIClient+Link.swift](https://github.com/stripe/stripe-ios/blob/60e6f194a1227f3f6edb6076a08cef4d99b33ea7/StripePaymentSheet/StripePaymentSheet/Source/Internal/API%20Bindings/Link/STPAPIClient%2BLink.swift): lookup/signup assertion callers.
