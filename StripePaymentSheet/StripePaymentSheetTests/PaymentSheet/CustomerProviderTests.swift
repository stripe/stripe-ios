//
//  CustomerProviderTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/27/26.
//

@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripeCoreTestUtils
@testable @_spi(STP) import StripePayments
@testable @_spi(STP) import StripePaymentSheet
import StripePaymentsObjcTestUtils
@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class CustomerProviderTests: XCTestCase {

    func testPaymentSheetConfigurationWithoutCustomerUsesNoCustomer() {
        let configuration = PaymentSheet.Configuration()

        let provider = CustomerProvider(customer: configuration.customer)

        XCTAssertEqual(provider.source, .none)
        XCTAssertFalse(provider.hasCustomer)
        XCTAssertNil(provider.customerID)
        XCTAssertNil(provider.analyticValue)
    }

    func testLegacyEphemeralKeyCustomerProvidesCredentials() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(
            id: "cus_legacy",
            ephemeralKeySecret: "ek_test_legacy"
        )
        var parameters: [String: Any] = [:]

        let provider = CustomerProvider(customer: configuration.customer)
        provider.addElementsSessionParams(to: &parameters)

        XCTAssertEqual(provider.source, .legacyEphemeralKey)
        XCTAssertEqual(provider.customerID, "cus_legacy")
        XCTAssertEqual(provider.analyticValue, "legacy")
        XCTAssertEqual(
            provider.ephemeralKeySecret(basedOn: nil),
            "ek_test_legacy"
        )
        XCTAssertEqual(
            parameters["legacy_customer_ephemeral_key"] as? String,
            "ek_test_legacy"
        )
    }

    func testCustomerSessionCustomerProvidesCredentialsAndCapabilities() {
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(
            id: "cus_session",
            customerSessionClientSecret: "cuss_test_secret"
        )
        let elementsSession = STPElementsSession
            .elementsSessionWithCustomerSessionForPaymentSheet(apiKey: "ek_from_session")
        var parameters: [String: Any] = [:]

        let provider = CustomerProvider(customer: configuration.customer)
        provider.addElementsSessionParams(to: &parameters)

        XCTAssertEqual(provider.source, .customerSession)
        XCTAssertEqual(provider.customerID, "cus_session")
        XCTAssertEqual(provider.analyticValue, "customer_session")
        XCTAssertEqual(provider.customerSessionClientSecret, "cuss_test_secret")
        XCTAssertTrue(provider.supportsLinkSetupFutureUsage)
        XCTAssertEqual(
            provider.ephemeralKeySecret(basedOn: elementsSession),
            "ek_from_session"
        )
        XCTAssertEqual(
            parameters["customer_session_client_secret"] as? String,
            "cuss_test_secret"
        )
    }

    func testCheckoutSessionProvidesCustomerDataAndCapabilities() {
        let session = try! PaymentPagesAPIResponse.decode(
            fromAPIResponse: STPTestUtils.jsonNamed("CheckoutSession")!
        ).makePublicSession()
        let provider = CustomerProvider(checkoutSession: session)

        XCTAssertEqual(provider.source, .checkoutSession)
        XCTAssertEqual(provider.customerID, "cus_test123456")
        XCTAssertEqual(provider.email, "customer@example.com")
        XCTAssertEqual(provider.name, "Test Customer")
        XCTAssertEqual(provider.phone, "+15555555555")
        XCTAssertEqual(provider.analyticValue, "checkout_session")
        XCTAssertEqual(
            provider.saveConsent,
            .init(enabled: true, initiallyChecked: false)
        )
        XCTAssertEqual(
            provider.savedPaymentMethods(
                elementsSession: session.elementsSession,
                prefetchedPaymentMethods: nil
            )?.count,
            2
        )
        XCTAssertFalse(
            provider.allowsPaymentMethodRemoval(
                elementsSession: session.elementsSession
            )
        )
        XCTAssertTrue(
            provider.allowsPaymentMethodUpdate(
                elementsSession: session.elementsSession
            )
        )
        XCTAssertEqual(
            provider.savePaymentMethodConsentBehavior(
                elementsSession: session.elementsSession
            ),
            .paymentSheetWithCheckoutSessionPaymentMethodSaveEnabled
        )
    }

    func testCheckoutSessionFallsBackToTopLevelEmail() {
        let session = CheckoutTestHelpers.makeOpenSession(
            customerEmail: "fallback@example.com"
        ).makePublicSession()

        let provider = CustomerProvider(checkoutSession: session)

        XCTAssertFalse(provider.hasCustomer)
        XCTAssertEqual(provider.email, "fallback@example.com")
        XCTAssertEqual(provider.source, .checkoutSession)
    }

    func testLoadResultsRetainTheirOwnCustomerSnapshots() {
        let firstSession = CheckoutTestHelpers.makeSession()
            .withCustomer(id: "cus_first")
            .makePublicSession()
        let secondSession = CheckoutTestHelpers.makeSession()
            .withCustomer(id: "cus_second")
            .makePublicSession()

        let firstLoad = makeLoadResult(session: firstSession)
        let secondLoad = makeLoadResult(session: secondSession)

        XCTAssertEqual(firstLoad.customerProvider.customerID, "cus_first")
        XCTAssertEqual(secondLoad.customerProvider.customerID, "cus_second")
    }

    func testCheckoutCustomerIDKeysLocalDefaultPaymentMethodFallback() {
        let customerID = "cus_checkout_default"
        let session = CheckoutTestHelpers.makeSession()
            .withCustomer(id: customerID)
            .makePublicSession()
        let loadResult = makeLoadResult(session: session)
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId("pm_default"),
            forCustomer: customerID
        )
        defer {
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: customerID)
        }

        let selectedPaymentMethod = CustomerPaymentOption.selectedPaymentMethod(
            for: loadResult.customerProvider.customerID,
            elementsSession: session.elementsSession,
            surface: .paymentSheet
        )

        XCTAssertEqual(selectedPaymentMethod, .stripeId("pm_default"))
    }

    private func makeLoadResult(session: CheckoutController.Session) -> PaymentSheetLoader.LoadResult {
        return .init(
            intent: .checkout(session),
            elementsSession: session.elementsSession,
            savedPaymentMethods: session.customer?.paymentMethods ?? [],
            paymentMethodTypes: [.stripe(.card)],
            paymentMethodMessagingPromotionsHelper: nil,
            paymentMethodOrientation: .vertical,
            customerProvider: CustomerProvider(checkoutSession: session)
        )
    }
}
