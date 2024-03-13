//
//  PaymentSheetConfigurationTests.swift
//  StripePaymentSheetTests
//

import XCTest

@testable@_spi(STP) @_spi(CustomerSessionBetaAccess) import StripePaymentSheet

class PaymentSheetConfigurationTests: XCTestCase {
    func testIsUsingBillingAddressCollection_Default() {
        let configuration = PaymentSheet.Configuration()
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_address_never() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .never
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_address_full() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.address = .full
        XCTAssert(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_email_never() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_email_full() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .always
        XCTAssert(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_name_never() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .never
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_name_full() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.name = .always
        XCTAssert(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_phone_never() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.phone = .never
        XCTAssertFalse(configuration.isUsingBillingAddressCollection())
    }

    func testIsUsingBillingAddressCollection_phone_full() {
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.phone = .always
        XCTAssert(configuration.isUsingBillingAddressCollection())
    }

    func testSTPPaymentMethodBillingDetailsToPaymentSheetBillingDetails() {
        var billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = "Jane Doe"
        billingDetails.email = "janedoe@test.com"
        billingDetails.phone = "+18885551234"
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.line1 = "123 Main Street"
        billingDetails.address?.line2 = ""
        billingDetails.address?.city = "San Francisco"
        billingDetails.address?.state = "California"
        billingDetails.address?.country = "US"

        let psBillingDetails: PaymentSheet.BillingDetails = billingDetails.toPaymentSheetBillingDetails()

        XCTAssertEqual(psBillingDetails.name, "Jane Doe")
        XCTAssertEqual(psBillingDetails.email, "janedoe@test.com")
        XCTAssertEqual(psBillingDetails.phone, "+18885551234")
        XCTAssertEqual(psBillingDetails.phoneNumberForDisplay, "+1 (888) 555-1234")
        XCTAssertEqual(psBillingDetails.address.line1, "123 Main Street")
        XCTAssertEqual(psBillingDetails.address.line2, "")
        XCTAssertEqual(psBillingDetails.address.city, "San Francisco")
        XCTAssertEqual(psBillingDetails.address.state, "California")
        XCTAssertEqual(psBillingDetails.address.country, "US")
    }
    func testReturnsEphemeralKey() {
        let deferredIntent = Intent.deferredIntent(elementsSession: STPElementsSession.emptyElementsSession,
                                                   intentConfig: .init(mode: .payment(amount: 500,
                                                                                      currency: "usd",
                                                                                      setupFutureUsage: .offSession,
                                                                                      captureMethod: .automatic),
                                                                       confirmHandler: {_, _, _ in
        }))
        let customerConfig = PaymentSheet.CustomerConfiguration(id: "cus_12345", ephemeralKeySecret: "ek_12345")
        let key = customerConfig.ephemeralKeySecretBasedOn(intent: deferredIntent)
        XCTAssertEqual(key, "ek_12345")
    }

    func testReturnsEphemeralKeyFromElements() {
        let deferredIntent = Intent.deferredIntent(elementsSession: STPElementsSession.elementsSessionWithCustomerSession(apiKey: "ek_11223344"),
                                                   intentConfig: .init(mode: .payment(amount: 500,
                                                                                      currency: "usd",
                                                                                      setupFutureUsage: .offSession,
                                                                                      captureMethod: .automatic),
                                                                       confirmHandler: {_, _, _ in
        }))
        let customerConfig = PaymentSheet.CustomerConfiguration(id: "cus_12345", customerSessionClientSecret: "cuss_12345")
        let key = customerConfig.ephemeralKeySecretBasedOn(intent: deferredIntent)
        XCTAssertEqual(key, "ek_11223344")
    }
}
