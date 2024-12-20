//
//  STPFixtures+PaymentSheet.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 8/11/23.
//

import Foundation
@_spi(STP) @testable import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) @_spi(EmbeddedPaymentElementPrivateBeta) @testable import StripePaymentSheet
import StripePaymentsTestUtils
@_spi(STP) import StripeUICore

public extension PaymentSheet.Configuration {
    /// Provides a Configuration that allows all pm types available
    static func _testValue_MostPermissive(isApplePayEnabled: Bool = true) -> Self {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "https://foo.com"
        configuration.allowsDelayedPaymentMethods = true
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        if isApplePayEnabled {
            configuration.applePay = .init(merchantId: "merchant id", merchantCountryCode: "US")
        }
        return configuration
    }
}

public extension EmbeddedPaymentElement.Configuration {
    /// Provides a Configuration that allows all pm types available
    static func _testValue_MostPermissive(isApplePayEnabled: Bool = true) -> Self {
        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.returnURL = "https://foo.com"
        configuration.allowsDelayedPaymentMethods = true
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        if isApplePayEnabled {
            configuration.applePay = .init(merchantId: "merchant id", merchantCountryCode: "US")
        }
        return configuration
    }
}

extension STPElementsSession {
    static func _testCardValue() -> STPElementsSession {
        return _testValue(paymentMethodTypes: ["card"])
    }

    static func _testDefaultCardValue(defaultPaymentMethod: String?, paymentMethods: [[AnyHashable: Any]]? = nil) -> STPElementsSession {
        return _testValue(paymentMethodTypes: ["card"], customerSessionData: [
            "mobile_payment_element": [
                "enabled": true,
                "features": ["payment_method_save": "enabled",
                             "payment_method_remove": "enabled",
                            ],
            ],
            "customer_sheet": [
                "enabled": false,
            ], ], allowsSetAsDefaultPM: true, defaultPaymentMethod: defaultPaymentMethod, paymentMethods: paymentMethods)
    }

    static func _testValue(
        paymentMethodTypes: [String],
        externalPaymentMethodTypes: [String] = [],
        customerSessionData: [String: Any]? = nil,
        cardBrandChoiceData: [String: Any]? = nil,
        isLinkPassthroughModeEnabled: Bool? = nil,
        linkMode: LinkMode? = nil,
        linkFundingSources: Set<LinkSettings.FundingSource> = [],
        disableLinkSignup: Bool? = nil,
        allowsSetAsDefaultPM: Bool = false,
        defaultPaymentMethod: String? = nil,
        paymentMethods: [[AnyHashable: Any]]? = nil
    ) -> STPElementsSession {
        var json = STPTestUtils.jsonNamed("ElementsSession")!
        json[jsonDict: "payment_method_preference"]?["ordered_payment_method_types"] = paymentMethodTypes
        json["external_payment_method_data"] = externalPaymentMethodTypes.map {
            [
                "type": $0,
                "label": $0,
                "light_image_url": "https://test.com",
                "dark_image_url": "https://test.com",
            ]
        }
        if let customerSessionData {
            json["customer"] = ["payment_methods": [],
                                "customer_session": [
                                    "id": "id123",
                                    "livemode": false,
                                    "api_key": "ek_12345",
                                    "api_key_expiry": 12345,
                                    "customer": "cus_123",
                                    "components": customerSessionData,
                                    ],
                                ]
            if allowsSetAsDefaultPM, let defaultPaymentMethod {
                json[jsonDict: "customer"]?["default_payment_method"] = defaultPaymentMethod
            }
            if let paymentMethods {
                json[jsonDict: "customer"]?["payment_methods"] = paymentMethods
            }
        }

        if let cardBrandChoiceData {
            json["card_brand_choice"] = cardBrandChoiceData
        }

        if let isLinkPassthroughModeEnabled {
            json[jsonDict: "link_settings"]!["link_passthrough_mode_enabled"] = isLinkPassthroughModeEnabled
        }

        if let linkMode {
            json[jsonDict: "link_settings"]!["link_mode"] = linkMode.rawValue
        }

        json[jsonDict: "link_settings"]!["link_funding_sources"] = linkFundingSources.map(\.rawValue)

        if let disableLinkSignup {
            json[jsonDict: "link_settings"]!["link_mobile_disable_signup"] = disableLinkSignup
        }

        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: json)!
        return elementsSession
    }

    static func _testValue(
        intent: Intent,
        linkMode: LinkMode? = nil,
        linkFundingSources: Set<LinkSettings.FundingSource> = []
    ) -> STPElementsSession {
        let paymentMethodTypes: [String] = {
            switch intent {
            case .paymentIntent(let paymentIntent):
                return paymentIntent.paymentMethodTypes.map { STPPaymentMethod.string(from: .init(rawValue: $0.intValue) ?? .unknown) ?? "unknown" }
            case .setupIntent(let setupIntent):
                return setupIntent.paymentMethodTypes.map { STPPaymentMethod.string(from: .init(rawValue: $0.intValue) ?? .unknown) ?? "unknown" }
            case .deferredIntent(let intentConfig):
                return intentConfig.paymentMethodTypes ?? []
            }
        }()
        return STPElementsSession._testValue(
            paymentMethodTypes: paymentMethodTypes,
            linkMode: linkMode,
            linkFundingSources: linkFundingSources
        )
    }
}

