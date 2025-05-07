#### PaymentSheet
`PaymentSheet.ApplePayConfiguration.Handlers` completion-block based `authorizationResultHandler` has been replaced by an async equivalent. You can use the following example to quickly migrate completion-block based code:

```
// Before:
authorizationResultHandler: { result in
  return await withCheckedThrowingContinuation { continuation in
    let modifiedResult = // ...modify result (details omitted)
    continuation.resume(returning: modifiedResult)
  }
}

// After:
authorizationResultHandler: { result, completion in
  // ...modify result (details omitted)
  completion(result)
}
```

#### STPApplePayContext
ApplePayContextDelegate's `applePayContext:didCreatePaymentMethod:paymentInformation:completion:` has been replaced by an async equivalent. You can use the following example to quickly migrate completion-block based code:

```
// Before:
func applePayContext(
    _ context: STPApplePayContext,
    didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
    paymentInformation: PKPayment,
    completion: @escaping STPIntentClientSecretCompletionBlock
) {
  MyExampleNetworkManager.getPaymentIntent() { paymentIntentClientSecret in
    completion("my client secret", nil)
  }
}

// After:
func applePayContext(
    _ context: STPApplePayContext,
    didCreatePaymentMethod paymentMethod: StripeAPI.PaymentMethod,
    paymentInformation: PKPayment
) async throws -> String {
   return try await withCheckedThrowingContinuation { continuation in
     MyExampleNetworkManager.getPaymentIntent() { paymentIntentClientSecret, error in
        if let error {
          continuation.resume(throwing: error)
        } else {
          continuation.resume(returning: paymentIntentClientSecret)
        }
     }
   }
}
```

