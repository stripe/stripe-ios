//
//  PhoneNumberElementSnapshotTests.swift
//  StripeUICoreTests
//
//  Created by Cameron Sabol on 10/20/21.
//

import FBSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore

class PhoneNumberElementSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
//        recordMode = true
    }
    
    func testEmptyUS() {
        let sut = PhoneNumberElement(defaultCountry: "US")
        verify(sut)
    }

    func testEmptyGB() {
        let sut = PhoneNumberElement(defaultCountry: "GB")
        verify(sut)
    }

    func testFilledUS() {
        let sut = PhoneNumberElement(defaultValue: "3105551234", defaultCountry: "US")
        verify(sut)
    }

    func testFilledGB() {
        let sut = PhoneNumberElement(defaultValue: "442071838750", defaultCountry: "GB")
        verify(sut)
    }

    func verify(
        _ sut: PhoneNumberElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let view = sut.view
        view.autosizeHeight(width: 200)
        STPSnapshotVerifyView(view, file: file, line: line)
    }

}
