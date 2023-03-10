//
//  DateFieldElementTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 10/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP)@testable import StripeUICore
import XCTest

final class DateFieldElementTest: XCTestCase {
    // Mock dates
    let oct1_2021 = Date(timeIntervalSince1970: 1633046400)
    let oct3_2021 = Date(timeIntervalSince1970: 1633219200)

    func testNoDefault() {
        let element = DateFieldElement(label: "")
        XCTAssertNil(element.selectedDate)
        XCTAssertFalse(element.validationState.isValid)
    }

    func testWithDefault() {
        let element = DateFieldElement(label: "", defaultDate: oct1_2021)
        XCTAssertEqual(element.selectedDate, oct1_2021)
        XCTAssertTrue(element.validationState.isValid)
    }

    func testDefaultExceedsMax() {
        let element = DateFieldElement(label: "", defaultDate: oct3_2021, maximumDate: oct1_2021)
        XCTAssertNil(element.selectedDate)
    }

    func testDefaultExceedsMin() {
        let element = DateFieldElement(label: "", defaultDate: oct1_2021, minimumDate: oct3_2021)
        XCTAssertNil(element.selectedDate)
    }

    func testCustomDateformatter() {
        let timeZone = TimeZone(secondsFromGMT: 0)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMddyyyy"

        let element = DateFieldElement(timeZone: timeZone!, customDateFormatter: dateFormatter)
        // Emulate a user changing the picker and hitting done button
        element.datePickerView.date = oct3_2021
        element.didSelectDate()
        element.didFinish(element.pickerFieldView)

        XCTAssertEqual(element.pickerFieldView.displayText, "10032021")
    }

    func testDidUpdate() {
        var date: Date?
        let element = DateFieldElement(label: "", didUpdate: { date = $0 })
        XCTAssertNil(date)
        // Emulate a user changing the picker and hitting done button
        element.datePickerView.date = oct3_2021
        element.didSelectDate()
        element.didFinish(element.pickerFieldView)
        XCTAssertEqual(date, oct3_2021)
    }

    func testDidUpdateToDefault() {
        // Ensure `didUpdate` is not called if the selection doesn't change

        var date: Date?
        let element = DateFieldElement(label: "", defaultDate: oct1_2021, didUpdate: { date = $0 })
        XCTAssertNil(date)

        // Emulate a user changing the picker
        element.datePickerView.date = oct3_2021
        element.didSelectDate()
        XCTAssertNil(date)

        // Emulate the user changing the picker back
        element.datePickerView.date = oct1_2021
        element.didSelectDate()
        XCTAssertNil(date)

        // Emulate user hitting the done button
        element.didFinish(element.pickerFieldView)
        XCTAssertNil(date)
    }
}
