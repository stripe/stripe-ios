//
//  STPApplePayContextTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(InternalOnlyAPI) import StripePayments

@testable@_spi(InternalOnlyAPI) import Stripe
@testable@_spi(InternalOnlyAPI) import StripeApplePay
@testable@_spi(InternalOnlyAPI) import StripeCore
@testable@_spi(InternalOnlyAPI) import StripePaymentSheet
@testable@_spi(InternalOnlyAPI) import StripePaymentsUI

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

    func applePayContext(
        _ context: STPApplePayContext,
        didChangeCouponCode couponCode: String,
        handler completion: @escaping (PKPaymentRequestCouponCodeUpdate) -> Void
    ) {
        didChangeCouponCodeCalled = true
        completion(.init(errors: nil, paymentSummaryItems: [], shippingMethods: []))
    }

    var didSelectPaymentMethodCalled: Bool = false
    func applePayContext(
        _ context: STPApplePayContext,
        didSelectPaymentMethod paymentMethod: PKPaymentMethod,
        handler completion: @escaping (PKPaymentRequestPaymentMethodUpdate) -> Void
    ) {
        didSelectPaymentMethodCalled = true
        completion(PKPaymentRequestPaymentMethodUpdate(paymentSummaryItems: []))
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
    func testInitPreservesMerchantSelectedChinaUnionPayForZeroTotalAndRecurringRequests() {
        // Given a merchant-built request, with no intent available to the context
        for summaryItems in [
            [PKPaymentSummaryItem(label: "Total", amount: .zero, type: .pending)],
            [PKRecurringPaymentSummaryItem(label: "Subscription", amount: 10), PKPaymentSummaryItem(label: "Total", amount: 10)],
        ] {
            let request = PKPaymentRequest()
            request.merchantIdentifier = "merchant_id"
            request.countryCode = "CN"
            request.currencyCode = "CNY"
            request.supportedNetworks = [.visa, .chinaUnionPay]
            request.merchantCapabilities = [.capability3DS, .capabilityDebit]
            request.paymentSummaryItems = summaryItems

            // When the final request is handed to Stripe's context
            _ = STPApplePayContext(paymentRequest: request, delegate: nil)

            // Then usage filtering stays with the merchant, while Stripe adds EMV and preserves the debit restriction
            XCTAssertEqual(request.supportedNetworks, [.visa, .chinaUnionPay])
            XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .emv, .capabilityDebit])
        }
    }

    func testInitAddsEMVToMerchantBuiltChinaUnionPayRequest() {
        // Given a merchant-built request without the required EMV capability
        let request = PKPaymentRequest()
        request.merchantIdentifier = "merchant_id"
        request.countryCode = "CN"
        request.currencyCode = "CNY"
        request.supportedNetworks = [.visa, .chinaUnionPay]
        request.merchantCapabilities = [.capability3DS, .capabilityDebit]
        request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Test", amount: NSDecimalNumber(value: 1))]

        // When handing the final request to Stripe's Apple Pay context
        _ = STPApplePayContext(paymentRequest: request, delegate: nil)

        // Then EMV is added while preserving the merchant's funding restriction
        XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityEMV, .capabilityDebit])
    }

    func testInitRemovesEMVAfterMerchantRemovesChinaUnionPay() {
        // Given a Stripe-built request with UnionPay enabled
        let originalNetworks = StripeAPI.additionalEnabledApplePayNetworks
        StripeAPI.additionalEnabledApplePayNetworks = [.chinaUnionPay]
        defer { StripeAPI.additionalEnabledApplePayNetworks = originalNetworks }
        let request = StripeAPI.paymentRequest(withMerchantIdentifier: "merchant_id", country: "CN", currency: "CNY")
        XCTAssertTrue(request.merchantCapabilities.contains(.capabilityEMV))

        // When the merchant removes UnionPay before handing the request to Stripe
        request.supportedNetworks = [.visa]
        request.merchantCapabilities.insert(.capabilityCredit)
        request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Test", amount: NSDecimalNumber(value: 1))]
        _ = STPApplePayContext(paymentRequest: request, delegate: nil)

        // Then the stale EMV capability is removed and the funding restriction remains
        XCTAssertEqual(request.supportedNetworks, [.visa])
        XCTAssertEqual(request.merchantCapabilities, [.capability3DS, .capabilityCredit])
    }

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
        XCTAssertFalse(delegate.didChangeCouponCodeCalled)
        let couponCodeExpectation = expectation(description: "didChangeCouponCode forwarded")
        context.paymentAuthorizationController(vc, didChangeCouponCode: "coupon_123") { _ in
            couponCodeExpectation.fulfill()
        }
        wait(for: [couponCodeExpectation], timeout: 1)
        XCTAssertTrue(delegate.didChangeCouponCodeCalled)

        // 4) ..didSelectPaymentMethod.. delegate method
        XCTAssertTrue(
            context.responds(
                to: #selector(
                    PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                        _:
                        didSelectPaymentMethod:
                        handler:
                    ))
            )
        )
        XCTAssertFalse(delegate.didSelectPaymentMethodCalled)
        let paymentMethodExpectation = expectation(description: "didSelectPaymentMethod forwarded")
        context.paymentAuthorizationController(vc, didSelectPaymentMethod: PKPaymentMethod()) { _ in
            paymentMethodExpectation.fulfill()
        }
        wait(for: [paymentMethodExpectation], timeout: 1)
        XCTAssertTrue(delegate.didSelectPaymentMethodCalled)

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
