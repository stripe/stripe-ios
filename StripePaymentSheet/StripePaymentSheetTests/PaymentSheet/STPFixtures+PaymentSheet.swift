//
//  STPFixtures+PaymentSheet.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 8/11/23.
//

import Foundation
@_spi(STP) @testable import StripeCore
@_spi(STP) import StripeCoreTestUtils
@_spi(STP) import StripePayments
@_spi(STP) @_spi(PaymentMethodOptionsSetupFutureUsagePreview) @_spi(AppearanceAPIAdditionsPreview) @testable import StripePaymentSheet
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
        if #available(iOS 26.0, *) {
            configuration.appearance.applyLiquidGlassIfPossible()
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

public extension PaymentSheet.Appearance {
    mutating func applyLiquidGlassIfPossible() {
        #if !os(visionOS)
        if #available(iOS 26.0, *) {
            self.applyLiquidGlass()
        }
        #endif
    }
    func applyingLiquidGlassIfPossible() -> PaymentSheet.Appearance {
        var copy = self
        #if !os(visionOS)
        if #available(iOS 26.0, *) {
            copy.applyLiquidGlass()
        }
        #endif
        return copy
    }
}

extension STPElementsSession {
    static func _testValue(
        orderedPaymentMethodTypes: [STPPaymentMethodType] = [.card],
        unactivatedPaymentMethodTypes: [STPPaymentMethodType] = [],
        countryCode: String? = nil,
        merchantCountryCode: String? = nil,
        merchantLogoUrl: URL? = nil,
        linkSettings: LinkSettings? = nil,
        experimentsData: ExperimentsData? = nil,
        flags: [String: Bool] = [:],
        paymentMethodSpecs: [[AnyHashable: Any]]? = nil,
        cardBrandChoice: STPCardBrandChoice? = nil,
        isApplePayEnabled: Bool = true,
        externalPaymentMethods: [ExternalPaymentMethod] = [],
        customPaymentMethods: [CustomPaymentMethod] = [],
        passiveCaptchaData: PassiveCaptchaData? = nil,
        customer: ElementsCustomer? = nil,
        isBackupInstance: Bool = false
    ) -> STPElementsSession {
        return .init(
            allResponseFields: [:],
            sessionID: "test_123",
            configID: "test_config",
            orderedPaymentMethodTypes: orderedPaymentMethodTypes,
            orderedPaymentMethodTypesAndWallets: [],
            unactivatedPaymentMethodTypes: unactivatedPaymentMethodTypes,
            countryCode: countryCode,
            merchantCountryCode: merchantCountryCode,
            merchantLogoUrl: merchantLogoUrl,
            linkSettings: linkSettings,
            experimentsData: experimentsData,
            flags: flags,
            paymentMethodSpecs: paymentMethodSpecs,
            cardBrandChoice: cardBrandChoice,
            isApplePayEnabled: isApplePayEnabled,
            externalPaymentMethods: externalPaymentMethods,
            customPaymentMethods: customPaymentMethods,
            passiveCaptchaData: passiveCaptchaData,
            customer: customer
        )
    }

    static func _testCardValue() -> STPElementsSession {
        return _testValue(paymentMethodTypes: ["card"])
    }

