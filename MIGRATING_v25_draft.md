#### PaymentSheet
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
