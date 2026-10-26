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

    func testLoaderOrdersSavedMethodsUsingCheckoutCustomerDefault() {
        // Given different local defaults for the merchant and Checkout customers
        let merchantCustomerID = "cus_merchant_default"
        let checkoutCustomerID = "cus_checkout_default"
        var configuration = PaymentSheet.Configuration()
        configuration.customer = .init(id: merchantCustomerID, ephemeralKeySecret: "ek_test")
        let session = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": checkoutCustomerID,
                "payment_methods": [
                    ["id": "pm_merchant_default", "type": "card", "created": 12345],
                    ["id": "pm_checkout_default", "type": "card", "created": 12345],
                ],
            ],
        ]).makePublicSession()
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId("pm_merchant_default"),
            forCustomer: merchantCustomerID
        )
        CustomerPaymentOption.setDefaultPaymentMethod(
            .stripeId("pm_checkout_default"),
            forCustomer: checkoutCustomerID
        )
        defer {
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: merchantCustomerID)
            CustomerPaymentOption.setDefaultPaymentMethod(nil, forCustomer: checkoutCustomerID)
        }

        // When the loader orders the Checkout session's saved payment methods
        let paymentMethods = PaymentSheetLoader.filterSavedPaymentMethods(
            intent: .checkout(session),
            elementsSession: session.elementsSession,
            configuration: configuration,
            customerProvider: CustomerProvider(checkoutSession: session),
            prefetchedSPMs: nil
        )

        // Then the Checkout customer's default takes priority over the merchant's default
        XCTAssertEqual(paymentMethods.map(\.stripeId), ["pm_checkout_default", "pm_merchant_default"])
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
}
