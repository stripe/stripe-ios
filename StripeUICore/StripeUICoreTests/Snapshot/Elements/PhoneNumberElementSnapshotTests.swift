//
//  PhoneNumberElementSnapshotTests.swift
//  StripeUICoreTests
//
//  Created by Yuki Tokuhiro on 6/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import StripeCoreTestUtils
@_spi(STP)@testable import StripeUICore
import iOSSnapshotTestCase

class PhoneNumberElementSnapshotTests: FBSnapshotTestCase {

    override func setUp() {
        super.setUp()
        //        recordMode = true
    }

    func testEmptyUS() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            defaultCountryCode: "US",
            locale: Locale(identifier: "en_US")
        )
        verify(sut)
    }

    func testEmptyGB() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["GB"],
            defaultCountryCode: "GB",
            locale: Locale(identifier: "en_GB")
        )
        verify(sut)
    }

    func testFilledUS() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["US"],
            defaultCountryCode: "US",
            defaultPhoneNumber: "3105551234",
            locale: Locale(identifier: "en_US")
        )
        verify(sut)
    }

    func testFilledGB() {
        let sut = PhoneNumberElement(
            allowedCountryCodes: ["GB"],
            defaultCountryCode: "GB",
            defaultPhoneNumber: "02071838750",
            locale: Locale(identifier: "en_GB")
        )
        verify(sut)
    }

    func testFilledHU() {
        let sut = PhoneNumberElement(
            defaultCountryCode: "HU",
            defaultPhoneNumber: "12345678",
            locale: Locale(identifier: "hu_HU")
        )
        verify(sut)
    }

    func testFilledHU_national() {
        let sut = PhoneNumberElement(
            defaultCountryCode: "HU",
            defaultPhoneNumber: "0612345678",
            locale: Locale(identifier: "hu_HU")
        )
        verify(sut)
    }

    func verify(
        _ sut: PhoneNumberElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let section = SectionElement(elements: [sut])
        let view = section.view
        view.autosizeHeight(width: 320)
        STPSnapshotVerifyView(view, file: file, line: line)
    }

}
