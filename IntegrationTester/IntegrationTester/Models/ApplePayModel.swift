//
//  ApplePayModel.swift
//  IntegrationTester
//
//  Created by David Estes on 2/18/21.
//

import Foundation
import Stripe
import PassKit

class MyApplePayBackendModel : NSObject, ObservableObject, STPApplePayContextDelegate {
  @Published var paymentStatus: STPPaymentStatus?
  @Published var lastPaymentError: Error?

  func pay() {
    // Configure a payment request
    let pr = StripeAPI.paymentRequest(withMerchantIdentifier: "merchant.stripetest.banana", country: "US", currency: "USD")
    
    // You'd generally want to configure at least `.postalAddress` here.
    // We don't require anything here, as we don't want to enter an address
    // in CI.
    pr.requiredShippingContactFields = []
    pr.requiredBillingContactFields = []
    
    // Configure shipping methods
    let firstClassShipping = PKShippingMethod(label: "First Class Mail", amount: NSDecimalNumber(string: "10.99"))
    firstClassShipping.detail = "Arrives in 3-5 days"
    firstClassShipping.identifier = "firstclass"
    let rocketRidesShipping = PKShippingMethod(label: "Rocket Rides courier", amount: NSDecimalNumber(string: "10.99"))
    rocketRidesShipping.detail = "Arrives in 1-2 hours"
    rocketRidesShipping.identifier = "rocketrides"
    pr.shippingMethods = [
      firstClassShipping,
      rocketRidesShipping
    ]
    
    // Build payment summary items
    // (You'll generally want to configure these based on the selected address and shipping method.
    pr.paymentSummaryItems = [
      PKPaymentSummaryItem(label: "A very nice computer", amount: NSDecimalNumber(string: "19.99")),
      PKPaymentSummaryItem(label: "Shipping", amount: NSDecimalNumber(string: "10.99")),
      PKPaymentSummaryItem(label: "Stripe Computer Shop", amount: NSDecimalNumber(string: "29.99"))
    ]
    
    // Present the Apple Pay Context:
    let applePayContext = STPApplePayContext(paymentRequest: pr, delegate: self)
    applePayContext?.presentApplePay()
  }
  
  
  func applePayContext(_ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod, paymentInformation: PKPayment, completion: @escaping STPIntentClientSecretCompletionBlock) {
    // When the Apple Pay sheet is confirmed, create a PaymentIntent on your backend from the provided PKPayment information.
    BackendModel.shared.fetchPaymentIntent(integrationMethod: .card) { pip in
      if let clientSecret = pip?.clientSecret {
        // Call the completion block with the PaymentIntent's client secret.
        completion(clientSecret, nil)
      } else {
        completion(nil, NSError())
      }
    }
  }
    
  func applePayContext(_ context: STPApplePayContext, willCompleteWithResult authorizationResult: PKPaymentAuthorizationResult, handler: @escaping (PKPaymentAuthorizationResult) -> Void) {
#if compiler(>=5.7)
      if #available(iOS 16.0, *) {
          authorizationResult.orderDetails = PKPaymentOrderDetails(
            orderTypeIdentifier: "com.myapp.order",
            orderIdentifier: "ABC123-AAAA-1111",
            webServiceURL: URL(string: "https://my-backend.example.com/apple-order-tracking-backend")!,
            authenticationToken: "abc123")
      }
#endif
      handler(authorizationResult)
  }
  
  func applePayContext(_ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?) {
    // When the payment is complete, display the status.
    self.paymentStatus = status
    self.lastPaymentError = error
  }
}
