//
//  STPImageLibraryTest.swift
//  StripeiOS Tests
//
//  Created by Cameron Sabol on 4/7/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class STPImageLibraryTestSwift: XCTestCase {

    func testBankIconCodeImagesExist() {
        for iconCode in STPImageLibrary.BankIconCodeRegexes.keys {
            XCTAssertNotNil(STPImageLibrary.bankIcon(for: iconCode), "Missing image for \(iconCode)")
        }
    }

    func testBankNameToIconCode() {
        // bank of america
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "bank of america"), "boa")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "BANK of AMERICA"), "boa")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "BANKof AMERICA"), "default")


        // capital one
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "capital one"), "capitalone")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Capital One"), "capitalone")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Capital      One"), "default")

        // citibank
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "citibank"), "citibank")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Citibank"), "citibank")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Citi Bank"), "default")

        // compass
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "bbva"), "compass")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "BBVA"), "compass")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "compass"), "compass")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "b b v a"), "default")

        // morganchase
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Morgan Chase"), "morganchase")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "morgan chase"), "morganchase")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "jp morgan"), "morganchase")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "JP Morgan"), "morganchase")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Chase"), "morganchase")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "chase"), "morganchase")

        // pnc
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "pncbank"), "pnc")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "PNCBANK"), "pnc")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "pnc bank"), "pnc")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "PNC Bank"), "pnc")

        // suntrust
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "suntrust"), "suntrust")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "SUNTRUST"), "suntrust")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "suntrust bank"), "suntrust")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Suntrust Bank"), "suntrust")

        // svb
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Silicon Valley Bank"), "svb")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "SILICON VALLEY BANK"), "svb")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "SILICONVALLEYBANK"), "default")

        // usaa
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "USAA Federal Savings Bank"), "usaa")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "USAA Bank"), "usaa")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "USAA Savings Bank"), "default")

        // usbank
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "US Bank"), "usbank")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "U.S. Bank"), "usbank")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "u.s. Bank"), "usbank")

        // wellsfargo
        XCTAssertEqual(STPImageLibrary.bankIconCode(for:"Wells Fargo"), "wellsfargo")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "WELLS FARGO"), "wellsfargo")
        XCTAssertEqual(STPImageLibrary.bankIconCode(for: "Well's Fargo"), "default")
    }

}