extension Intent {
    static func _testPaymentIntent(
        paymentMethodTypes: [STPPaymentMethodType],
        setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none,
        currency: String = "usd"
    ) -> Intent {
        let paymentMethodTypes = paymentMethodTypes.map { STPPaymentMethod.string(from: $0) ?? "unknown" }
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: paymentMethodTypes, setupFutureUsage: setupFutureUsage, currency: currency)
        return .paymentIntent(paymentIntent)
    }

    static func _testValue() -> Intent {
        return _testPaymentIntent(paymentMethodTypes: [.card])
    }

    static func _testSetupIntent(
        paymentMethodTypes: [STPPaymentMethodType] = [.card],
        customerSessionData: [String: Any]? = nil
    ) -> Intent {
        let setupIntent = STPFixtures.makeSetupIntent(paymentMethodTypes: paymentMethodTypes)
        return .setupIntent(setupIntent)
    }

    static func _testDeferredIntent(paymentMethodTypes: [STPPaymentMethodType], setupFutureUsage: PaymentSheet.IntentConfiguration.SetupFutureUsage? = nil) -> Intent {
        return .deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD", setupFutureUsage: setupFutureUsage), confirmHandler: { _, _, _ in }))
    }
}

extension STPPaymentMethod {
    static func _testCard() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123card",
            "type": "card",
            "card": [
                "last4": "4242",
                "brand": "visa",
                "fingerprint": "B8XXs2y2JsVBtB9f",
                "networks": ["available": ["visa"]],
                "exp_month": "01",
                "exp_year": Calendar.current.component(.year, from: Date()) + 1,
            ],
        ])!
    }

    static func _testCardAmex() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123card",
            "type": "card",
            "card": [
                "last4": "0005",
                "brand": "amex",
            ],
        ])!
    }

    static func _testCardCoBranded(brand: String = "visa", displayBrand: String? = nil, networks: [String] = ["visa", "amex"]) -> STPPaymentMethod {
        var apiResponse: [String: Any] = [
            "id": "pm_123card",
            "type": "card",
            "card": [
                "last4": "4242",
                "brand": brand,
                "networks": ["available": networks],
                "exp_month": "01",
                "exp_year": Calendar.current.component(.year, from: Date()) + 1,
            ],
        ]
        if let displayBrand {
            apiResponse[jsonDict: "card"]?["display_brand"] = displayBrand
        }
        return STPPaymentMethod.decodedObject(fromAPIResponse: apiResponse)!
    }

    static func _testUSBankAccount() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123",
            "type": "us_bank_account",
            "us_bank_account": [
                "account_holder_type": "individual",
                "account_type": "checking",
                "bank_name": "STRIPE TEST BANK",
                "fingerprint": "ickfX9sbxIyAlbuh",
                "last4": "6789",
                "networks": [
                  "preferred": "ach",
                  "supported": [
                    "ach",
                  ],
                ] as [String: Any],
                "routing_number": "110000000",
            ] as [String: Any],
            "billing_details": [
                "name": "Sam Stripe",
                "email": "sam@stripe.com",
            ] as [String: Any],
        ])!
    }

    static func _testSEPA() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123",
            "type": "sepa_debit",
            "sepa_debit": [
                "last4": "1234",
            ],
            "billing_details": [
                "name": "Sam Stripe",
                "email": "sam@stripe.com",
            ] as [String: Any],
        ])!
    }
}

