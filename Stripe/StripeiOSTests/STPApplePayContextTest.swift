//
//  STPApplePayContextTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeApplePay
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class STPApplePayTestDelegateiOS11: NSObject, STPApplePayContextDelegate {
    var didChangeCouponCodeCalled: Bool = false
    func applePayContext(
        _ context: STPApplePayContext,
        didSelectShippingContact contact: PKContact,
        handler completion: @escaping (PKPaymentRequestShippingContactUpdate) -> Void
    ) {
        completion(PKPaymentRequestShippingContactUpdate())
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didSelect shippingMethod: PKShippingMethod,
        handler completion: @escaping (PKPaymentRequestShippingMethodUpdate) -> Void
    ) {
        completion(PKPaymentRequestShippingMethodUpdate())
    }

    @available(iOS 15.0, *)
    func applePayContext(
        _ context: STPApplePayContext,
        didChangeCouponCode couponCode: String,
        handler completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        didChangeCouponCodeCalled = true
        completion(.init(errors: nil, paymentSummaryItems: [], shippingMethods: []))
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCompleteWith status: STPPaymentStatus,
        error: Error?
    ) {
    }

    func applePayContext(
        _ context: STPApplePayContext,
        didCreatePaymentMethod paymentMethod: STPPaymentMethod,
        paymentInformation: PKPayment,
        completion: STPIntentClientSecretCompletionBlock
    ) {
    }
}

class STPApplePayContextTest: XCTestCase {
    func testInvalidPaymentRequest() {
        // An invalid request (missing payment summary items)...
        let request = StripeAPI.paymentRequest(
            withMerchantIdentifier: "foo",
            country: "US",
            currency: "USD"
        )
        // ...should cause ApplePayContext to be nil
        let applePayContext = STPApplePayContext(paymentRequest: request, delegate: STPApplePayTestDelegateiOS11())
        XCTAssertNil(applePayContext)
    }

    // MARK: - STPApplePayTestDelegateiOS11
    func testiOS11ApplePayDelegateMethodsForwarded() {
        // With a user that only implements iOS 11 delegate methods...
        let delegate = STPApplePayTestDelegateiOS11()
        let request = StripeAPI.paymentRequest(
            withMerchantIdentifier: "foo",
            country: "US",
            currency: "USD"
        )
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00")),
        ]
        let context = STPApplePayContext(paymentRequest: request, delegate: delegate)!

        // ...the context should respondToSelector appropriately...
        XCTAssertTrue(
            context.responds(
                to: #selector(
                    PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                        _:
                        didSelectShippingContact:
                        handler:
                    ))
            )
        )
        XCTAssertFalse(
            context.responds(
                to: #selector(
                    PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                        _:
                        didSelectShippingContact:
                        completion:
                    ))
            )
        )

        // ...and forward the PassKit delegate method to its delegate
        let vc: PKPaymentAuthorizationController = PKPaymentAuthorizationController()
        // 1) ..didSelectShippingContact.. delegate method
        let contact = PKContact()
        let shippingContactExpectation = expectation(
            description: "didSelectShippingContact forwarded"
        )
        context.paymentAuthorizationController(
            vc,
            didSelectShippingContact: contact,
            handler: { _ in
                shippingContactExpectation.fulfill()
            }
        )

        // 2) ..didSelectShippingMethod.. delegate method
        let method = PKShippingMethod()
        let shippingMethodExpectation = expectation(
            description: "didSelectShippingMethod forwarded"
        )
        context.paymentAuthorizationController(
            vc,
            didSelectShippingMethod: method,
            handler: { _ in
                shippingMethodExpectation.fulfill()
            }
        )

        // 3) ..didChangeCouponCode.. delegate method
        if #available(iOS 15.0, *) {
            XCTAssertFalse(delegate.didChangeCouponCodeCalled)
            let couponCodeExpectation = expectation(description: "didChangeCouponCode forwarded")
            context.paymentAuthorizationController(vc, didChangeCouponCode: "coupon_123") { _ in
                couponCodeExpectation.fulfill()
            }
            wait(for: [couponCodeExpectation], timeout: 1)
            XCTAssertTrue(delegate.didChangeCouponCodeCalled)
        } else {
            // Fallback on earlier versions
        }

        waitForExpectations(timeout: 2, handler: nil)
    }

    func testConvertsShippingDetails() {
        let delegate = STPApplePayTestDelegateiOS11()
        let request = StripeAPI.paymentRequest(
            withMerchantIdentifier: "foo",
            country: "US",
            currency: "USD"
        )
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00")),
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
        payment.perform(#selector(setter: PKPaymentRequest.shippingContact), with: shipping)

        let shippingParams = context!._shippingDetails(from: payment)
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

    // Tests stp_tokenParameters in StripeApplePay, not StripePayments
    func testStpTokenParameters() {
        let applePay = STPFixtures.applePayPayment()
        let applePayDict = applePay.stp_tokenParameters(apiClient: .shared)
        XCTAssertNotNil(applePayDict["pk_token"])
        XCTAssertEqual((applePayDict["card"] as! NSDictionary)["name"] as! String, "Test Testerson")
        XCTAssertEqual(applePayDict["pk_token_instrument_name"] as! String, "Master Charge")
    }
}
