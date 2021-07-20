//
//  TextFieldElement+IBANTest.swift
//  StripeiOS Tests
//
//  Created by Yuki Tokuhiro on 5/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class TextFieldElementIBANTest: XCTestCase {
    typealias IBANError = TextFieldElement.IBANError
    typealias Error = TextFieldElement.Error
    
    func testValidation() throws {
        let testcases: [String: TextFieldElement.ValidationState] = [
            "": .invalid(Error.empty),
            "G": .invalid(IBANError.incomplete),
            "GB": .invalid(IBANError.incomplete),
            "GB1": .invalid(IBANError.incomplete),
            "GB12": .invalid(IBANError.incomplete),
            
            "1": .invalid(IBANError.shouldStartWithCountryCode),
            "12": .invalid(IBANError.shouldStartWithCountryCode),
            "Z1": .invalid(IBANError.shouldStartWithCountryCode),
            "🤦🏻🇺🇸": .invalid(IBANError.shouldStartWithCountryCode),
            
            "ZZ": .invalid(IBANError.invalidCountryCode(countryCode: "ZZ")),
            
            "GB82WEST12345698765432🇺🇸": .invalid(IBANError.invalidFormat),
            "GB94BARC20201530093459": .invalid(IBANError.invalidFormat), // https://www.iban.com/testibans
            
            "GB33BUKB20201555555555": .valid,
            "GB94BARC10201530093459": .valid,
            "SK6902000000001933504555": .valid,
            "BG09STSA93000021741508": .valid,
            "FR1420041010050500013M02606": .valid,
            "AT611904300234573201": .valid,
            "AT861904300235473202": .valid,
        ]
        
        let config = TextFieldElement.IBANConfiguration()
        for (text, expected) in testcases {
            let actual = config.validate(text: text, isOptional: false)
            XCTAssertTrue(
                actual == expected,
                "Input \"\(text)\": expected \(expected) but got \(actual)"
            )
        }
    }

    func testValidateCountryCode() {
        let testcases: [String: ValidationState] = [
            "": .invalid(IBANError.incomplete),
            "A": .invalid(IBANError.incomplete),
            "D": .invalid(IBANError.incomplete),
            
            "ū": .invalid(IBANError.shouldStartWithCountryCode),
            "1": .invalid(IBANError.shouldStartWithCountryCode),
            ".": .invalid(IBANError.shouldStartWithCountryCode),
            
            "AT": .valid,
            "DE": .valid,
        ]
        for (test, expected) in testcases {
            let actual = TextFieldElement.IBANConfiguration.validateCountryCode(test)
            XCTAssertTrue(actual == expected)
        }
    }
    
    func testTransformToASCIIDigits() {
        let testcases: [String: String] = [
            "": "",
            "1234": "1234",
            "GB82": "161182",
            "AAAA": "10101010",
            "ZZZZ": "35353535",
        ]
        for (test, expected) in testcases {
            let actual = TextFieldElement.IBANConfiguration.transformToASCIIDigits(test)
            XCTAssertTrue(actual == expected)
        }
    }
    
    func testMod97() {
        let testcases: [String: Int?] = [
            "0": 0,
            "97": 0,
            "96": 96,
            "00001": 1,
            "13985713857180375018375081735081735": 15,
            "13985713857180375018375081735081720": 0,
        ]
        for (test, expected) in testcases {
            let actual = TextFieldElement.IBANConfiguration.mod97(test)
            XCTAssertTrue(actual == expected)
        }
        
        for _ in 0...100 {
            let test = Int.random(in: 0...Int.max)
            let actual = TextFieldElement.IBANConfiguration.mod97(String(test))
            XCTAssertTrue(actual == test % 97)
        }
    }
}
