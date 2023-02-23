//
//  PaymentSheetPaymentMethodTypeTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import Stripe
@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsUI

class PaymentSheetPaymentMethodTypeTest: XCTestCase {

    func makeConfiguration(
        hasReturnURL: Bool = false
    ) -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = hasReturnURL ? "foo://bar" : nil
        return configuration
    }

    // MARK: - Cards

    /// Returns false, card not in `supportedPaymentMethods`
    func testSupportsAdding_notInSupportedList_noRequirementsNeeded() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .card,
                configuration: PaymentSheet.Configuration(),
                intent: .paymentIntent(STPFixtures.paymentIntent()),
                supportedPaymentMethods: []
            )
            , .notSupported
        )
    }

    /// Returns true, card in `supportedPaymentMethods` and has no additional requirements
    func testSupportsAdding_inSupportedList_noRequirementsNeeded() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .card,
                configuration: PaymentSheet.Configuration(),
                intent: .paymentIntent(
                    STPFixtures.makePaymentIntent(setupFutureUsage: .offSession)
                ),
                supportedPaymentMethods: [.card]
            ),
            .supported
        )
    }

    /// Returns true, card in `supportedPaymentMethods` and has no additional requirements
    func testSupportsAdding_inSupportedList_noRequirementsNeededButProvided() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .card,
                configuration: makeConfiguration(hasReturnURL: true),
                intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                supportedPaymentMethods: [.card]
            ),
            .supported
        )
    }

    // MARK: - iDEAL

    /// Returns true, iDEAL in `supportedPaymentMethods` and URL requirement and not setting up requirement are met
    func testSupportsAdding_inSupportedList_urlConfiguredRequired() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: PaymentSheet.PaymentMethodType.dynamic("ideal"),
                configuration: makeConfiguration(hasReturnURL: true),
                intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                supportedPaymentMethods: [.iDEAL]
            ),
            .supported
        )
    }

    /// Returns true, iDEAL in `supportedPaymentMethods` but URL requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredRequiredButNotProvided() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: PaymentSheet.PaymentMethodType.dynamic("ideal"),
                configuration: makeConfiguration(),
                intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                supportedPaymentMethods: [.iDEAL]
            ),
            .missingRequirements([.returnURL])
        )
    }

    // MARK: - Afterpay

    /// Returns false, Afterpay in `supportedPaymentMethods` but shipping requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_missingShipping() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay"),
                configuration: makeConfiguration(hasReturnURL: true),
                intent: .paymentIntent(STPFixtures.makePaymentIntent(shippingProvided: false)),
                supportedPaymentMethods: [.afterpayClearpay]
            ),
            .missingRequirements([.shippingAddress])
        )
    }

    /// Returns false, Afterpay in `supportedPaymentMethods` but URL and shipping requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_missingURL() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay"),
                configuration: makeConfiguration(hasReturnURL: false),
                intent: .paymentIntent(STPFixtures.makePaymentIntent(shippingProvided: false)),
                supportedPaymentMethods: [.afterpayClearpay]
            ),
            .missingRequirements([.shippingAddress, .returnURL])
        )
    }

    /// Returns true, Afterpay in `supportedPaymentMethods` and both URL and shipping requirements are met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_bothMet() {
        // Afterpay should be supported if PI has shipping...
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay"),
                configuration: makeConfiguration(hasReturnURL: true),
                intent: .paymentIntent(STPFixtures.makePaymentIntent(shippingProvided: true)),
                supportedPaymentMethods: [.afterpayClearpay]
            ),
            .supported
        )
        // ...and also if configuration.allowsPaymentMethodsThatRequireShipping is true
        var config = makeConfiguration(hasReturnURL: true)
        config.allowsPaymentMethodsRequiringShippingAddress = true
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay"),
                configuration: config,
                intent: .paymentIntent(STPFixtures.makePaymentIntent(shippingProvided: false)),
                supportedPaymentMethods: [.afterpayClearpay]
            ),
            .supported
        )
    }

    // MARK: - SEPA family

    let sepaFamily = [
        PaymentSheet.PaymentMethodType.dynamic("ideal"),
        PaymentSheet.PaymentMethodType.dynamic("bancontact"),
        PaymentSheet.PaymentMethodType.dynamic("sofort"),
        PaymentSheet.PaymentMethodType.dynamic("sepa_debit"),
    ]
    func testCantSetupSEPAFamily() {
        // All SEPA family pms...
        for pm in sepaFamily {
            // ...can't be used for PIs...
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: makeConfiguration(hasReturnURL: true),
                    // ...if setup future usage is provided.
                    intent: .paymentIntent(
                        STPFixtures.makePaymentIntent(setupFutureUsage: .offSession)
                    ),
                    supportedPaymentMethods: sepaFamily.map { $0.stpPaymentMethodType! }
                ),
                .missingRequirements([.unavailable, .userSupportsDelayedPaymentMethods])
            )

            // ...and can't be set up
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: makeConfiguration(hasReturnURL: true),
                    intent: .setupIntent(STPFixtures.setupIntent()),
                    supportedPaymentMethods: sepaFamily.map { $0.stpPaymentMethodType! }
                ),
                .missingRequirements([.unavailable, .userSupportsDelayedPaymentMethods])
            )
        }
    }

    func testCanAddSEPAFamily() {
        // iDEAL and bancontact can be added if returnURL provided
        let sepaFamilySynchronous = [
            PaymentSheet.PaymentMethodType.dynamic("ideal"),
            PaymentSheet.PaymentMethodType.dynamic("bancontact"),
        ]
        for pm in sepaFamilySynchronous {
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: makeConfiguration(hasReturnURL: true),
                    intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                    supportedPaymentMethods: sepaFamily.map { $0.stpPaymentMethodType! }
                ),
                .supported
            )
        }

        let sepaFamilyAsynchronous = [
            PaymentSheet.PaymentMethodType.dynamic("sofort"),
            PaymentSheet.PaymentMethodType.dynamic("sepa_debit"),
        ]
        // ...SEPA and sofort also need allowsDelayedPaymentMethod:
        for pm in sepaFamilyAsynchronous {
            var config = makeConfiguration(hasReturnURL: true)
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: config,
                    intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                    supportedPaymentMethods: sepaFamily.map { $0.stpPaymentMethodType! }
                ),
                .missingRequirements([.userSupportsDelayedPaymentMethods])
            )
            config.allowsDelayedPaymentMethods = true
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: config,
                    intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                    supportedPaymentMethods: sepaFamily.map { $0.stpPaymentMethodType! }
                ),
                .supported
            )
        }
    }

    // US Bank Account
    func testCanAddUSBankAccountBasedOnVerificationMethod() {
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        for verificationMethod in STPPaymentMethodOptions.USBankAccount.VerificationMethod.allCases {
            let usBankOptions = STPPaymentMethodOptions.USBankAccount(
                setupFutureUsage: nil,
                verificationMethod: verificationMethod,
                allResponseFields: [:]
            )
            let paymentMethodOptions = STPPaymentMethodOptions(
                usBankAccount: usBankOptions,
                allResponseFields: [:]
            )
            let pi = STPFixtures.makePaymentIntent(
                paymentMethodTypes: [.USBankAccount],
                setupFutureUsage: nil,
                paymentMethodOptions: paymentMethodOptions,
                shippingProvided: false
            )
            switch verificationMethod {
            case .automatic, .instantOrSkip, .instant:
                XCTAssertEqual(
                    PaymentSheet.PaymentMethodType.supportsAdding(
                        paymentMethod: .USBankAccount,
                        configuration: configuration,
                        intent: .paymentIntent(pi),
                        supportedPaymentMethods: [.USBankAccount]
                    ),
                    .supported
                )

            case .skip, .microdeposits, .unknown:
                XCTAssertEqual(
                    PaymentSheet.PaymentMethodType.supportsAdding(
                        paymentMethod: .USBankAccount,
                        configuration: configuration,
                        intent: .paymentIntent(pi),
                        supportedPaymentMethods: [.USBankAccount]
                    ),
                    .missingRequirements([.validUSBankVerificationMethod])
                )
            }
        }
    }

    func testInit() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType(from: "card"), .card)
        XCTAssertEqual(PaymentSheet.PaymentMethodType(from: "us_bank_account"), .USBankAccount)
        XCTAssertEqual(PaymentSheet.PaymentMethodType(from: "link"), .link)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType(from: "mock_payment_method"),
            .dynamic("mock_payment_method")
        )
    }

    func testString() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.string(from: .card), "card")
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.string(from: .USBankAccount),
            "us_bank_account"
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.string(from: .link), "link")
        XCTAssertNil(PaymentSheet.PaymentMethodType.string(from: .linkInstantDebit))
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.string(from: .dynamic("mock_payment_method")),
            "mock_payment_method"
        )
    }

    func testDisplayName() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("card").displayName, "Card")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.card.displayName, "Card")

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("us_bank_account").displayName,
            "US Bank Account"
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.USBankAccount.displayName, "US Bank Account")

        XCTAssertEqual(PaymentSheet.PaymentMethodType.link.displayName, "Link")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("link").displayName, "Link")

        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("alipay").displayName, "Alipay")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("ideal").displayName, "iDEAL")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("fpx").displayName, "FPX")
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("sepa_debit").displayName,
            "SEPA Debit"
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("au_becs_debit").displayName,
            "AU BECS Direct Debit"
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("grabpay").displayName, "GrabPay")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("giropay").displayName, "giropay")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("eps").displayName, "EPS")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("p24").displayName, "Przelewy24")
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("bancontact").displayName,
            "Bancontact"
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("netbanking").displayName,
            "NetBanking"
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("oxxo").displayName, "OXXO")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("sofort").displayName, "Sofort")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("upi").displayName, "UPI")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("paypal").displayName, "PayPal")
        if Locale.current.regionCode == "GB" {
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay").displayName,
                "Clearpay"
            )
        } else {
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay").displayName,
                "Afterpay"
            )
        }
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("blik").displayName, "BLIK")
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("wechat_pay").displayName,
            "WeChat Pay"
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("boleto").displayName, "Boleto")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("link").displayName, "Link")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("klarna").displayName, "Klarna")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("affirm").displayName, "Affirm")
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("").displayName, "")
    }

    func testSTPPaymentMethodType() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.card.stpPaymentMethodType, .card)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("card").stpPaymentMethodType, .card)

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.USBankAccount.stpPaymentMethodType,
            .USBankAccount
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("us_bank_account").stpPaymentMethodType,
            .USBankAccount
        )

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.linkInstantDebit.stpPaymentMethodType,
            .linkInstantDebit
        )

        XCTAssertEqual(PaymentSheet.PaymentMethodType.link.stpPaymentMethodType, .link)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("link").stpPaymentMethodType, .link)

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("alipay").stpPaymentMethodType,
            .alipay
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("ideal").stpPaymentMethodType, .iDEAL)
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("fpx").stpPaymentMethodType, .FPX)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("sepa_debit").stpPaymentMethodType,
            .SEPADebit
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("au_becs_debit").stpPaymentMethodType,
            .AUBECSDebit
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("grabpay").stpPaymentMethodType,
            .grabPay
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("giropay").stpPaymentMethodType,
            .giropay
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("eps").stpPaymentMethodType, .EPS)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("p24").stpPaymentMethodType,
            .przelewy24
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("bancontact").stpPaymentMethodType,
            .bancontact
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("netbanking").stpPaymentMethodType,
            .netBanking
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("oxxo").stpPaymentMethodType, .OXXO)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("sofort").stpPaymentMethodType,
            .sofort
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("upi").stpPaymentMethodType, .UPI)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("paypal").stpPaymentMethodType,
            .payPal
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("afterpay_clearpay").stpPaymentMethodType,
            .afterpayClearpay
        )
        XCTAssertEqual(PaymentSheet.PaymentMethodType.dynamic("blik").stpPaymentMethodType, .blik)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("wechat_pay").stpPaymentMethodType,
            .weChatPay
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("boleto").stpPaymentMethodType,
            .boleto
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("klarna").stpPaymentMethodType,
            .klarna
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.dynamic("affirm").stpPaymentMethodType,
            .affirm
        )
        XCTAssertNil(PaymentSheet.PaymentMethodType.dynamic("doesNotExist").stpPaymentMethodType)
    }

    func testConvertingNonDynamicTypes() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.card.stpPaymentMethodType,
            PaymentSheet.PaymentMethodType.dynamic("card").stpPaymentMethodType
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.USBankAccount.stpPaymentMethodType,
            PaymentSheet.PaymentMethodType.dynamic("us_bank_account").stpPaymentMethodType
        )
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.link.stpPaymentMethodType,
            PaymentSheet.PaymentMethodType.dynamic("link").stpPaymentMethodType
        )
    }

    func testPaymentIntentRecommendedPaymentMethodTypes() {
        let paymentIntent = constructPI(
            paymentMethodTypes: ["card", "us_bank_account", "klarna", "futurePaymentMethod"],
            orderedPaymentMethodTypes: ["card", "klarna", "us_bank_account", "futurePaymentMethod"]
        )!
        let intent = Intent.paymentIntent(paymentIntent)
        let types = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .dynamic("klarna"))
        XCTAssertEqual(types[2], .USBankAccount)
        XCTAssertEqual(types[3], .dynamic("futurePaymentMethod"))

    }

    func testPaymentIntentRecommendedPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let paymentIntent = constructPI(paymentMethodTypes: [
            "card", "us_bank_account", "klarna", "futurePaymentMethod",
        ])!
        let intent = Intent.paymentIntent(paymentIntent)
        let types = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .USBankAccount)
        XCTAssertEqual(types[2], .dynamic("klarna"))
        XCTAssertEqual(types[3], .dynamic("futurePaymentMethod"))
    }

    func testSetupIntentRecommendedPaymentMethodTypes() {
        let setupIntent = constructSI(paymentMethodTypes: [
            "card", "us_bank_account", "klarna", "futurePaymentMethod",
        ])!
        let intent = Intent.setupIntent(setupIntent)
        let types = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .USBankAccount)
        XCTAssertEqual(types[2], .dynamic("klarna"))
        XCTAssertEqual(types[3], .dynamic("futurePaymentMethod"))
    }

    func testSetupIntentRecommendedPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let setupIntent = constructSI(
            paymentMethodTypes: ["card", "us_bank_account", "klarna", "futurePaymentMethod"],
            orderedPaymentMethodTypes: ["card", "klarna", "us_bank_account", "futurePaymentMethod"]
        )!
        let intent = Intent.setupIntent(setupIntent)
        let types = PaymentSheet.PaymentMethodType.recommendedPaymentMethodTypes(from: intent)

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .dynamic("klarna"))
        XCTAssertEqual(types[2], .USBankAccount)
        XCTAssertEqual(types[3], .dynamic("futurePaymentMethod"))
    }

    func testPaymentIntentFilteredPaymentMethodTypes() {
        let paymentIntent = constructPI(
            paymentMethodTypes: ["card", "klarna", "p24"],
            orderedPaymentMethodTypes: ["card", "klarna", "p24"]
        )!
        let intent = Intent.paymentIntent(paymentIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        configuration.allowsDelayedPaymentMethods = true
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration
        )

        XCTAssertEqual(types.count, 3)
        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .dynamic("klarna"))
        XCTAssertEqual(types[2], .dynamic("p24"))
    }

    func testPaymentIntentFilteredPaymentMethodTypes_withUnfulfilledRequirements() {
        let paymentIntent = constructPI(
            paymentMethodTypes: ["card", "klarna", "p24"],
            orderedPaymentMethodTypes: ["card", "klarna", "p24"]
        )!
        let intent = Intent.paymentIntent(paymentIntent)
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration
        )

        XCTAssertEqual(types.count, 1)
        XCTAssertEqual(types[0], .card)
    }

    func testPaymentIntentFilteredPaymentMethodTypes_withSetupFutureUsage() {
        let paymentIntent = constructPI(
            paymentMethodTypes: ["card", "cashapp"],
            orderedPaymentMethodTypes: ["card", "cashapp", "mobilepay"],
            setupFutureUsage: .onSession
        )!
        let intent = Intent.paymentIntent(paymentIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        configuration.allowsDelayedPaymentMethods = true
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration
        )

        XCTAssertEqual(types.count, 1)
        XCTAssertEqual(types[0], .card)
        // Cash App is not enabled for saving or reuse so it should be filtered out
    }

    func testSetupIntentFilteredPaymentMethodTypes() {
        let setupIntent = constructSI(paymentMethodTypes: ["card", "cashapp"])!
        let intent = Intent.setupIntent(setupIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration
        )

        XCTAssertEqual(types.count, 1)
        XCTAssertEqual(types[0], .card)
        // Cash App is not enabled for saving or reuse so it should be filtered out
    }

    func testSetupIntentFilteredPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let setupIntent = constructSI(paymentMethodTypes: ["card", "klarna", "p24"])!
        let intent = Intent.setupIntent(setupIntent)
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration
        )

        XCTAssertEqual(types.count, 1)
        XCTAssertEqual(types[0], .card)
    }

    func testUnknownPMTypeIsUnsupported() {
        let paymentIntent = constructPI(paymentMethodTypes: ["luxe_bucks"])!
        let setupIntent = constructSI(paymentMethodTypes: ["luxe_bucks"])!
        let paymentMethod = PaymentSheet.PaymentMethodType.dynamic("luxe_bucks")
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        for intent in [Intent.setupIntent(setupIntent), Intent.paymentIntent(paymentIntent)] {
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: paymentMethod,
                    configuration: configuration,
                    intent: intent
                ),
                .missingRequirements([.unavailable])
            )
        }
    }

    func testSupport() {
        let paymentIntent = constructPI(paymentMethodTypes: ["luxe_bucks"])!
        let intent = Intent.paymentIntent(paymentIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.configurationSatisfiesRequirements(
                requirements: [.returnURL],
                configuration: configuration,
                intent: intent
            ),
            .supported
        )
    }

    private func constructPI(
        paymentMethodTypes: [String],
        orderedPaymentMethodTypes: [String]? = nil,
        setupFutureUsage: STPPaymentIntentSetupFutureUsage = .none
    ) -> STPPaymentIntent? {
        var apiResponse: [AnyHashable: Any?] = [
            "id": "123",
            "client_secret": "sec",
            "amount": 10,
            "currency": "usd",
            "status": "requires_payment_method",
            "livemode": false,
            "created": 1652736692.0,
            "payment_method_types": paymentMethodTypes,
            "setup_future_usage": setupFutureUsage.stringValue,
        ]
        if let orderedPaymentMethodTypes = orderedPaymentMethodTypes {
            apiResponse["ordered_payment_method_types"] = orderedPaymentMethodTypes
        }
        guard
            let stpPaymentIntent = STPPaymentIntent.decodeSTPPaymentIntentObject(
                fromAPIResponse: apiResponse as [AnyHashable: Any]
            )
        else {
            XCTFail("Failed to decode")
            return nil
        }
        return stpPaymentIntent
    }
    private func constructSI(
        paymentMethodTypes: [String],
        orderedPaymentMethodTypes: [String]? = nil
    ) -> STPSetupIntent? {
        var apiResponse: [AnyHashable: Any] = [
            "id": "123",
            "client_secret": "sec",
            "status": "requires_payment_method",
            "created": 1652736692.0,
            "payment_method_types": paymentMethodTypes,
            "livemode": false,
        ]
        if let orderedPaymentMethodTypes = orderedPaymentMethodTypes {
            apiResponse["ordered_payment_method_types"] = orderedPaymentMethodTypes
        }
        guard
            let stpSetupIntent = STPSetupIntent.decodeSTPSetupIntentObject(
                fromAPIResponse: apiResponse
            )
        else {
            XCTFail("Failed to decode")
            return nil
        }
        return stpSetupIntent
    }

}

extension STPFixtures {
    static func makePaymentIntent(
        paymentMethodTypes: [STPPaymentMethodType]? = nil,
        setupFutureUsage: STPPaymentIntentSetupFutureUsage? = nil,
        paymentMethodOptions: STPPaymentMethodOptions? = nil,
        shippingProvided: Bool = false
    ) -> STPPaymentIntent {
        var json = STPTestUtils.jsonNamed(STPTestJSONPaymentIntent)!
        if let setupFutureUsage = setupFutureUsage {
            json["setup_future_usage"] = setupFutureUsage.stringValue
        }
        if let paymentMethodTypes = paymentMethodTypes {
            json["payment_method_types"] = paymentMethodTypes.map {
                STPPaymentMethod.string(from: $0)
            }
        }
        if !shippingProvided {
            // The payment intent json already has shipping on it, so just remove it if needed
            json["shipping"] = nil
        }
        if let paymentMethodOptions = paymentMethodOptions {
            json["payment_method_options"] = paymentMethodOptions.dictionaryValue
        }
        let pi = STPPaymentIntent.decodedObject(fromAPIResponse: json)
        return pi!
    }
}
