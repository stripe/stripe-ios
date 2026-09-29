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

    func testSavedPaymentMethodsComeFromTheResolvedCustomerSource() {
        // Given different saved methods in each loading source
        let elementsSession = STPElementsSession
            .elementsSessionWithCustomerSessionForPaymentSheet(apiKey: "ek_from_session")
        let checkoutSession = CheckoutTestHelpers.makeSession([
            "customer": [
                "id": "cus_checkout",
                "payment_methods": [["id": "pm_checkout", "type": "card"]],
            ],
        ]).makePublicSession()
        let prefetchedPaymentMethod = STPPaymentMethod.decodedObject(
            fromAPIResponse: ["id": "pm_prefetched", "type": "card"]
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

    func testLegacyCustomerProvidesElementsSessionCredentials() {
        let provider = CustomerProvider(
            customer: .init(id: "cus_legacy", ephemeralKeySecret: "ek_test_legacy")
        )
        var parameters: [String: Any] = ["unrelated": "preserved"]

        provider.addElementsSessionParams(to: &parameters)

        XCTAssertEqual(parameters as? [String: String], [
            "unrelated": "preserved",
            "legacy_customer_ephemeral_key": "ek_test_legacy",
        ])
        XCTAssertEqual(provider.legacyEphemeralKeyCredentials?.customerID, "cus_legacy")
        XCTAssertEqual(provider.legacyEphemeralKeyCredentials?.ephemeralKeySecret, "ek_test_legacy")
        XCTAssertEqual(provider.ephemeralKeySecret(basedOn: nil), "ek_test_legacy")
        XCTAssertFalse(provider.usesCustomerSession)
    }

    func testCustomerSessionCredentialsUseTheLoadedAPIKey() {
        let provider = CustomerProvider(
            customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test_secret")
        )
        let elementsSession = STPElementsSession
            .elementsSessionWithCustomerSessionForPaymentSheet(apiKey: "ek_from_session")
        var parameters: [String: Any] = [:]

        provider.addElementsSessionParams(to: &parameters)

        XCTAssertEqual(parameters as? [String: String], ["customer_session_client_secret": "cuss_test_secret"])
        XCTAssertEqual(provider.ephemeralKeySecret(basedOn: elementsSession), "ek_from_session")
        XCTAssertNil(provider.ephemeralKeySecret(basedOn: nil))
        XCTAssertNil(provider.legacyEphemeralKeyCredentials)
        XCTAssertTrue(provider.usesCustomerSession)
    }

    func testCheckoutAndGuestCustomersDoNotProvideElementsSessionCredentials() {
        let checkoutSession = CheckoutTestHelpers.makeSession()
            .withCustomer()
            .makePublicSession()
        let providers: [CustomerProvider] = [
            .init(customer: nil),
            .init(checkoutSession: checkoutSession),
        ]
        let elementsSession = STPElementsSession
            .elementsSessionWithCustomerSessionForPaymentSheet(apiKey: "ek_unrelated")

        for provider in providers {
            var parameters: [String: Any] = ["unrelated": "preserved"]
            provider.addElementsSessionParams(to: &parameters)

            XCTAssertEqual(parameters as? [String: String], ["unrelated": "preserved"])
            XCTAssertNil(provider.ephemeralKeySecret(basedOn: elementsSession))
            XCTAssertNil(provider.legacyEphemeralKeyCredentials)
            XCTAssertFalse(provider.usesCustomerSession)
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

    func testCheckoutPermissionsUseTheCheckoutSession() {
        for canDetach in [true, false] {
            let session = CheckoutTestHelpers.makeSession([
                "customer": ["id": "cus_checkout", "can_detach_payment_method": canDetach],
            ]).makePublicSession()
            let provider = CustomerProvider(checkoutSession: session)

            XCTAssertEqual(provider.allowsPaymentMethodRemoval(elementsSession: .emptyElementsSession), canDetach)
            XCTAssertTrue(provider.allowsPaymentMethodUpdate(elementsSession: .emptyElementsSession))
        }
    }

    func testCustomerPermissionsUseTheElementsSession() {
        let provider = CustomerProvider(
            customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test")
        )
        for enabled in [true, false] {
            let elementsSession = STPElementsSession._testValue(
                paymentMethodTypes: ["card"],
                customerSessionData: [
                    "mobile_payment_element": [
                        "enabled": enabled,
                        "features": [
                            "payment_method_save": "enabled",
                            "payment_method_remove": "enabled",
                        ],
                    ],
                ]
            )

            XCTAssertEqual(provider.allowsPaymentMethodRemoval(elementsSession: elementsSession), enabled)
            XCTAssertEqual(provider.allowsPaymentMethodUpdate(elementsSession: elementsSession), enabled)
        }
    }

    func testCheckoutSaveConsentRequiresACustomerAndAnEnabledOffer() {
        for hasCustomer in [true, false] {
            for enabled in [true, false] {
                var overrides: [String: Any] = [
                    "customer_managed_saved_payment_methods_offer_save": [
                        "enabled": enabled,
                        "status": "not_accepted",
                    ],
                ]
                if hasCustomer {
                    overrides["customer"] = ["id": "cus_checkout"]
                }
                let provider = CustomerProvider(
                    checkoutSession: CheckoutTestHelpers.makeSession(overrides).makePublicSession()
                )

                XCTAssertEqual(
                    provider.savePaymentMethodConsentBehavior(elementsSession: .emptyElementsSession),
                    hasCustomer && enabled
                        ? .paymentSheetWithCheckoutSessionPaymentMethodSaveEnabled
                        : .paymentSheetWithCheckoutSessionPaymentMethodSaveDisabled
                )
            }
        }

        let providerWithoutOffer = CustomerProvider(
            checkoutSession: CheckoutTestHelpers.makeSession().withCustomer().makePublicSession()
        )
        XCTAssertEqual(
            providerWithoutOffer.savePaymentMethodConsentBehavior(elementsSession: .emptyElementsSession),
            .paymentSheetWithCheckoutSessionPaymentMethodSaveDisabled
        )
    }

    func testCustomerSaveConsentUsesTheElementsSession() {
        let provider = CustomerProvider(
            customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test")
        )
        XCTAssertEqual(provider.savePaymentMethodConsentBehavior(elementsSession: .emptyElementsSession), .legacy)

        for enabled in [true, false] {
            let elementsSession = STPElementsSession._testValue(
                paymentMethodTypes: ["card"],
                customerSessionData: [
                    "mobile_payment_element": [
                        "enabled": true,
                        "features": [
                            "payment_method_save": enabled ? "enabled" : "disabled",
                            "payment_method_remove": "enabled",
                        ],
                    ],
                ]
            )

            XCTAssertEqual(
                provider.savePaymentMethodConsentBehavior(elementsSession: elementsSession),
                enabled
                    ? .paymentSheetWithCustomerSessionPaymentMethodSaveEnabled
                    : .paymentSheetWithCustomerSessionPaymentMethodSaveDisabled
            )
        }
    }

    func testOnlyCustomerSessionSupportsLinkSetupFutureUsage() {
        let checkoutSession = CheckoutTestHelpers.makeSession().withCustomer().makePublicSession()
        let cases: [(CustomerProvider, Bool)] = [
            (.init(customer: nil), false),
            (.init(customer: .init(id: "cus_legacy", ephemeralKeySecret: "ek_test")), false),
            (.init(customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test")), true),
            (.init(checkoutSession: checkoutSession), false),
        ]

        for (provider, expected) in cases {
            XCTAssertEqual(provider.supportsLinkSetupFutureUsage, expected)
        }
    }

    func testCustomerAnalyticsIdentifyTheResolvedIntegration() {
        let checkoutSession = CheckoutTestHelpers.makeSession().makePublicSession()
        let cases: [(CustomerProvider, String?)] = [
            (.init(customer: nil), nil),
            (.init(customer: .init(id: "cus_legacy", ephemeralKeySecret: "ek_test")), "legacy"),
            (.init(customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test")), "customer_session"),
            (.init(checkoutSession: checkoutSession), "checkout_session"),
        ]

        for (provider, expected) in cases {
            XCTAssertEqual(provider.analyticValue, expected)
        }
    }

    func testLoadedCheckoutCustomerDoesNotReplaceMerchantConfiguration() async {
        // Given a merchant configuration and a separate Checkout customer
        await AddressSpecProvider.shared.loadAddressSpecs()
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.customer = .init(id: "cus_merchant", ephemeralKeySecret: "ek_test")
        let session = CheckoutTestHelpers.makeSession()
            .withCustomer(id: "cus_checkout")
            .makePublicSession()

        // When the payment surface accepts the Checkout load result
        let sut = EmbeddedPaymentElement(
            configuration: configuration,
            loadResult: makeLoadResult(session: session),
            analyticsHelper: ._testValue()
        )

        // Then consumers can use the loaded customer without mutating merchant input
        XCTAssertEqual(sut.savedPaymentMethodManager.customerProvider.customerID, "cus_checkout")
        XCTAssertEqual(sut.configuration.customer?.id, "cus_merchant")
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