    static func _testDefaultCardValue(defaultPaymentMethod: String?, paymentMethods: [[AnyHashable: Any]]? = nil) -> STPElementsSession {
        return _testValue(paymentMethodTypes: ["card"], customerSessionData: [
            "mobile_payment_element": [
                "enabled": true,
                "features": ["payment_method_save": "enabled",
                             "payment_method_remove": "enabled",
                             "payment_method_set_as_default": "enabled",
                            ],
            ],
            "customer_sheet": [
                "enabled": false,
            ], ], defaultPaymentMethod: defaultPaymentMethod, paymentMethods: paymentMethods)
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
        defaultPaymentMethod: String? = nil,
        paymentMethods: [[AnyHashable: Any]]? = nil,
        linkUseAttestation: Bool? = nil,
        linkSuppress2FA: Bool? = nil,
        hasLinkConsumerIncentive: Bool = false,
        linkSupportedPaymentMethodsOnboardingEnabled: [String] = ["CARD"]
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
            if let defaultPaymentMethod {
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

        if let linkUseAttestation {
            json[jsonDict: "link_settings"]!["link_use_attestation"] = linkUseAttestation
        }

        if let linkSuppress2FA {
            json[jsonDict: "link_settings"]!["link_mobile_suppress_2fa_modal"] = linkSuppress2FA
        }

        if hasLinkConsumerIncentive {
            json[jsonDict: "link_settings"]!["link_consumer_incentive"] = [
                "campaign": "bankaccountsignup",
                "incentive_display_text": "$5",
                "incentive_params": [
                    "amount_flat": 500,
                    "currency": "USD",
                    "payment_method": "link_instant_debits",
                ],
            ]
        }

        json[jsonDict: "link_settings"]!["link_funding_sources"] = linkFundingSources.map(\.rawValue)

        if let disableLinkSignup {
            json[jsonDict: "link_settings"]!["link_mobile_disable_signup"] = disableLinkSignup
        }

        json[jsonDict: "link_settings"]!["link_supported_payment_methods_onboarding_enabled"] = linkSupportedPaymentMethodsOnboardingEnabled

        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: json)!
        return elementsSession
    }

    static func _testValue(
        intent: Intent,
        isLinkPassthroughModeEnabled: Bool? = nil,
        linkMode: LinkMode? = nil,
        linkFundingSources: Set<LinkSettings.FundingSource> = [],
        defaultPaymentMethod: String? = nil,
        paymentMethods: [[AnyHashable: Any]]? = nil,
        allowsSetAsDefaultPM: Bool = false,
        linkSupportedPaymentMethodsOnboardingEnabled: [String] = ["CARD"]
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
        var customerSessionData: [String: Any]?
        if allowsSetAsDefaultPM {
            customerSessionData = [
                "mobile_payment_element": [
                    "enabled": true,
                    "features": ["payment_method_save": "enabled",
                                 "payment_method_remove": "enabled",
                                 "payment_method_set_as_default": "enabled",
                                ],
                ],
                "customer_sheet": [
                    "enabled": false,
                ],
            ]
        }
        return STPElementsSession._testValue(
            paymentMethodTypes: paymentMethodTypes,
            customerSessionData: customerSessionData,
            isLinkPassthroughModeEnabled: isLinkPassthroughModeEnabled,
            linkMode: linkMode,
            linkFundingSources: linkFundingSources,
            defaultPaymentMethod: defaultPaymentMethod,
            paymentMethods: paymentMethods,
            linkSupportedPaymentMethodsOnboardingEnabled: linkSupportedPaymentMethodsOnboardingEnabled
        )
    }
}

extension Intent {
    static func _testPaymentIntent(
        paymentMethodTypes: [STPPaymentMethodType],
        setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none,
        paymentMethodOptionsSetupFutureUsage: [STPPaymentMethodType: String]? = nil,
        currency: String = "usd"
    ) -> Intent {
        let paymentMethodTypes = paymentMethodTypes.map { STPPaymentMethod.string(from: $0) ?? "unknown" }
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: paymentMethodTypes, setupFutureUsage: setupFutureUsage, paymentMethodOptionsSetupFutureUsage: paymentMethodOptionsSetupFutureUsage, currency: currency)
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

    static func _testDeferredIntent(
        paymentMethodTypes: [STPPaymentMethodType],
        setupFutureUsage: PaymentSheet.IntentConfiguration.SetupFutureUsage? = nil,
        paymentMethodOptionsSetupFutureUsage: [STPPaymentMethodType: PaymentSheet.IntentConfiguration.SetupFutureUsage]? = nil
    ) -> Intent {
        return .deferredIntent(intentConfig: .init(mode: .payment(amount: 1010, currency: "USD", setupFutureUsage: setupFutureUsage, paymentMethodOptions: PaymentSheet.IntentConfiguration.Mode.PaymentMethodOptions(setupFutureUsageValues: paymentMethodOptionsSetupFutureUsage)), confirmHandler: { _, _ in return "" }))
    }
}

