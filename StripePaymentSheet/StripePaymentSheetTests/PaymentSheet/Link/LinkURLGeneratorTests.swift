//
//  LinkURLGeneratorTests.swift
//  StripePaymentSheetTests
//

import Foundation

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePayments
@_spi(STP) @_spi(PaymentMethodOptionsSetupFutureUsagePreview) @testable import StripePaymentSheet

import OHHTTPStubs
import OHHTTPStubsSwift
import StripeCoreTestUtils
import XCTest

class LinkURLGeneratorTests: XCTestCase {
    let testParams = LinkURLParams(paymentObject: .link_payment_method,
                                   publishableKey: "pk_test_123",
                                   stripeAccount: "acct_1234",
                                   paymentUserAgent: "test",
                                   merchantInfo: LinkURLParams.MerchantInfo(businessName: "Test test", country: "US"),
                                   customerInfo: LinkURLParams.CustomerInfo(country: "US", email: "test@example.com"),
                                   paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                   experiments: [:],
                                   flags: [:],
                                   loggerMetadata: [:],
                                   locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                   intentMode: .payment,
                                   setupFutureUsage: false,
                                   linkFundingSources: [.card],
                                   clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .standard, paymentMethodSelectionFlow: .merchantSpecified)
    )

    func testURLCreation() {
        let url = try! LinkURLGenerator.url(params: testParams)

        // Build expected JSON with dynamic SDK version
        let expectedJSON: [String: Any] = [
            "clientAttributionMetadata": [
                "elements_session_config_id": "123",
                "merchant_integration_source": "elements",
                "merchant_integration_subtype": "mobile",
                "merchant_integration_version": "stripe-ios/\(StripeAPIConfiguration.STPSDKVersion)",
                "payment_intent_creation_flow": "standard",
                "payment_method_selection_flow": "merchant_specified",
            ],
            "customerInfo": [
                "country": "US",
                "email": "test@example.com",
            ],
            "experiments": [:] as [String: Any],
            "flags": [:] as [String: Any],
            "integrationType": "mobile",
            "intentMode": "payment",
            "linkFundingSources": ["CARD"],
            "locale": "en-US",
            "loggerMetadata": [:] as [String: Any],
            "merchantInfo": [
                "businessName": "Test test",
                "country": "US",
            ],
            "path": "mobile_pay",
            "paymentInfo": [
                "amount": 100,
                "currency": "USD",
            ],
            "paymentObject": "link_payment_method",
            "paymentUserAgent": "test",
            "publishableKey": "pk_test_123",
            "setupFutureUsage": false,
            "stripeAccount": "acct_1234",
        ]

        let jsonData = try! JSONSerialization.data(withJSONObject: expectedJSON, options: [.sortedKeys])
        let expectedBase64 = jsonData.base64EncodedString()
        let expectedURLString = "https://checkout.link.com/#\(expectedBase64)"

        XCTAssertEqual(url.absoluteString, expectedURLString)
    }

    func testURLCreationRegularUnicode() {
        var params = testParams
        params.customerInfo.email = "유니코드"
        _ = try! LinkURLGenerator.url(params: params)
        // Just make sure it doesn't fail
    }

    func testURLParamsFromConfig() async {
        let config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .emptyElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .link_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "US"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "US", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                           experiments: [:],
                                           flags: [:],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: false,
                                           linkFundingSources: [],
                                           clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .deferred, paymentMethodSelectionFlow: .automatic))

        XCTAssertEqual(params, expectedParams)
    }

    func testURLParamsPaymentMethodOptionsSetupFutureUsage() {
        var config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.link: .offSession]))) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .linkElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .link_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "US"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "US", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                           experiments: [:],
                                           flags: ["link_passthrough_mode_enabled": false],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: true,
                                           linkFundingSources: [.card],
                                           clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .deferred, paymentMethodSelectionFlow: .automatic))

        XCTAssertEqual(params, expectedParams)
    }

    func testURLParamsPaymentMethodOptionsSetupFutureUsage_passthrough() {
        var config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.card: .offSession]))) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .linkPassthroughElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .card_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "US"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "US", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                           experiments: [:],
                                           flags: ["link_passthrough_mode_enabled": true],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: true,
                                           linkFundingSources: [.card],
                                           clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .deferred, paymentMethodSelectionFlow: .automatic))

        XCTAssertEqual(params, expectedParams)
    }

    func testURLParamsTopLevelSFUPaymentMethodOptionsSetupFutureUsageNone() {
        var config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", setupFutureUsage: .offSession, paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.link: .none]))) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .linkElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .link_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "US"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "US", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                           experiments: [:],
                                           flags: ["link_passthrough_mode_enabled": false],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: false,
                                           linkFundingSources: [.card],
                                           clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .deferred, paymentMethodSelectionFlow: .automatic))

        XCTAssertEqual(params, expectedParams)
    }

    func testURLParamsTopLevelSFUPaymentMethodOptionsSetupFutureUsageNone_passthrough() {
        var config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "USD", setupFutureUsage: .offSession, paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: [.card: .none]))) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .linkPassthroughElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .card_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "US"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "US", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "USD", amount: 100),
                                           experiments: [:],
                                           flags: ["link_passthrough_mode_enabled": true],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: false,
                                           linkFundingSources: [.card],
                                           clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .deferred, paymentMethodSelectionFlow: .automatic))

        XCTAssertEqual(params, expectedParams)
    }

    func testURLParamsWithCBC() {
        var config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "EUR")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        config.defaultBillingDetails.address.country = "FR"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .cbcElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .link_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "FR"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "FR", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "EUR", amount: 100),
                                           experiments: [:],
                                           flags: ["cbc_in_link_popup": true,
                                                   "disable_cbc_in_link_popup": false,
                                                  ],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: false,
                                           cardBrandChoice: LinkURLParams.CardBrandChoiceInfo(isMerchantEligibleForCBC: true, stripePreferredNetworks: ["cartes_bancaires"], supportedCobrandedNetworks: ["cartes_bancaires": true]),
                                           linkFundingSources: [],
                                           clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .deferred, paymentMethodSelectionFlow: .automatic)
        )

        XCTAssertEqual(params, expectedParams)
    }

    func testURLParamsWithCardFundingSource() {
        var config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "EUR")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        config.defaultBillingDetails.address.country = "FR"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .linkPassthroughElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .card_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "FR"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "FR", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "EUR", amount: 100),
                                           experiments: [:],
                                           flags: ["link_passthrough_mode_enabled": true],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: false,
                                           cardBrandChoice: nil,
                                           linkFundingSources: [.card],
                                           clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .deferred, paymentMethodSelectionFlow: .automatic)
        )

        XCTAssertEqual(params, expectedParams)
    }

    func testURLParamsWithCardAndBankFundingSources() {
        var config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "EUR")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        config.defaultBillingDetails.address.country = "FR"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        // Create a session ID
        AnalyticsHelper.shared.generateSessionID()
        let sessionID = AnalyticsHelper.shared.sessionID!

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .linkPassthroughWithBankElementsSession)

        let expectedParams = LinkURLParams(paymentObject: .card_payment_method,
                                           publishableKey: config.apiClient.publishableKey!,
                                           paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                                           merchantInfo: LinkURLParams.MerchantInfo(businessName: "StripePaymentSheetTestHostApp", country: "FR"),
                                           customerInfo: LinkURLParams.CustomerInfo(country: "FR", email: nil),
                                           paymentInfo: LinkURLParams.PaymentInfo(currency: "EUR", amount: 100),
                                           experiments: [:],
                                           flags: ["link_passthrough_mode_enabled": true],
                                           loggerMetadata: ["mobile_session_id": sessionID],
                                           locale: Locale.init(identifier: "en_US").toLanguageTag(),
                                           intentMode: .payment,
                                           setupFutureUsage: false,
                                           cardBrandChoice: nil,
                                           linkFundingSources: [.bankAccount, .card],
                                           clientAttributionMetadata: STPClientAttributionMetadata(elementsSessionConfigId: "123", paymentIntentCreationFlow: .deferred, paymentMethodSelectionFlow: .automatic)
        )

        XCTAssertEqual(params, expectedParams)
    }

    func testIgnoresApplePrivateRelayEmails() {
        var config = PaymentSheet.Configuration()
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 100, currency: "EUR")) { _, _, _ in
            // Nothing
        }
        config.apiClient.publishableKey = "pk_123"
        config.defaultBillingDetails.email = "hide_my_email@privaterelay.appleid.com"
        let intent = Intent.deferredIntent(intentConfig: intentConfig)

        let params = try! LinkURLGenerator.linkParams(configuration: config, intent: intent, elementsSession: .linkPassthroughWithBankElementsSession)
        XCTAssertNil(params.customerInfo.email)
    }
}

