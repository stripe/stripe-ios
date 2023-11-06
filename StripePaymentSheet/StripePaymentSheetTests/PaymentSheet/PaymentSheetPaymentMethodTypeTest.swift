//
//  PaymentSheetPaymentMethodTypeTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(ExternalPaymentMethodsPrivateBeta) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class PaymentSheetPaymentMethodTypeTest: XCTestCase {

    func makeConfiguration(
        hasReturnURL: Bool = false
    ) -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = hasReturnURL ? "foo://bar" : nil
        return configuration
    }

    // MARK: - Images
    func testMakeImage_with_client_asset_and_form_spec() {
        let e = expectation(description: "Load specs")
        FormSpecProvider.shared.load { _ in
            e.fulfill()
        }
        DownloadManager.sharedManager.resetDiskCache()
        DownloadManager.sharedManager.resetMemoryCache()
        waitForExpectations(timeout: 10)
        // A Payment methods with a client-side asset and a form spec image URL...
        let loadExpectation = expectation(description: "Load form spec image")
        let clientImage = STPPaymentMethodType.cashApp.makeImage()!
        let image = PaymentSheet.PaymentMethodType.stripe(.cashApp).makeImage { image in
            // ...should update to the form spec image
            XCTAssertNotEqual(image, clientImage)
            XCTAssertTrue(image.size.width > 1) // Sanity check
            loadExpectation.fulfill()
        }
        // ...should default to the client-side asset
        XCTAssertEqual(image, clientImage)
        waitForExpectations(timeout: 10)
    }

    func testMakeImage_with_client_asset_but_no_form_spec() {
        // A Payment methods with a client-side asset but without a form spec image URL...
        let e = expectation(description: "Load form spec image")
        e.isInverted = true
        let usBankAccountImage = PaymentSheet.PaymentMethodType.stripe(.USBankAccount).makeImage { _ in
            // This shouldn't be called
            XCTFail()
            e.fulfill()
        }
        // ...should default to the client-side asset
        XCTAssertEqual(usBankAccountImage, STPPaymentMethodType.USBankAccount.makeImage())
        waitForExpectations(timeout: 1)
    }

    func testMakeImage_without_client_asset() {
        DownloadManager.sharedManager.resetDiskCache()
        DownloadManager.sharedManager.resetMemoryCache()
        let e = expectation(description: "Load specs")
        FormSpecProvider.shared.load { _ in
            e.fulfill()
        }
        waitForExpectations(timeout: 10)
        // A Payment methods without a client-side asset...
        let loadExpectation = expectation(description: "Load form spec image")
        let image = PaymentSheet.PaymentMethodType.stripe(.amazonPay).makeImage { image in
            // ...should update to the form spec image
            XCTAssertTrue(image.size.width > 1) // Sanity check
            loadExpectation.fulfill()
        }
        // ...should default to a blank placeholder image
        XCTAssertEqual(image.size, .init(width: 1, height: 1))
        waitForExpectations(timeout: 10)
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
                paymentMethod: .iDEAL,
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
                paymentMethod: .iDEAL,
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
                paymentMethod: .afterpayClearpay,
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
                paymentMethod: .afterpayClearpay,
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
                paymentMethod: .afterpayClearpay,
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
                paymentMethod: .afterpayClearpay,
                configuration: config,
                intent: .paymentIntent(STPFixtures.makePaymentIntent(shippingProvided: false)),
                supportedPaymentMethods: [.afterpayClearpay]
            ),
            .supported
        )
    }

    // MARK: - SEPA family

    let sepaFamily: [STPPaymentMethodType] = [.SEPADebit, .iDEAL, .bancontact, .sofort]

    func testCanAddSEPAFamily() {
        // iDEAL and bancontact can be added if returnURL provided
        let sepaFamilySynchronous: [STPPaymentMethodType] = [.iDEAL, .bancontact]
        for pm in sepaFamilySynchronous {
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: makeConfiguration(hasReturnURL: true),
                    intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                    supportedPaymentMethods: sepaFamily.map { $0 }
                ),
                .supported
            )
        }

        let sepaFamilyAsynchronous: [STPPaymentMethodType] = [.sofort, .SEPADebit]
        // ...SEPA and sofort also need allowsDelayedPaymentMethod:
        for pm in sepaFamilyAsynchronous {
            var config = makeConfiguration(hasReturnURL: true)
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: config,
                    intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                    supportedPaymentMethods: sepaFamily.map { $0 }
                ),
                .missingRequirements([.userSupportsDelayedPaymentMethods])
            )
            config.allowsDelayedPaymentMethods = true
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: config,
                    intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                    supportedPaymentMethods: sepaFamily.map { $0 }
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

    func testDisplayName() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.stripe(.card).displayName, "Card")
    }

    func testPaymentIntentRecommendedPaymentMethodTypes() {
        let paymentIntent = constructPI(
            paymentMethodTypes: ["card", "us_bank_account", "klarna", "futurePaymentMethod"],
            orderedPaymentMethodTypes: ["card", "klarna", "us_bank_account", "futurePaymentMethod"]
        )!
        let intent = Intent.paymentIntent(paymentIntent)
        let types = intent.recommendedPaymentMethodTypes

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .klarna)
        XCTAssertEqual(types[2], .USBankAccount)
        XCTAssertEqual(types[3], .unknown)
    }

    func testPaymentIntentRecommendedPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let paymentIntent = constructPI(paymentMethodTypes: [
            "card", "us_bank_account", "klarna", "futurePaymentMethod",
        ])!
        let intent = Intent.paymentIntent(paymentIntent)
        let types = intent.recommendedPaymentMethodTypes

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .USBankAccount)
        XCTAssertEqual(types[2], .klarna)
        XCTAssertEqual(types[3], .unknown)
    }

    func testSetupIntentRecommendedPaymentMethodTypes() {
        let setupIntent = constructSI(paymentMethodTypes: [
            "card", "us_bank_account", "klarna", "futurePaymentMethod",
        ])!
        let intent = Intent.setupIntent(setupIntent)
        let types = intent.recommendedPaymentMethodTypes

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .USBankAccount)
        XCTAssertEqual(types[2], .klarna)
        XCTAssertEqual(types[3], .unknown)
    }

    func testSetupIntentRecommendedPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let setupIntent = constructSI(
            paymentMethodTypes: ["card", "us_bank_account", "klarna", "futurePaymentMethod"],
            orderedPaymentMethodTypes: ["card", "klarna", "us_bank_account", "futurePaymentMethod"]
        )!
        let intent = Intent.setupIntent(setupIntent)
        let types = intent.recommendedPaymentMethodTypes

        XCTAssertEqual(types[0], .card)
        XCTAssertEqual(types[1], .klarna)
        XCTAssertEqual(types[2], .USBankAccount)
        XCTAssertEqual(types[3], .unknown)
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

        XCTAssertEqual(types, [.stripe(.card), .stripe(.klarna), .stripe(.przelewy24)])
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

        XCTAssertEqual(types, [.stripe(.card)])
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

        XCTAssertEqual(types, [.stripe(.card), .stripe(.cashApp)])
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

        XCTAssertEqual(types, [.stripe(.card), .stripe(.cashApp)])
    }

    func testSetupIntentFilteredPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let setupIntent = constructSI(paymentMethodTypes: ["card", "klarna", "p24"])!
        let intent = Intent.setupIntent(setupIntent)
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card)])
    }

    func testUnknownPMTypeIsUnsupported() {
        let paymentIntent = constructPI(paymentMethodTypes: ["luxe_bucks"])!
        let setupIntent = constructSI(paymentMethodTypes: ["luxe_bucks"])!
        let paymentMethod = STPPaymentMethod.type(from: "luxe_bucks")
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: paymentMethod,
                configuration: configuration,
                intent: Intent.setupIntent(setupIntent)
            ),
            .notSupported
        )

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: paymentMethod,
                configuration: configuration,
                intent: Intent.paymentIntent(paymentIntent)
            ),
            .notSupported
        )
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

    func testPaymentMethodOrder() {
        func callFilteredPaymentMethodTypes(withIntentTypes paymentMethodTypes: [String]) -> [PaymentSheet.PaymentMethodType] {
            let intent = Intent.deferredIntent(elementsSession: ._testValue(paymentMethodTypes: paymentMethodTypes, flags: [:]), intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _, _ in }))
            // Note: 👇 `filteredPaymentMethodTypes` is the function we are testing
            return PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, configuration: configuration)
        }
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_paypal"], externalPaymentMethodConfirmHandler: { _, _, completion in
            XCTFail()
            completion(.canceled)
        })

        // Ordering is respected
        configuration.paymentMethodOrder = ["card", "external_paypal"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["card"]),
            [.stripe(.card), .externalPayPal]
        )
        configuration.paymentMethodOrder = ["external_paypal", "card"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["card"]),
            [.externalPayPal, .stripe(.card)]
        )
        // Omitted PMs are ordered afterwards in their original order
        configuration.paymentMethodOrder = ["card", "external_paypal"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"]),
            [.stripe(.card), .externalPayPal, .stripe(.iDEAL), .stripe(.bancontact)]
        )
        // Invalid PM types are ignored
        configuration.paymentMethodOrder = ["foo", "card", "bar", "external_paypal", "zoo"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"]),
            [.stripe(.card), .externalPayPal, .stripe(.iDEAL), .stripe(.bancontact)]
        )
        // Duplicate PMs are ignored
        configuration.paymentMethodOrder = ["card", "card", "external_paypal", "card"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"]),
            [.stripe(.card), .externalPayPal, .stripe(.iDEAL), .stripe(.bancontact)]
        )
        // Empty paymentMethodOrder -> uses default ordering on the Intent
        configuration.paymentMethodOrder = []
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"]),
            [.stripe(.iDEAL), .stripe(.card), .stripe(.bancontact), .externalPayPal]
        )
        // Nil paymentMethodOrder -> uses default ordering on the Intent
        configuration.paymentMethodOrder = nil
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"]),
            [.stripe(.iDEAL), .stripe(.card), .stripe(.bancontact), .externalPayPal]
        )
    }

    func testRepectsExternalPayPalFlag() {
        func callFilteredPaymentMethodTypes(with flags: [String: Bool]) -> [PaymentSheet.PaymentMethodType] {
            let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"], flags: flags)
            let intent = Intent.deferredIntent(
                elementsSession: elementsSession,
                intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _, _ in })
            )
            // Note: 👇 `filteredPaymentMethodTypes` is the function we are testing
            return PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, configuration: configuration)
        }

        // Given a configuration w/ external_paypal...
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_paypal"], externalPaymentMethodConfirmHandler: { _, _, completion in
            XCTFail()
            completion(.canceled)
        })

        // If `elements_enable_external_payment_method_paypal` is false, we should hide external_paypal
        XCTAssertFalse(
            callFilteredPaymentMethodTypes(with: ["elements_enable_external_payment_method_paypal": false])
                .contains(PaymentSheet.PaymentMethodType.externalPayPal)
        )

        // If `elements_enable_external_payment_method_paypal` is true, we should show external_paypal
        XCTAssertTrue(
            callFilteredPaymentMethodTypes(with: ["elements_enable_external_payment_method_paypal": true])
                .contains(PaymentSheet.PaymentMethodType.externalPayPal)
        )

        // If `elements_enable_external_payment_method_paypal` is not present, we should show external_paypal
        XCTAssertTrue(
            callFilteredPaymentMethodTypes(with: [:])
                .contains(PaymentSheet.PaymentMethodType.externalPayPal)
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
        amount: Int = 2345,
        currency: String = "USD",
        paymentMethodTypes: [STPPaymentMethodType]? = nil,
        setupFutureUsage: STPPaymentIntentSetupFutureUsage? = nil,
        paymentMethodOptions: STPPaymentMethodOptions? = nil,
        captureMethod: String = "automatic",
        confirmationMethod: String = "automatic",
        shippingProvided: Bool = false
    ) -> STPPaymentIntent {
        var json = STPTestUtils.jsonNamed(STPTestJSONPaymentIntent)!
        if let setupFutureUsage = setupFutureUsage {
            json["setup_future_usage"] = setupFutureUsage.stringValue
        }
        json["amount"] = amount
        json["currency"] = currency
        json["capture_method"] = captureMethod
        json["confirmation_method"] = confirmationMethod
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
        return STPPaymentIntent.decodedObject(fromAPIResponse: json)!
    }

    static func makeSetupIntent(
        paymentMethodTypes: [STPPaymentMethodType] = [.card],
        usage: String = "off_session"
    ) -> STPSetupIntent {
        var json = STPTestUtils.jsonNamed(STPTestJSONSetupIntent)!
        json["usage"] = usage
        json["payment_method_types"] = paymentMethodTypes.map {
            STPPaymentMethod.string(from: $0)
        }
        return STPSetupIntent.decodedObject(fromAPIResponse: json)!
    }
}
