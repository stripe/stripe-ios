//
//  PaymentSheetPaymentMethodTypeTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
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
        DownloadManager.sharedManager.resetCache()
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
        waitForExpectations(timeout: 0.1)
    }

    func testMakeImage_without_client_asset() {
        DownloadManager.sharedManager.resetCache()
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
                intent: ._testValue(), elementsSession: ._testCardValue(),
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
                intent: ._testPaymentIntent(paymentMethodTypes: [.card], setupFutureUsage: .offSession),
                elementsSession: ._testCardValue(),
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
                intent: ._testValue(), elementsSession: ._testCardValue(),
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
                intent: ._testValue(), elementsSession: ._testCardValue(),
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
                intent: ._testValue(), elementsSession: ._testCardValue(),
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
                elementsSession: .emptyElementsSession,
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
                elementsSession: .emptyElementsSession,
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
                elementsSession: .emptyElementsSession,
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
                elementsSession: .emptyElementsSession,
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
                    intent: ._testValue(),
                    elementsSession: ._testCardValue(),
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
                    intent: ._testValue(),
                    elementsSession: ._testCardValue(),
                    supportedPaymentMethods: sepaFamily.map { $0 }
                ),
                .missingRequirements([.userSupportsDelayedPaymentMethods])
            )
            config.allowsDelayedPaymentMethods = true
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: config,
                    intent: ._testValue(),
                    elementsSession: ._testCardValue(),
                    supportedPaymentMethods: sepaFamily.map { $0 }
                ),
                .supported
            )
        }
    }

    func testCanAddMultibanco() {
        var config = makeConfiguration(hasReturnURL: true)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .multibanco,
                configuration: config,
                intent: ._testValue(), elementsSession: ._testCardValue(),
                supportedPaymentMethods: [.multibanco]
            ),
            .missingRequirements([.userSupportsDelayedPaymentMethods])
        )
        config.allowsDelayedPaymentMethods = true
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .multibanco,
                configuration: config,
                intent: ._testValue(), elementsSession: ._testCardValue(),
                supportedPaymentMethods: [.multibanco]
            ),
            .supported
        )
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
                card: nil,
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
                        elementsSession: .makeBackupElementsSession(with: pi),
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
                        elementsSession: .makeBackupElementsSession(with: pi),
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
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card", "klarna", "us_bank_account", "futurePaymentMethod"])
        XCTAssertEqual(elementsSession.orderedPaymentMethodTypes, [.card, .klarna, .USBankAccount, .unknown])
    }

    func testSetupIntentRecommendedPaymentMethodTypes() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["klarna", "card"])
        XCTAssertEqual(elementsSession.orderedPaymentMethodTypes, [.klarna, .card])
    }

    // MARK: - Payment Method Types

    func testPaymentIntentFilteredPaymentMethodTypes() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .klarna, .przelewy24])
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        configuration.allowsDelayedPaymentMethods = true
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card), .stripe(.klarna), .stripe(.przelewy24)])
    }

    func testPaymentIntentFilteredPaymentMethodTypes_withUnfulfilledRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .klarna, .przelewy24])
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card)])
    }

    func testPaymentIntentFilteredPaymentMethodTypes_withSetupFutureUsage() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .cashApp, .mobilePay, .amazonPay, .klarna], setupFutureUsage: .onSession)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        configuration.allowsDelayedPaymentMethods = true
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card), .stripe(.cashApp), .stripe(.amazonPay), .stripe(.klarna)])
    }

    func testSetupIntentFilteredPaymentMethodTypes() {
        let setupIntent = STPFixtures.makeSetupIntent(paymentMethodTypes: [.card, .cashApp, .amazonPay, .klarna])
        let intent = Intent.setupIntent(setupIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card), .stripe(.cashApp), .stripe(.amazonPay), .stripe(.klarna)])
    }

    func testSetupIntentFilteredPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let setupIntent = STPFixtures.makeSetupIntent(paymentMethodTypes: [.card, .klarna, .przelewy24])
        let intent = Intent.setupIntent(setupIntent)
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card)])
    }

    func testPaymentMethodTypesLinkCardBrand() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(
                intent: intent,
                linkMode: .linkCardBrand,
                linkFundingSources: [.card, .bankAccount]
            ),
            configuration: configuration
        )
        XCTAssertEqual(types, [.stripe(.card), .linkCardBrand])
    }

    func testPaymentMethodTypesLinkCardBrand_noDefaults() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = false
        configuration.defaultBillingDetails.email = nil
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(
                intent: intent,
                linkMode: .linkCardBrand,
                linkFundingSources: [.card, .bankAccount]
            ),
            configuration: configuration
        )
        // This configuration should not show the bank tab.
        XCTAssertEqual(types, [.stripe(.card)])
    }

    // MARK: SupportsInstantBankPayments

    func testSupportsInstantBankPayments() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )
        XCTAssertEqual(availability, .supported)
    }

    func testSupportsInstantBankPayments_missingLink() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsInstantBankPayments_unexpectedUsBankAccount() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link, .USBankAccount])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case .missingRequirements(let requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .unexpectedUsBankAccount)
    }

    func testSupportsInstantBankPayments_linkFundingSourcesMissingBankAccount() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case .missingRequirements(let requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .linkFundingSourcesMissingBankAccount)
    }

    func testSupportsInstantBankPayments_invalidEmailCollectionConfiguration() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case .missingRequirements(let requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .invalidEmailCollectionConfiguration)
    }

    func testSupportsInstantBankPayments_multipleMissingNonPrimaryRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link, .USBankAccount])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case .missingRequirements(let requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        let expectedMissingRequirements: Set<PaymentSheet.PaymentMethodTypeRequirement> = [
            .unexpectedUsBankAccount,
            .linkFundingSourcesMissingBankAccount,
            .invalidEmailCollectionConfiguration,
        ]
        XCTAssertEqual(requirements.count, 3)
        XCTAssertEqual(requirements, expectedMissingRequirements)
    }

    func testSupportsInstantBankPayments_multipleMissingRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .USBankAccount])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsInstantBankPayments_primaryRequirementPresent_debugDescription() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        let expectedDebugDescription = """
        \t* Your account isn't set up to process Instant Bank Payments. Reach out to Stripe support.
        """
        XCTAssertEqual(availability.debugDescription, expectedDebugDescription)
    }

    func testSupportsInstantBankPayments_primaryRequirementMissing_debugDescription() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        let expectedDebugDescription = """
        This payment method is not currently supported by PaymentSheet.
        """
        XCTAssertEqual(availability.debugDescription, expectedDebugDescription)
    }

    // MARK: SupportsLinkCardIntegration

    func testSupportsLinkCardIntegration() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )
        XCTAssertEqual(availability, .supported)
    }

    func testSupportsLinkCardIntegration_missingLink() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsLinkCardIntegration_unexpectedUsBankAccount() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .USBankAccount])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case .missingRequirements(let requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .unexpectedUsBankAccount)
    }

    func testSupportsLinkCardIntegration_linkFundingSourcesMissingBankAccount() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [.card]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case .missingRequirements(let requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .linkFundingSourcesMissingBankAccount)
    }

    func testSupportsLinkCardIntegration_invalidEmailCollectionConfiguration() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case .missingRequirements(let requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .invalidEmailCollectionConfiguration)
    }

    func testSupportsLinkCardIntegration_multipleMissingNonPrimaryRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .USBankAccount])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [.card]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case .missingRequirements(let requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        let expectedMissingRequirements: Set<PaymentSheet.PaymentMethodTypeRequirement> = [
            .unexpectedUsBankAccount,
            .linkFundingSourcesMissingBankAccount,
            .invalidEmailCollectionConfiguration,
        ]
        XCTAssertEqual(requirements.count, 3)
        XCTAssertEqual(requirements, expectedMissingRequirements)
    }

    func testSupportsLinkCardIntegration_multipleMissingRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .USBankAccount])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsLinkCardIntegration_primaryRequirementPresent_debugDescription() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [.card]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        let expectedDebugDescription = """
        \t* Your account isn't set up to process Instant Bank Payments. Reach out to Stripe support.
        """
        XCTAssertEqual(availability.debugDescription, expectedDebugDescription)
    }

    func testSupportsLinkCardIntegration_primaryRequirementMissing_debugDescription() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [.card, .bankAccount]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        let expectedDebugDescription = """
        This payment method is not currently supported by PaymentSheet.
        """
        XCTAssertEqual(availability.debugDescription, expectedDebugDescription)
    }

    // MARK: Other

    func testUnknownPMTypeIsUnsupported() {
        let setupIntent = STPFixtures.makeSetupIntent(paymentMethodTypes: [.unknown])
        let paymentMethod = STPPaymentMethod.type(from: "luxe_bucks")
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: paymentMethod,
                configuration: configuration,
                intent: Intent.setupIntent( setupIntent),
                elementsSession: ._testCardValue()
            ),
            .notSupported
        )

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: paymentMethod,
                configuration: configuration,
                intent: ._testPaymentIntent(paymentMethodTypes: [.unknown]),
                elementsSession: .emptyElementsSession
            ),
            .notSupported
        )
    }

    func testSupport() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.unknown])
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
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_paypal"], externalPaymentMethodConfirmHandler: { _, _, completion in
            XCTFail()
            completion(.canceled)
        })

        func callFilteredPaymentMethodTypes(withIntentTypes paymentMethodTypes: [String], externalPMTypes: [String]) -> [PaymentSheet.PaymentMethodType] {
            let intent = Intent.deferredIntent(
                intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _, _ in })
            )
            // Note: 👇 `filteredPaymentMethodTypes` is the function we are testing
            return PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, elementsSession: ._testValue(paymentMethodTypes: paymentMethodTypes, externalPaymentMethodTypes: externalPMTypes), configuration: configuration)
        }

        // Ordering is respected
        configuration.paymentMethodOrder = ["card", "external_paypal"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["card"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["card", "external_paypal"]
        )
        configuration.paymentMethodOrder = ["external_paypal", "card"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["card"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["external_paypal", "card"]
        )
        // Omitted PMs are ordered afterwards in their original order
        configuration.paymentMethodOrder = ["card", "external_paypal"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["card", "external_paypal", "ideal", "bancontact"]
        )
        // Invalid PM types are ignored
        configuration.paymentMethodOrder = ["foo", "card", "bar", "external_paypal", "zoo"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["card", "external_paypal", "ideal", "bancontact"]
        )
        // Duplicate PMs are ignored
        configuration.paymentMethodOrder = ["card", "card", "external_paypal", "card"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["card", "external_paypal", "ideal", "bancontact"]
        )
        // Empty paymentMethodOrder -> uses default ordering on the Intent
        configuration.paymentMethodOrder = []
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["ideal", "card", "bancontact", "external_paypal"]
        )
        // Nil paymentMethodOrder -> uses default ordering on the Intent
        configuration.paymentMethodOrder = nil
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["ideal", "card", "bancontact", "external_paypal"]
        )
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
        shippingProvided: Bool = false,
        paymentMethodJson: [String: Any]? = nil
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
                STPPaymentMethod.string(from: $0) ?? "unknown"
            }
        }
        if !shippingProvided {
            // The payment intent json already has shipping on it, so just remove it if needed
            json["shipping"] = nil
        }
        if let paymentMethodJson = paymentMethodJson {
            json["payment_method"] = paymentMethodJson

        }
        if let paymentMethodOptions = paymentMethodOptions {
            json["payment_method_options"] = paymentMethodOptions.dictionaryValue
        }
        return STPPaymentIntent.decodedObject(fromAPIResponse: json)!
    }

    static func makeSetupIntent(
        paymentMethodTypes: [STPPaymentMethodType] = [.card],
        usage: String = "off_session",
        paymentMethodJson: [String: Any]? = nil
    ) -> STPSetupIntent {
        var json = STPTestUtils.jsonNamed(STPTestJSONSetupIntent)!
        json["usage"] = usage
        json["payment_method_types"] = paymentMethodTypes.map {
            STPPaymentMethod.string(from: $0)
        }
        if let paymentMethodJson = paymentMethodJson {
            json["payment_method"] = paymentMethodJson

        }
        return STPSetupIntent.decodedObject(fromAPIResponse: json)!
    }
}
