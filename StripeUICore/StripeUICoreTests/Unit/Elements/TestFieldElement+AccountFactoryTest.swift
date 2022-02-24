//
//  TestFieldElement+AccountFactoryTest.swift
//  StripeUICoreTests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import StripeUICore


class TextFieldElementAccountFactoryTest: XCTestCase {
    // MARK: - BSB
    func testBSBConfiguration_validBSB() {
        let bsb = TextFieldElement.Account.BSBConfiguration(defaultValue: nil)
        
        bsb.test(text: "000000", isOptional: false, matches: .valid)
        bsb.test(text: "082902", isOptional: false, matches: .valid)
    }

    func testBSBConfiguration_empty() {
        let bsb = TextFieldElement.Account.BSBConfiguration(defaultValue: nil)
        
        bsb.test(text: "", isOptional: false, matches: .invalid(TextFieldElement.Error.empty))
    }

    func testBSBConfiguration_incomplete() {
        let bsb = TextFieldElement.Account.BSBConfiguration(defaultValue: nil)
        
        bsb.test(text: "0", isOptional: false, matches: .invalid(TextFieldElement.Account.BSBConfiguration.incompleteError))
        bsb.test(text: "00", isOptional: false, matches: .invalid(TextFieldElement.Account.BSBConfiguration.incompleteError))
        bsb.test(text: "000", isOptional: false, matches: .invalid(TextFieldElement.Account.BSBConfiguration.incompleteError))
        bsb.test(text: "0000", isOptional: false, matches: .invalid(TextFieldElement.Account.BSBConfiguration.incompleteError))
        bsb.test(text: "00000", isOptional: false, matches: .invalid(TextFieldElement.Account.BSBConfiguration.incompleteError))
    }

    // MARK: - AU BECS Account Number
    func testAUBECSAccountNumberConfiguration_validAccountNumber() {
        let bsb = TextFieldElement.Account.AUBECSAccountNumberConfiguration(defaultValue: nil)

        bsb.test(text: "000123456", isOptional: false, matches: .valid)
    }

    func testAUBECSAccountNumberConfiguration_empty() {
        let bsb = TextFieldElement.Account.AUBECSAccountNumberConfiguration(defaultValue: nil)

        bsb.test(text: "", isOptional: false, matches: .invalid(TextFieldElement.Error.empty))
    }

    func testAUBECSAccountNumberConfiguration_incomplete() {
        let bsb = TextFieldElement.Account.AUBECSAccountNumberConfiguration(defaultValue: nil)

        bsb.test(text: "0", isOptional: false, matches: .invalid(TextFieldElement.Account.AUBECSAccountNumberConfiguration.incompleteError))
        bsb.test(text: "00", isOptional: false, matches: .invalid(TextFieldElement.Account.AUBECSAccountNumberConfiguration.incompleteError))
        bsb.test(text: "000", isOptional: false, matches: .invalid(TextFieldElement.Account.AUBECSAccountNumberConfiguration.incompleteError))
        bsb.test(text: "0001", isOptional: false, matches: .invalid(TextFieldElement.Account.AUBECSAccountNumberConfiguration.incompleteError))
        bsb.test(text: "00012", isOptional: false, matches: .invalid(TextFieldElement.Account.AUBECSAccountNumberConfiguration.incompleteError))
        bsb.test(text: "000123", isOptional: false, matches: .invalid(TextFieldElement.Account.AUBECSAccountNumberConfiguration.incompleteError))
        bsb.test(text: "0001234", isOptional: false, matches: .invalid(TextFieldElement.Account.AUBECSAccountNumberConfiguration.incompleteError))
        bsb.test(text: "00012345", isOptional: false, matches: .invalid(TextFieldElement.Account.AUBECSAccountNumberConfiguration.incompleteError))
    }

}