extension PaymentSheet.Appearance {
    static var _testMSPaintTheme: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()

        // Customize the font
        var font = PaymentSheet.Appearance.Font()
        font.sizeScaleFactor = 0.85
        font.base = UIFont(name: "AvenirNext-Regular", size: 12)!

        appearance.cornerRadius = 0.0
        appearance.borderWidth = 2.0
        appearance.shadow = PaymentSheet.Appearance.Shadow(
            color: .orange,
            opacity: 0.5,
            offset: CGSize(width: 0, height: 2),
            radius: 4
        )

        // Customize the colors
        var colors = PaymentSheet.Appearance.Colors()
        colors.primary = .systemOrange
        colors.background = .cyan
        colors.componentBackground = .yellow
        colors.componentBorder = .systemRed
        colors.componentDivider = .black
        colors.text = .red
        colors.textSecondary = .orange
        colors.componentText = .red
        colors.componentPlaceholderText = .systemBlue
        colors.icon = .green
        colors.danger = .purple

        appearance.font = font
        appearance.colors = colors

        return appearance
    }
}

extension PaymentSheetLoader.LoadResult {
    static func _testValue(paymentMethodTypes: [String], savedPaymentMethods: [STPPaymentMethod]) -> Self {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _, _ in }
        let elementsSession = STPElementsSession._testValue(
            paymentMethodTypes: paymentMethodTypes
        )
        let intent = Intent.deferredIntent(intentConfig: intentConfig)
        return PaymentSheetLoader.LoadResult(
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: savedPaymentMethods,
            paymentMethodTypes: paymentMethodTypes.map { .stripe(STPPaymentMethod.type(from: $0)) }
        )
    }
}

extension PaymentSheetAnalyticsHelper {
    static func _testValue(analyticsClient: STPAnalyticsClient = .sharedClient) -> Self {
        return .init(integrationShape: .complete, configuration: PaymentSheet.Configuration(), analyticsClient: analyticsClient)
    }
}

extension PaymentSheetFormFactory {
    convenience init(
        intent: Intent,
        elementsSession: STPElementsSession,
        configuration: PaymentSheetFormFactoryConfig,
        paymentMethod: PaymentSheet.PaymentMethodType,
        previousCustomerInput: IntentConfirmParams? = nil,
        addressSpecProvider: AddressSpecProvider = .shared,
        linkAccount: PaymentSheetLinkAccount? = nil
    ) {
        self.init(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            paymentMethod: paymentMethod,
            previousCustomerInput: previousCustomerInput,
            addressSpecProvider: addressSpecProvider,
            linkAccount: linkAccount,
            accountService: LinkAccountService._testValue(),
            analyticsHelper: ._testValue()
        )
    }
}

extension LinkAccountService {
    static func _testValue() -> Self {
        .init(apiClient: STPAPIClient(publishableKey: "pk_test"), elementsSession: .emptyElementsSession)
    }
}