extension STPPaymentMethod {
    static let _testCardJSON = [
        "id": "pm_123card",
        "type": "card",
        "card": [
            "last4": "4242",
            "brand": "visa",
            "fingerprint": "B8XXs2y2JsVBtB9f",
            "networks": ["available": ["visa"]],
            "exp_month": "01",
            "exp_year": "2040",
        ],
    ] as [AnyHashable: Any]

    static func _testCard() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: _testCardJSON)!
    }
    static func _testCard(line1: String? = nil,
                          line2: String? = nil,
                          city: String? = nil,
                          state: String? = nil,
                          postalCode: String? = nil,
                          countryCode: String? = nil) -> STPPaymentMethod {
        var address: [String: String] = [:]
        if let line1 {
            address["line1"] = line1
        }
        if let line2 {
            address["line2"] = line2
        }
        if let city {
            address["city"] = city
        }
        if let state {
            address["state"] = state
        }
        if let postalCode {
            address["postal_code"] = postalCode
        }
        if let countryCode {
            address["country"] = countryCode
        }
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123card",
            "type": "card",
            "card": [
                "last4": "4242",
                "brand": "visa",
                "fingerprint": "B8XXs2y2JsVBtB9f",
                "networks": ["available": ["visa"]],
                "exp_month": "01",
                "exp_year": "2040",
            ],
            "billing_details": [
                "address": address,
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
                "exp_year": "2040",
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

    static func _testLink(displayName: String? = nil) -> STPPaymentMethod {
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123",
            "type": "link",
            "sepa_debit": [
                "last4": "1234",
            ],
            "billing_details": [
                "name": "Sam Stripe",
                "email": "sam@stripe.com",
            ] as [String: Any],
        ])!
        paymentMethod.linkPaymentDetails = .card(
            LinkPaymentDetails.Card(
                id: "csmr_123",
                displayName: displayName,
                expMonth: 12,
                expYear: 2030,
                last4: "4242",
                brand: .visa
            )
        )
        return paymentMethod
    }
}

extension PaymentSheet.Appearance {
    static var _testMSPaintTheme: PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()
        appearance.applyLiquidGlassIfPossible()

        // Customize the font
        var font = PaymentSheet.Appearance.Font()
        font.sizeScaleFactor = 0.85
        font.base = UIFont(name: "AvenirNext-Regular", size: 12)!

        appearance.cornerRadius = 0.0
        appearance.borderWidth = 2.0
        appearance.sheetCornerRadius = 16.0
        appearance.shadow = PaymentSheet.Appearance.Shadow(
            color: .orange,
            opacity: 0.5,
            offset: CGSize(width: 0, height: 2),
            radius: 4
        )
        appearance.formInsets = NSDirectionalEdgeInsets(top: 30, leading: 50, bottom: 70, trailing: 10)

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

        // Customize the primary button
        var primaryButton = PaymentSheet.Appearance.PrimaryButton()
        primaryButton.height = 50
        primaryButton.cornerRadius = 8

        appearance.font = font
        appearance.colors = colors
        appearance.primaryButton = primaryButton

        return appearance
    }
}

extension PaymentSheetLoader.LoadResult {
    static func _testValue(paymentMethodTypes: [String], savedPaymentMethods: [STPPaymentMethod]) -> Self {
        let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1000, currency: "USD")) { _, _ in return "" }
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
    static func _testValue(
        integrationShape: PaymentSheetAnalyticsHelper.IntegrationShape = .complete,
        configuration: PaymentSheet.Configuration = .init(),
        analyticsClient: STPAnalyticsClient = STPTestingAnalyticsClient(),
        analyticsClientV2: AnalyticsClientV2Protocol = MockAnalyticsClientV2()
    ) -> Self {
        return .init(
            integrationShape: integrationShape,
            configuration: configuration,
            analyticsClient: analyticsClient,
            analyticsClientV2: analyticsClientV2
        )
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

extension STPCardBrandChoice {
    static func _testValue() -> STPCardBrandChoice {
        return .init(
            eligible: true,
            preferredNetworks: [],
            supportedCobrandedNetworks: [:],
            allResponseFields: [:]
        )
    }
}
