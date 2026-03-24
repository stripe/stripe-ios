//
//  CustomerProviderTests.swift
//  StripePaymentSheetTests
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) @_spi(CheckoutSessionsPreview) import StripePaymentSheet
import StripePaymentsObjcTestUtils
import XCTest

final class CustomerProviderTests: XCTestCase {
    func testMake_withoutCustomerUsesNoneSource() {
        let configuration = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: "usd")) { _, _, _ in }

        let behavior = CustomerProvider.make(mode: .deferredIntent(intentConfig), configuration: configuration)

        XCTAssertEqual(behavior.source, .none)
        XCTAssertFalse(behavior.hasCustomer)
        XCTAssertFalse(behavior.hasConfigurationCustomer)
        XCTAssertNil(behavior.customerID)
        XCTAssertNil(behavior.analyticsValue)
        XCTAssertNil(behavior.ephemeralKeySecret(basedOn: nil))
    }

    func testMake_withLegacyEphemeralKeyUsesLegacySource() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "cus_123", ephemeralKeySecret: "ek_test_123")

        let behavior = CustomerProvider.make(mode: .paymentIntentClientSecret("pi_123_secret_456"), configuration: configuration)
        var params: [String: Any] = [:]
        behavior.addingElementsSessionCustomerParams(to: &params)

        XCTAssertEqual(behavior.source, .legacyEphemeralKey)
        XCTAssertTrue(behavior.hasCustomer)
        XCTAssertTrue(behavior.hasConfigurationCustomer)
        XCTAssertEqual(behavior.customerID, "cus_123")
        XCTAssertEqual(behavior.analyticsValue, "legacy")
        XCTAssertTrue(behavior.usesLegacyEphemeralKey)
        XCTAssertFalse(behavior.usesCustomerSession)
        XCTAssertEqual(behavior.ephemeralKeySecret(basedOn: nil), "ek_test_123")
        XCTAssertNil(behavior.customerSessionClientSecretIfAvailable)
        XCTAssertFalse(behavior.supportsLinkSetupFutureUsage)
        XCTAssertEqual(params["legacy_customer_ephemeral_key"] as? String, "ek_test_123")
    }

    func testMake_withCustomerSessionUsesCustomerSessionSource() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: "cus_123", customerSessionClientSecret: "cuss_123_secret_456")

        let behavior = CustomerProvider.make(mode: .setupIntentClientSecret("seti_123_secret_456"), configuration: configuration)
        var params: [String: Any] = [:]
        behavior.addingElementsSessionCustomerParams(to: &params)

        XCTAssertEqual(behavior.source, .customerSession)
        XCTAssertTrue(behavior.hasCustomer)
        XCTAssertEqual(behavior.customerID, "cus_123")
        XCTAssertEqual(behavior.analyticsValue, "customer_session")
        XCTAssertFalse(behavior.usesLegacyEphemeralKey)
        XCTAssertTrue(behavior.usesCustomerSession)
        XCTAssertEqual(behavior.customerSessionClientSecretIfAvailable, "cuss_123_secret_456")
        XCTAssertTrue(behavior.supportsLinkSetupFutureUsage)
        XCTAssertEqual(params["customer_session_client_secret"] as? String, "cuss_123_secret_456")

        let elementsSession = STPElementsSession.elementsSessionWithCustomerSessionForPaymentSheet(apiKey: "ek_from_elements_session")
        XCTAssertEqual(behavior.ephemeralKeySecret(basedOn: elementsSession), "ek_from_elements_session")
    }

    func testMake_withCheckoutSessionUsesCheckoutCustomerData() {
        var json = STPTestUtils.jsonNamed("CheckoutSession")!
        json["customer_managed_saved_payment_methods_offer_save"] = [
            "enabled": true,
            "status": "accepted",
        ]
        let checkoutSession = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        let behavior = CustomerProvider.make(mode: .checkoutSession(checkoutSession), configuration: PaymentSheet.Configuration())

        XCTAssertEqual(behavior.source, CustomerProvider.Source.checkoutSession)
        XCTAssertTrue(behavior.hasCustomer)
        XCTAssertEqual(behavior.customerID, "cus_test123456")
        XCTAssertEqual(behavior.analyticsValue, "checkout_session")
        XCTAssertEqual(behavior.checkoutCustomerEmail, "customer@example.com")
        XCTAssertEqual(behavior.checkoutCustomerName, "Test Customer")
        XCTAssertEqual(behavior.checkoutCustomerPhone, "+15555555555")
        XCTAssertEqual(behavior.checkoutSavedPaymentMethods.count, 2)
        XCTAssertEqual(behavior.checkoutSaveConsent?.enabled, true)
        XCTAssertEqual(behavior.checkoutSaveConsent?.initiallyChecked, true)
        XCTAssertNil(behavior.ephemeralKeySecret(basedOn: nil as STPElementsSession?))
    }

    func testMake_withCheckoutSessionFallsBackToTopLevelCustomerEmail() {
        var json = CheckoutTestHelpers.makeOpenSessionJSON()
        json["customer_email"] = "fallback@example.com"
        let checkoutSession = STPCheckoutSession.decodedObject(fromAPIResponse: json)!

        let behavior = CustomerProvider.make(mode: .checkoutSession(checkoutSession), configuration: PaymentSheet.Configuration())

        XCTAssertEqual(behavior.source, CustomerProvider.Source.checkoutSession)
        XCTAssertFalse(behavior.hasCustomer)
        XCTAssertNil(behavior.customerID)
        XCTAssertEqual(behavior.checkoutCustomerEmail, "fallback@example.com")
        XCTAssertNil(behavior.checkoutSaveConsent)
    }
}
