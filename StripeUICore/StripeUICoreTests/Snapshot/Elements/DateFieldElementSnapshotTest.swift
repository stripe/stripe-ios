//
//  DateFieldElementSnapshotTest.swift
//  StripeUICoreTests
//
//  Created by Mel Ludowise on 10/1/21.
//

import FBSnapshotTestCase
import StripeCoreTestUtils
@_spi(STP) @testable import StripeUICore

final class DateFieldElementSnapshotTest: FBSnapshotTestCase {

    // Use consistent locale and timezone for consistent test results
    let locale_enUS = Locale(identifier: "en_US")
    let timeZone_GMT = TimeZone(secondsFromGMT: 0)!

    // Mock dates
    let oct1_2021 = Date(timeIntervalSince1970: 1633046400)
    let oct3_2021 = Date(timeIntervalSince1970: 1633219200)

    override func setUp() {
        super.setUp()
//        recordMode = true
    }

    func testNoDefaultUnfocused() {
        let dateFieldElement = makeDateFieldElement()
        verify(dateFieldElement)
    }

    func testNoDefaultFocused() {
        // Setting a max date to the past makes the UIDatePicker default to that
        // date instead of the current date, giving us consistent UI to test.
        let dateFieldElement = makeDateFieldElement(
            maximumDate: oct1_2021
        )
        dateFieldElement.didBeginEditing(dateFieldElement.pickerFieldView)
        verify(dateFieldElement)
    }

    func testDefault() {
        let dateFieldElement = makeDateFieldElement(
            defaultDate: oct1_2021
        )
        verify(dateFieldElement)
    }

    func testChangeInput() {
        let dateFieldElement = makeDateFieldElement(
            defaultDate: oct1_2021
        )
        dateFieldElement.datePickerView.date = oct3_2021

        // Emulate a user changing the picker
        dateFieldElement.didSelectDate()

        verify(dateFieldElement)
    }
}

// MARK: - Helpers

private extension DateFieldElementSnapshotTest {
    func makeDateFieldElement(
        defaultDate: Date? = nil,
        maximumDate: Date? = nil
    ) -> DateFieldElement {
        return DateFieldElement(
            label: "Label",
            defaultDate: defaultDate,
            maximumDate: maximumDate,
            locale: locale_enUS,
            timeZone: timeZone_GMT
        )
    }

    func verify(_ dateFieldElement: DateFieldElement,
                file: StaticString = #filePath,
                line: UInt = #line) {
        let view = dateFieldElement.view
        view.autosizeHeight(width: 200)
        STPSnapshotVerifyView(view, file: file, line: line)
    }
}
