//
//  STPFixtures+PaymentSheet.swift
//  StripePaymentSheetTests
//
//  Created by David Estes on 8/11/23.
//

import Foundation
@_spi(STP) @testable import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) @testable import StripePaymentSheet
import StripePaymentsTestUtils

public extension PaymentSheet.Configuration {
    /// Provides a Configuration that allows all pm types available
    static func _testValue_MostPermissive() -> Self {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "https://foo.com"
        configuration.allowsDelayedPaymentMethods = true
        configuration.allowsPaymentMethodsRequiringShippingAddress = true
        configuration.applePay = .init(merchantId: "merchant id", merchantCountryCode: "US")
        return configuration
    }
}

extension STPElementsSession {
    static func _testCardValue() -> STPElementsSession {
        let elementsSessionJson = STPTestUtils.jsonNamed("ElementsSession")
        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionJson)!
        return elementsSession
    }

    static func _testValue(
        paymentMethodTypes: [String],
        externalPaymentMethodTypes: [String] = [],
        customerSessionData: [String: Any]? = nil,
        cardBrandChoiceData: [String: Any]? = nil
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
        }

        if let cardBrandChoiceData {
            json["card_brand_choice"] = cardBrandChoiceData
        }

        let elementsSession = STPElementsSession.decodedObject(fromAPIResponse: json)!
        return elementsSession
    }
}

extension Intent {
    static func _testPaymentIntent(
        paymentMethodTypes: [STPPaymentMethodType],
        setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none,
        customerSessionData: [String: Any]? = nil,
        cardBrandChoiceData: [String: Any]? = nil,
        currency: String = "usd",
        cvcRecollectionEnabled: Bool = false
    ) -> Intent {
        let paymentMethodTypes = paymentMethodTypes.map { STPPaymentMethod.string(from: $0) ?? "unknown" }
        let paymentIntent = STPFixtures.paymentIntent(paymentMethodTypes: paymentMethodTypes, setupFutureUsage: setupFutureUsage, currency: currency)
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: paymentMethodTypes, customerSessionData: customerSessionData, cardBrandChoiceData: cardBrandChoiceData)
        return .paymentIntent(elementsSession: elementsSession, paymentIntent: paymentIntent)
    }

    static func _testValue() -> Intent {
        return _testPaymentIntent(paymentMethodTypes: [.card])
    }

    static func _testSetupIntent(
        paymentMethodTypes: [STPPaymentMethodType] = [.card],
        customerSessionData: [String: Any]? = nil
    ) -> Intent {
        let setupIntent = STPFixtures.makeSetupIntent(paymentMethodTypes: paymentMethodTypes)
        let paymentMethodTypes = paymentMethodTypes.map { STPPaymentMethod.string(from: $0) ?? "unknown" }
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: paymentMethodTypes, customerSessionData: customerSessionData)
        return .setupIntent(elementsSession: elementsSession, setupIntent: setupIntent)
    }

    static func _testDeferredIntent(paymentMethodTypes: [STPPaymentMethodType], setupFutureUsage: PaymentSheet.IntentConfiguration.SetupFutureUsage? = nil) -> Intent {
        let paymentMethodTypes = paymentMethodTypes.map { STPPaymentMethod.string(from: $0) ?? "unknown" }
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: paymentMethodTypes, customerSessionData: nil)
        return .deferredIntent(elementsSession: elementsSession, intentConfig: .init(mode: .payment(amount: 1010, currency: "USD", setupFutureUsage: setupFutureUsage), confirmHandler: { _, _, _ in }))
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
        ])!
    }

    static func _testSEPA() -> STPPaymentMethod {
        return STPPaymentMethod.decodedObject(fromAPIResponse: [
            "id": "pm_123",
            "type": "sepa_debit",
            "sepa_debit": [
                "last4": "1234",
            ],
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
