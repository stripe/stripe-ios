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

    func testLinkEmailUsesCheckoutSessionEmailPrecedence() {
        // Given a Checkout customer email and an optional higher-priority session email
        for sessionEmail in ["session@example.com", nil] {
            var json: [String: Any] = [
                "customer": ["id": "cus_checkout", "email": "customer@example.com"],
            ]
            json["customer_email"] = sessionEmail
            let session = CheckoutTestHelpers.makeSession(json).makePublicSession()

            // Then Link uses the same precedence as Checkout's session email
            XCTAssertEqual(
                CustomerProvider(checkoutSession: session).linkEmail(),
                sessionEmail ?? "customer@example.com"
            )
        }
    }

    func testLinkEmailUsesPrefetchedEmailThenElementsSessionAcrossIntegrations() {
        // Given an Elements Session email, including when no customer was configured locally
        var json = STPElementsSession._testValue(paymentMethodTypes: ["card"], customerSessionData: [:]).allResponseFields
        json[jsonDict: "customer"]?["email"] = "session@example.com"
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: json)!
        let providers: [CustomerProvider] = [
            .init(customer: nil),
            .init(customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test")),
            .init(customer: .init(id: "cus_legacy", ephemeralKeySecret: "ek_test")),
        ]
        for provider in providers {
            // Then missing or failed prefetches fall back to the session, and absent sources remain nil
            XCTAssertEqual(provider.linkEmail(elementsSession: elementsSession), "session@example.com")
            XCTAssertNil(provider.linkEmail())
        }

        // A retrieved legacy Customer email takes priority, preserving empty strings as before
        let legacyProvider = providers[2]
        XCTAssertEqual(legacyProvider.linkEmail(elementsSession: elementsSession, prefetchedEmail: "customer@example.com"), "customer@example.com")
        XCTAssertEqual(legacyProvider.linkEmail(elementsSession: elementsSession, prefetchedEmail: ""), "")
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
        XCTAssertEqual(sut.loadResult.customerProvider.customerID, "cus_checkout")
        XCTAssertEqual(sut.configuration.customer?.id, "cus_merchant")
    }

    func testLegacyCustomerUsesTheConfiguredEphemeralKey() {
        let provider = CustomerProvider(
            customer: .init(id: "cus_legacy", ephemeralKeySecret: "ek_test_legacy")
        )

        XCTAssertEqual(provider.ephemeralKeySecret(basedOn: nil), "ek_test_legacy")
    }

    func testCustomerSessionCredentialsUseTheLoadedAPIKey() {
        let provider = CustomerProvider(
            customer: .init(id: "cus_session", customerSessionClientSecret: "cuss_test_secret")
        )
        let elementsSession = STPElementsSession
            .elementsSessionWithCustomerSessionForPaymentSheet(apiKey: "ek_from_session")

        XCTAssertEqual(provider.ephemeralKeySecret(basedOn: elementsSession), "ek_from_session")
        XCTAssertNil(provider.ephemeralKeySecret(basedOn: nil))
    }

    func testCheckoutAndGuestCustomersDoNotUseElementsSessionEphemeralKeys() {
        let checkoutSession = CheckoutTestHelpers.makeSession().withCustomer().makePublicSession()
        let providers: [CustomerProvider] = [
            .init(customer: nil),
            .init(checkoutSession: checkoutSession),
        ]
        let elementsSession = STPElementsSession
            .elementsSessionWithCustomerSessionForPaymentSheet(apiKey: "ek_unrelated")

        for provider in providers {
            XCTAssertNil(provider.ephemeralKeySecret(basedOn: elementsSession))
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
}
