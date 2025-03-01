#### PaymentSheet
`PaymentSheet.IntentConfiguration.confirmHandler` has been replaced by an async equivalent. You can use the following example to quickly migrate completion-block based code:

```
Before:
PaymentSheet.IntentConfiguration(
  mode: .payment(amount: 1000),
  currency: "USD"
) { [weak self] paymentMethod, shouldSavePaymentMethod, intentCreationCallback in
  MyExampleNetworkManager.fetchIntentClientSecret() { result in
    switch result {
      case .success(let clientSecret):
        intentCreationCallback(.success(clientSecret))
      case .failure(let error):
	intentCreationCallback(.failure(error))
    }
  }
}

// After:
PaymentSheet.IntentConfiguration(
  mode: .payment(amount: 1000),
  currency: "USD"
) { [weak self] paymentMethod, shouldSavePaymentMethod in
  try await withCheckedThrowingContinuation() { continuation in
    MyExampleNetworkManager.fetchIntentClientSecret() { result in
      continuation.resume(with: result)
    }
  }
}
```


`PaymentSheet.ExternalPaymentMethodConfiguration` completion-block based confirm handler has been replaced by an async equivalent. You can use the following example to quickly migrate completion-block based code:

```
Before:
externalPaymentMethodConfiguration = .init(
  externalPaymentMethods: externalPaymentMethods
) { [weak self] externalPaymentMethodType, billingDetails, completion in
    ...
    completion(result)
  }
}

After:
externalPaymentMethodConfiguration = .init(
    externalPaymentMethods: externalPaymentMethods
) { [weak self] externalPaymentMethodType, billingDetails in
  return await withCheckedContinuation() { continuation in
      ...
      continuation.resume(returning: result)
    }
  }
}
```
