//
//  OneTimeCodeTextFieldTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/5/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import XCTest
@_spi(STP) @testable import Stripe

class OneTimeCodeTextFieldTests: XCTestCase {

    func testIsComplete() {
        let codeField = OneTimeCodeTextField(numberOfDigits: 6)

        codeField.value = "12345"
        XCTAssertFalse(codeField.isComplete)

        codeField.value = "123456"
        XCTAssertTrue(codeField.isComplete)
    }

    func testInsertText() {
        let codeField = OneTimeCodeTextField()

        codeField.insertText("1")
        XCTAssertEqual(codeField.value, "1")

        codeField.insertText("2")
        XCTAssertEqual(codeField.value, "12")
    }

    func testInsertText_shouldNotInsertBeyondNumberOfDigits() {
        let codeField = OneTimeCodeTextField(numberOfDigits: 4)
        codeField.value = "123"
        codeField.insertText("45")
        XCTAssertEqual(codeField.value, "1234")
    }

    func testInsertText_shouldIgnoreInvalidCharacters() {
        let codeField = OneTimeCodeTextField(numberOfDigits: 6)
        codeField.insertText("123-456")
        XCTAssertEqual(codeField.value, "123456")
    }

    func testDeleteBackward() {
        let codeField = OneTimeCodeTextField()
        codeField.value = "12"

        codeField.deleteBackward()
        XCTAssertEqual(codeField.value, "1")

        codeField.deleteBackward()
        XCTAssertEqual(codeField.value, "")

        // Delete while empty
        codeField.deleteBackward()
        XCTAssertEqual(codeField.value, "")
    }

    func testPaste() {
        UIPasteboard.general.string = "123-456"

        let codeField = OneTimeCodeTextField()
        codeField.paste(nil)
        XCTAssertEqual(codeField.value, "123456")
    }

}