extension STPElementsSession {
    // Should use the one from StripeiOSTests, but we don't have good infrastructure to share these
    // and we're not using any details from it.
    static var emptyElementsSession: STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["123"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "apple_pay_preference": "enabled",
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }

    static var cbcElementsSession: STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["123"],
                                                                        "country_code": "FR", ] as [String: Any],
                                          "flags": ["cbc_in_link_popup": true,
                                                    "disable_cbc_in_link_popup": false, ] as [String: Bool],
                                          "session_id": "123",
                                          "card_brand_choice": ["eligible": true,
                                                                "preferred_networks": ["cartes_bancaires"],
                                                                "supported_cobranded_networks": ["cartes_bancaires": true],
                                                               ],
                                          "merchant_country": "FR",
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }

    static var linkElementsSession: STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["123"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "apple_pay_preference": "enabled",
                                          "link_settings": ["link_funding_sources": ["CARD"],
                                                            "link_passthrough_mode_enabled": false,
                                                           ],
        ]

        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }

    static var linkElementsSessionWithCustomerSession: STPElementsSession {
        let apiResponse: [String: Any] = [
            "payment_method_preference": [
                "ordered_payment_method_types": ["card", "link"],
                "country_code": "US",
            ],
            "session_id": "123",
            "apple_pay_preference": "enabled",
            "link_settings": [
                "link_funding_sources": ["CARD"],
                "link_passthrough_mode_enabled": false,
            ],
            "customer": [
                "customer_session": [
                    "id": "cuss_123",
                    "customer": "cus_123",
                    "api_key": "ek_123",
                    "api_key_expiry": 1716580929,
                    "livemode": false,
                    "components": [
                        "mobile_payment_element": [
                            "enabled": true,
                            "features": [
                              "payment_method_save": "enabled",
                              "payment_method_remove": "enabled",
                            ],
                        ],
                        "customer_sheet": [
                          "enabled": false
                        ],
                    ],
                ],
                "payment_methods": [],
            ],
        ]

        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }

    static var linkPassthroughElementsSession: STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["123"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "apple_pay_preference": "enabled",
                                          "link_settings": ["link_funding_sources": ["CARD"],
                                                            "link_passthrough_mode_enabled": true,
                                                           ],
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }

    static var linkPassthroughWithBankElementsSession: STPElementsSession {
        let apiResponse: [String: Any] = ["payment_method_preference": ["ordered_payment_method_types": ["123"],
                                                                        "country_code": "US", ] as [String: Any],
                                          "session_id": "123",
                                          "apple_pay_preference": "enabled",
                                          "link_settings": ["link_funding_sources": ["BANK_ACCOUNT",
                                                                                     "CARD",
                                                                                    ],
                                                            "link_passthrough_mode_enabled": true,
                                                           ],
        ]
        return STPElementsSession.decodedObject(fromAPIResponse: apiResponse)!
    }
}

// Just for the purposes of this test. No need to add the (tiny) overhead of Equatable to the published binary
extension LinkURLParams: Equatable {
    public static func == (lhs: StripePaymentSheet.LinkURLParams, rhs: StripePaymentSheet.LinkURLParams) -> Bool {
        let encoder = JSONEncoder()
        // deterministic plz
        encoder.outputFormatting = .sortedKeys
        return try! encoder.encode(lhs) == encoder.encode(rhs)
    }
}
