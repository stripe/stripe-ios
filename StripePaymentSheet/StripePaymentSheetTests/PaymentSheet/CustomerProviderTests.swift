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
@_spi(STP) import StripeUICore
import XCTest

@MainActor
final class CustomerProviderTests: XCTestCase {

    func testNoCustomerHasNoIdentity() {
        let provider = CustomerProvider(customer: nil)

        XCTAssertFalse(provider.hasCustomer)
        XCTAssertNil(provider.customerID)
    }

    func testMerchantCustomerIdentity() {
        let customers: [PaymentSheet.CustomerConfiguration] = [
            .init(id: "cus_merchant", ephemeralKeySecret: "ek_test"),
            .init(id: "cus_merchant", customerSessionClientSecret: "cuss_test"),
        ]

        for customer in customers {
            let provider = CustomerProvider(customer: customer)

            XCTAssertTrue(provider.hasCustomer)
            XCTAssertEqual(provider.customerID, "cus_merchant")
        }
    }

    func testCheckoutCustomerIdentity() {
        let session = CheckoutTestHelpers.makeSession()
            .withCustomer(id: "cus_checkout")
            .makePublicSession()
        let provider = CustomerProvider(checkoutSession: session)

        XCTAssertTrue(provider.hasCustomer)
        XCTAssertEqual(provider.customerID, "cus_checkout")

        let guestProvider = CustomerProvider(
            checkoutSession: CheckoutTestHelpers.makeSession().makePublicSession()
        )
        XCTAssertFalse(guestProvider.hasCustomer)
        XCTAssertNil(guestProvider.customerID)
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

    func testSavedPaymentMethodsComeFromTheResolvedCustomerSource() {
        // Given different saved methods in each loading source
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: ["card"],
            customerSessionData: [:],
            paymentMethods: [
                ["id": "pm_1234", "type": "card", "created": 12345],
                ["id": "pm_4567", "type": "card", "created": 12345],
            ]
        )
        let checkoutSession = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_checkout",
                "payment_methods": [["id": "pm_checkout", "type": "card", "created": 12345]],
            ],
        ]).makePublicSession()
        let prefetchedPaymentMethod = STPPaymentMethod.decodedObject(
            fromAPIResponse: ["id": "pm_prefetched", "type": "card", "created": 12345]
        )!
        let cases: [(CustomerProvider, [String]?)] = [
            (.init(customer: nil), nil),
            (.init(customer: .init(id: "cus_legacy", ephemeralKeySecret: "ek_legacy")), ["pm_prefetched"]),
            (.init(customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_secret")), ["pm_1234", "pm_4567"]),
            (.init(checkoutSession: checkoutSession), ["pm_checkout"]),
        ]

        for (provider, expectedIDs) in cases {
            // When all sources are available, the resolved customer determines which one is used
            let paymentMethods = provider.savedPaymentMethods(
                elementsSession: elementsSession,
                prefetchedPaymentMethods: [prefetchedPaymentMethod]
            )

            // Then saved methods from another source cannot replace the resolved customer's methods
            XCTAssertEqual(paymentMethods?.map(\.stripeId), expectedIDs)
        }
    }

    func testLegacyEphemeralKeyCredentialsOnlyApplyToLegacyCustomers() {
        let legacyProvider = CustomerProvider(
            customer: .init(id: "cus_legacy", ephemeralKeySecret: "ek_test")
        )
        XCTAssertEqual(legacyProvider.legacyEphemeralKeyCredentials?.customerID, "cus_legacy")
        XCTAssertEqual(legacyProvider.legacyEphemeralKeyCredentials?.ephemeralKeySecret, "ek_test")

        let otherProviders: [CustomerProvider] = [
            .init(customer: nil),
            .init(customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test")),
            .init(checkoutSession: CheckoutTestHelpers.makeSession().withCustomer().makePublicSession()),
        ]
        for provider in otherProviders {
            XCTAssertNil(provider.legacyEphemeralKeyCredentials)
        }
    }

    func testCheckoutEmailPrefersTheCustomerEmail() {
        let session = CheckoutTestHelpers.makeSession([
            "customer": ["id": "cus_checkout", "email": "customer@example.com"],
            "customer_email": "fallback@example.com",
        ]).makePublicSession()

        XCTAssertEqual(CustomerProvider(checkoutSession: session).email, "customer@example.com")
    }

    func testCheckoutSessionFallsBackToTopLevelEmail() {
        let session = CheckoutTestHelpers.makeOpenSession(
            customerEmail: "fallback@example.com"
        ).makePublicSession()

        XCTAssertEqual(CustomerProvider(checkoutSession: session).email, "fallback@example.com")
    }

    func testMerchantCustomerDoesNotProvideAnEmail() {
        let provider = CustomerProvider(
            customer: .init(id: "cus_merchant", customerSessionClientSecret: "cuss_test")
        )

        XCTAssertNil(provider.email)
    }

    func testElementsSessionAuthenticationMatchesTheCustomerSource() {
        let checkoutSession = CheckoutTestHelpers.makeSession().withCustomer().makePublicSession()
        let cases: [(CustomerProvider, [String: String], Bool)] = [
            (.init(customer: nil), [:], false),
            (
                .init(customer: .init(id: "cus_legacy", ephemeralKeySecret: "ek_test")),
                ["legacy_customer_ephemeral_key": "ek_test"],
                false
            ),
            (
                .init(customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test")),
                ["customer_session_client_secret": "cuss_test"],
                true
            ),
            (.init(checkoutSession: checkoutSession), [:], false),
        ]

        for (provider, expectedParameters, usesCustomerSession) in cases {
            var parameters: [String: Any] = ["unrelated": "preserved"]
            provider.addElementsSessionParams(to: &parameters)

            var expectedParameters = expectedParameters
            expectedParameters["unrelated"] = "preserved"
            XCTAssertEqual(parameters as? [String: String], expectedParameters)
            XCTAssertEqual(provider.usesCustomerSession, usesCustomerSession)
        }
    }
}
