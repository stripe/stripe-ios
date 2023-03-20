//
//  PaymentSheet+PaymentMethodAvailabilityTest.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 8/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

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
            json["payment_method_types"] = paymentMethodTypes.map { STPPaymentMethod.string(from: $0) }
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

class PaymentSheet_PaymentMethodAvailabilityTest: XCTestCase {
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
        XCTAssertFalse(PaymentSheet.supportsAdding(
            paymentMethod: .card,
            configuration: PaymentSheet.Configuration(),
            intent: .paymentIntent(STPFixtures.paymentIntent()),
            supportedPaymentMethods: [])
        )
    }
    
    /// Returns true, card in `supportedPaymentMethods` and has no additional requirements
    func testSupportsAdding_inSupportedList_noRequirementsNeeded() {
        XCTAssertTrue(PaymentSheet.supportsAdding(
            paymentMethod: .card,
            configuration: PaymentSheet.Configuration(),
            intent: .paymentIntent(STPFixtures.makePaymentIntent(setupFutureUsage: .offSession)),
            supportedPaymentMethods: [.card])
        )
    }
    
    
    /// Returns true, card in `supportedPaymentMethods` and has no additional requirements
    func testSupportsAdding_inSupportedList_noRequirementsNeededButProvided() {
        XCTAssertTrue(PaymentSheet.supportsAdding(
            paymentMethod: .card,
            configuration: makeConfiguration(hasReturnURL: true),
            intent: .paymentIntent(STPFixtures.makePaymentIntent()),
            supportedPaymentMethods: [.card])
        )
    }

    // MARK: - iDEAL
    
    /// Returns true, iDEAL in `supportedPaymentMethods` and URL requirement and not setting up requirement are met
    func testSupportsAdding_inSupportedList_urlConfiguredRequired() {
        XCTAssertTrue(PaymentSheet.supportsAdding(
            paymentMethod: .iDEAL,
            configuration: makeConfiguration(hasReturnURL: true),
            intent: .paymentIntent(STPFixtures.makePaymentIntent()),
            supportedPaymentMethods: [.iDEAL])
        )
    }

    /// Returns true, iDEAL in `supportedPaymentMethods` but URL requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredRequiredButNotProvided() {
        XCTAssertFalse(PaymentSheet.supportsAdding(
            paymentMethod: .iDEAL,
            configuration: makeConfiguration(),
            intent: .paymentIntent(STPFixtures.makePaymentIntent()),
            supportedPaymentMethods: [.iDEAL])
        )
    }
    
    // MARK: - Afterpay

    /// Returns false, Afterpay in `supportedPaymentMethods` but shipping requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_missingSihpping() {
        XCTAssertFalse(PaymentSheet.supportsAdding(
            paymentMethod: .afterpayClearpay,
            configuration: makeConfiguration(hasReturnURL: true),
            intent: .paymentIntent(STPFixtures.makePaymentIntent(shippingProvided: false)),
            supportedPaymentMethods: [.iDEAL])
        )
    }

    /// Returns false, Afterpay in `supportedPaymentMethods` but URL requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_missingURL() {
        XCTAssertFalse(PaymentSheet.supportsAdding(
            paymentMethod: .afterpayClearpay,
            configuration: makeConfiguration(hasReturnURL: false),
            intent: .paymentIntent(STPFixtures.makePaymentIntent(shippingProvided: false)),
            supportedPaymentMethods: [.iDEAL])
        )
    }

    /// Returns true, Afterpay in `supportedPaymentMethods` and both URL ands shipping requirements are met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_bothMet() {
        XCTAssertFalse(PaymentSheet.supportsAdding(
            paymentMethod: .afterpayClearpay,
            configuration: makeConfiguration(hasReturnURL: true),
            intent: .paymentIntent(STPFixtures.makePaymentIntent(shippingProvided: true)),
            supportedPaymentMethods: [.iDEAL])
        )
    }
    
    // MARK: - SEPA family
    
    let sepaFamily: [STPPaymentMethodType] = [.iDEAL, .bancontact, .sofort, .SEPADebit]
    func testCantSetupSEPAFamily() {
        // All SEPA family pms...
        for pm in sepaFamily {
            // ...can't be added...
            XCTAssertFalse(PaymentSheet.supportsAdding(
                paymentMethod: pm,
                configuration: makeConfiguration(hasReturnURL: true),
                // ...if setup future usage is provided.
                intent: .paymentIntent(STPFixtures.makePaymentIntent(setupFutureUsage: .offSession)),
                supportedPaymentMethods: sepaFamily)
            )
            
            // ...and can't be set up
            XCTAssertFalse(PaymentSheet.supportsSaveAndReuse(
                paymentMethod: pm,
                configuration: makeConfiguration(hasReturnURL: true),
                intent: .setupIntent(STPFixtures.setupIntent()),
                supportedPaymentMethods: sepaFamily)
            )
        }
    }
    
    func testCanAddSEPAFamily() {
        // iDEAL and bancontact can be added if returnURL provided
        let sepaFamilySynchronous: [STPPaymentMethodType] = [.iDEAL, .bancontact]
        for pm in sepaFamilySynchronous {
            XCTAssertTrue(PaymentSheet.supportsAdding(
                paymentMethod: pm,
                configuration: makeConfiguration(hasReturnURL: true),
                intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                supportedPaymentMethods: sepaFamily)
            )
        }
        
        let sepaFamilyAsynchronous: [STPPaymentMethodType] = [.sofort, .SEPADebit]
        // ...SEPA and sofort also need allowsDelayedPaymentMethod:
        for pm in sepaFamilyAsynchronous {
            var config = makeConfiguration(hasReturnURL: true)
            XCTAssertFalse(PaymentSheet.supportsAdding(
                paymentMethod: pm,
                configuration: config,
                intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                supportedPaymentMethods: sepaFamily)
            )
            config.allowsDelayedPaymentMethods = true
            XCTAssertTrue(PaymentSheet.supportsAdding(
                paymentMethod: pm,
                configuration: config,
                intent: .paymentIntent(STPFixtures.makePaymentIntent()),
                supportedPaymentMethods: sepaFamily)
            )
        }
    }

    // US Bank Account
    func testCanAddUSBankAccountBasedOnVerificationMethod() {
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        for verificationMethod in STPPaymentMethodOptions.USBankAccount.VerificationMethod.allCases {
            let usBankOptions = STPPaymentMethodOptions.USBankAccount(setupFutureUsage: nil,
                                                                      verificationMethod: verificationMethod,
                                                                      allResponseFields: [:])
            let paymentMethodOptions = STPPaymentMethodOptions(usBankAccount: usBankOptions,
                                                               allResponseFields: [:])
            let pi = STPFixtures.makePaymentIntent(paymentMethodTypes: [.USBankAccount],
                                                   setupFutureUsage: nil,
                                                   paymentMethodOptions: paymentMethodOptions,
                                                   shippingProvided: false)
            switch verificationMethod {
            case .automatic, .instantOrSkip, .instant:
                XCTAssertTrue(PaymentSheet.supportsAdding(
                    paymentMethod: .USBankAccount,
                    configuration: configuration,
                    intent: .paymentIntent(pi),
                    supportedPaymentMethods: [.USBankAccount])
                )

            case .skip, .microdeposits, .unknown:
                XCTAssertFalse(PaymentSheet.supportsAdding(
                    paymentMethod: .USBankAccount,
                    configuration: configuration,
                    intent: .paymentIntent(pi),
                    supportedPaymentMethods: [.USBankAccount])
                )
            }
        }
    }
}
