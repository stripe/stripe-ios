//
//  STPApplePayContextTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe

class STPApplePayTestDelegateiOS11: NSObject, STPApplePayContextDelegate {
  func applePayContext(
    _ context: STPApplePayContext, didSelectShippingContact contact: PKContact,
    handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
  ) {
    completion(PKPaymentRequestShippingContactUpdate())
  }

  func applePayContext(
    _ context: STPApplePayContext, didSelect shippingMethod: PKShippingMethod,
    handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
  ) {
    completion(PKPaymentRequestShippingMethodUpdate())
  }

  func applePayContext(
    _ context: STPApplePayContext, didCompleteWith status: STPPaymentStatus, error: Error?
  ) {
  }

  func applePayContext(
    _ context: STPApplePayContext, didCreatePaymentMethod paymentMethod: STPPaymentMethod,
    paymentInformation: PKPayment, completion: STPIntentClientSecretCompletionBlock
  ) {
  }
}

// MARK: - STPApplePayTestDelegateiOS11
class STPApplePayContextTest: XCTestCase {
  func testiOS11ApplePayDelegateMethodsForwarded() {
    // With a user that only implements iOS 11 delegate methods...
    let delegate = STPApplePayTestDelegateiOS11()
    let request = StripeAPI.paymentRequest(
      withMerchantIdentifier: "foo", country: "US", currency: "USD")
    request.paymentSummaryItems = [
      PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"))
    ]
    let context = STPApplePayContext(paymentRequest: request, delegate: delegate)!

    // ...the context should respondToSelector appropriately...
    XCTAssertTrue(
      context.responds(
        to: #selector(
          PKPaymentAuthorizationViewControllerDelegate.paymentAuthorizationViewController(
            _:didSelectShippingContact:handler:))))
    XCTAssertFalse(
      context.responds(
        to: #selector(
          PKPaymentAuthorizationViewControllerDelegate.paymentAuthorizationViewController(
            _:didSelectShippingContact:completion:))))

    // ...and forward the PassKit delegate method to its delegate
    let vc: PKPaymentAuthorizationViewController = PKPaymentAuthorizationViewController()
    let contact = PKContact()
    let shippingContactExpectation = expectation(description: "didSelectShippingContact forwarded")
    context.paymentAuthorizationViewController(
      vc, didSelectShippingContact: contact,
      handler: { _ in
        shippingContactExpectation.fulfill()
      })

    let method = PKShippingMethod()
    let shippingMethodExpectation = expectation(description: "didSelectShippingMethod forwarded")
    context.paymentAuthorizationViewController(
      vc, didSelect: method,
      handler: { _ in
        shippingMethodExpectation.fulfill()
      })
    waitForExpectations(timeout: 2, handler: nil)
  }

  func testConvertsShippingDetails() {
    let delegate = STPApplePayTestDelegateiOS11()
    let request = StripeAPI.paymentRequest(
      withMerchantIdentifier: "foo", country: "US", currency: "USD")
    request.paymentSummaryItems = [
      PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"))
    ]
    let context = STPApplePayContext(paymentRequest: request, delegate: delegate)

    let payment = STPFixtures.simulatorApplePayPayment()
    let shipping = PKContact()
    shipping.name = PersonNameComponentsFormatter().personNameComponents(from: "Jane Doe")
    shipping.phoneNumber = CNPhoneNumber(stringValue: "555-555-5555")
    let address = CNMutablePostalAddress()
    address.street = "510 Townsend St"
    address.city = "San Francisco"
    address.state = "CA"
    address.isoCountryCode = "US"
    address.postalCode = "94105"
    shipping.postalAddress = address
    payment?.perform(#selector(setter:PKPaymentRequest.shippingContact), with: shipping)

    let shippingParams = context!._shippingDetails(from: payment!)
    XCTAssertNotNil(shippingParams)
    XCTAssertEqual(shippingParams?.name, "Jane Doe")
    XCTAssertNil(shippingParams?.carrier)
    XCTAssertEqual(shippingParams?.phone, "555-555-5555")
    XCTAssertNil(shippingParams?.trackingNumber)

    XCTAssertEqual(shippingParams?.address.line1, "510 Townsend St")
    XCTAssertNil(shippingParams?.address.line2)
    XCTAssertEqual(shippingParams?.address.city, "San Francisco")
    XCTAssertEqual(shippingParams?.address.state, "CA")
    XCTAssertEqual(shippingParams?.address.country, "US")
    XCTAssertEqual(shippingParams?.address.postalCode, "94105")
  }
}
