//
//  PaymentSheet+HelperTest.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 8/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class PaymentSheet_HelperTest: XCTestCase {

    /// Returns false, card not in `supportedPaymentMethods`
    func testSupportsAdding_notInSupportedList_noRequirementsNeeded() {
        XCTAssertFalse(PaymentSheet.supportsAdding(paymentMethod: .card,
                                                   with: [],
                                                   supportedPaymentMethods: []))
    }
    
    /// Returns true, card in `supportedPaymentMethods` and has no additional requirements
    func testSupportsAdding_inSupportedList_noRequirementsNeeded() {
        XCTAssertTrue(PaymentSheet.supportsAdding(paymentMethod: .card,
                                                  with: [],
                                                  supportedPaymentMethods: [.card]))
                                                  
    }
    
    /// Returns true, card in `supportedPaymentMethods` and has no additional requirements
    func testSupportsAdding_inSupportedList_noRequirementsNeededButProvided() {
        XCTAssertTrue(PaymentSheet.supportsAdding(paymentMethod: .card,
                                                  with: [MockURLRequirementProvider()],
                                                  supportedPaymentMethods: [.card]))
    }
    
    /// Returns true, iDEAL in `supportedPaymentMethods` and URL requirement and not setting up requirement are met
    func testSupportsAdding_inSupportedList_urlConfiguredRequired() {
        XCTAssertTrue(PaymentSheet.supportsAdding(paymentMethod: .iDEAL,
                                                  with: [MockURLRequirementProvider(), MockNotSettingUpRequirementProvider()],
                                                  supportedPaymentMethods: [.iDEAL]))
    }
    
    /// Returns true, iDEAL in `supportedPaymentMethods` but URL requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredRequiredButNotProvided() {
        XCTAssertFalse(PaymentSheet.supportsAdding(paymentMethod: .iDEAL,
                                                  with: [MockShippingRequirementProvider()],
                                                  supportedPaymentMethods: [.iDEAL]))
    }
    
    /// Returns false, Afterpay in `supportedPaymentMethods` but shipping requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_missingSihpping() {
        XCTAssertFalse(PaymentSheet.supportsAdding(paymentMethod: .afterpayClearpay,
                                                   with: [MockURLRequirementProvider()],
                                                   supportedPaymentMethods: [.afterpayClearpay]))
    }
    
    /// Returns false, Afterpay in `supportedPaymentMethods` but URL requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_missingURL() {
        XCTAssertFalse(PaymentSheet.supportsAdding(paymentMethod: .afterpayClearpay,
                                                   with: [MockShippingRequirementProvider()],
                                                   supportedPaymentMethods: [.afterpayClearpay]))
    }
    
    /// Returns true, Afterpay in `supportedPaymentMethods` and both URL ands shipping requirements are met
    func testSupportsAdding_inSupportedList_urlConfiguredAndShippingRequired_bothMet() {
        XCTAssertTrue(PaymentSheet.supportsAdding(paymentMethod: .afterpayClearpay,
                                                  with: [MockURLRequirementProvider(), MockShippingRequirementProvider()],
                                                  supportedPaymentMethods: [.afterpayClearpay]))
    }
    
    private struct MockNotSettingUpRequirementProvider: PaymentMethodRequirementProvider {
        var fufilledRequirements: Set<STPPaymentMethodType.PaymentMethodTypeRequirement> {
            return Set(arrayLiteral: .notSettingUp)
        }
    }
    private struct MockURLRequirementProvider: PaymentMethodRequirementProvider {
        var fufilledRequirements: Set<STPPaymentMethodType.PaymentMethodTypeRequirement> {
            var reqs = Set<STPPaymentMethodType.PaymentMethodTypeRequirement>()
            reqs.insert(.returnURL)
            return reqs
        }
    }
    
    private struct MockShippingRequirementProvider: PaymentMethodRequirementProvider {
        var fufilledRequirements: Set<STPPaymentMethodType.PaymentMethodTypeRequirement> {
            var reqs = Set<STPPaymentMethodType.PaymentMethodTypeRequirement>()
            reqs.insert(.shippingAddress)
            return reqs
        }
    }
    
}
