//
//  STPApplePayContextTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 2/20/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@testable import Stripe
@_spi(STP) @testable import StripeApplePay

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
                    PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                        _:didSelectShippingContact:handler:))))
        XCTAssertFalse(
            context.responds(
                to: #selector(
                    PKPaymentAuthorizationControllerDelegate.paymentAuthorizationController(
                        _:didSelectShippingContact:completion:))))

        // ...and forward the PassKit delegate method to its delegate
        let vc: PKPaymentAuthorizationController = PKPaymentAuthorizationController()
        let contact = PKContact()
        let shippingContactExpectation = expectation(
            description: "didSelectShippingContact forwarded")
        context.paymentAuthorizationController(
            vc, didSelectShippingContact: contact,
            handler: { _ in
                shippingContactExpectation.fulfill()
            })

        let method = PKShippingMethod()
        let shippingMethodExpectation = expectation(
            description: "didSelectShippingMethod forwarded")
        context.paymentAuthorizationController(
            vc, didSelectShippingMethod: method,
            handler: { _ in
                shippingMethodExpectation.fulfill()
            })
        waitForExpectations(timeout: 2, handler: nil)
    }

    // CB only supports euro presentment currency
    func testCartesBancairesRemovalNonEuro() {

        let sampleNonEuroCurrencies = [
            "usd",
            "gbp",
            "aud",
            "cad",
            "sgd",
            "mxn"
        ];

        StripeAPI.additionalEnabledApplePayNetworks = [.cartesBancaires]

        // Remove CB for non euro
        for currency in sampleNonEuroCurrencies {

            let request = StripeAPI.paymentRequest(withMerchantIdentifier: "foo", country: "US", currency: currency)
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"))
            ]

            XCTAssertFalse(request.supportedNetworks.contains(.cartesBancaires))

            // Check we aren't modifying the underlying list
            XCTAssert(StripeAPI.additionalEnabledApplePayNetworks.contains(.cartesBancaires))
        }

        // Keep CB for euro
        let request = StripeAPI.paymentRequest(withMerchantIdentifier: "foo", country: "US", currency: "EUR")
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"))
        ]

        XCTAssert(request.supportedNetworks.contains(.cartesBancaires))
    }

    // CB does not currently support any MIT transactions via Apple Pay
    func testCartesBancairesRemovalMIT() {
        StripeAPI.additionalEnabledApplePayNetworks = [.cartesBancaires]

        // Remove CB for .pending summary items
        let delegate = STPApplePayTestDelegateiOS11()
        let request = StripeAPI.paymentRequest(withMerchantIdentifier: "foo", country: "US", currency: "EUR")
        request.paymentSummaryItems = [
            PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00"), type: .pending)
        ]

        let context = STPApplePayContext(paymentRequest: request, delegate: delegate)
        XCTAssertNotNil(context)

        let networks = context!.paymentRequest.supportedNetworks
        XCTAssertFalse(networks.contains(.cartesBancaires))

        // Remove CB for PKRecurringPaymentSummaryItem
        if #available(iOS 15.0, *) {
            let delegate = STPApplePayTestDelegateiOS11()

            let recurringPayment = PKRecurringPaymentSummaryItem(label: "Total Payment", amount: NSDecimalNumber(string: "10.99"))
            recurringPayment.startDate = nil
            recurringPayment.intervalUnit = .month
            recurringPayment.intervalCount = 1
            var dateComponent = DateComponents()
            dateComponent.month = 5
            recurringPayment.endDate = Calendar.current.date(byAdding: dateComponent, to: Date())

            let request = StripeAPI.paymentRequest(withMerchantIdentifier: "foo", country: "US", currency: "EUR")
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00")),
                recurringPayment
            ]

            let context = STPApplePayContext(paymentRequest: request, delegate: delegate)
            XCTAssertNotNil(context)

            let networks = context!.paymentRequest.supportedNetworks
            XCTAssertFalse(networks.contains(.cartesBancaires))
        }

        // Remove CB for PKDeferredPaymentSummaryItem
        if #available(iOS 15.0, *) {
            let delegate = STPApplePayTestDelegateiOS11()

            let defferedPayment = PKDeferredPaymentSummaryItem(label: "Total Payment", amount: NSDecimalNumber(string: "10.99"))
            defferedPayment.deferredDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())!

            let request = StripeAPI.paymentRequest(withMerchantIdentifier: "foo", country: "US", currency: "EUR")
            request.paymentSummaryItems = [
                PKPaymentSummaryItem(label: "bar", amount: NSDecimalNumber(string: "1.00")),
                defferedPayment
            ]

            let context = STPApplePayContext(paymentRequest: request, delegate: delegate)
            XCTAssertNotNil(context)

            let networks = context!.paymentRequest.supportedNetworks
            XCTAssertFalse(networks.contains(.cartesBancaires))
        }

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
        payment.perform(#selector(setter:PKPaymentRequest.shippingContact), with: shipping)

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
}
