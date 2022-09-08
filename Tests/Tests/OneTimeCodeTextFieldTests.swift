//
//  OneTimeCodeTextFieldTests.swift
//  StripeiOS Tests
//
//  Created by Ramon Torres on 11/5/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import XCTest
@_spi(STP) @testable import Stripe

class OneTimeCodeTextFieldTests: XCTestCase {

    func test_isComplete() {
        let field = makeSUT()

        field.value = "12345"
        XCTAssertFalse(field.isComplete)

        field.value = "123456"
        XCTAssertTrue(field.isComplete)
    }

    func test_insertText() {
        let field = makeSUT()

        field.insertText("1")
        XCTAssertEqual(field.value, "1")

        field.insertText("2")
        XCTAssertEqual(field.value, "12")
        XCTAssertEqual(field.selectedTextRange?.start, field.endOfDocument)
        XCTAssertEqual(field.selectedTextRange?.end, field.endOfDocument)
    }

    func test_insertText_shouldNotInsertBeyondNumberOfDigits() {
        let field = makeSUT(numberOfDigits: 4)
        field.value = "123"
        field.selectedTextRange = field.textRange(from: field.endOfDocument, to: field.endOfDocument)
        field.insertText("45")
        XCTAssertEqual(field.value, "1234")
    }

    func test_insertText_shouldIgnoreInvalidCharacters() {
        let field = makeSUT()
        field.insertText("123-456")
        XCTAssertEqual(field.value, "123456")
    }

    func test_deleteBackward() throws {
        let field = makeSUT(value: "12")

        field.selectedTextRange = field.textRange(
            from: try XCTUnwrap(field.position(from: field.endOfDocument, in: .left, offset: 1)),
            to: field.endOfDocument
        )
        field.deleteBackward()
        XCTAssertEqual(field.value, "1")

        field.selectedTextRange = field.textRange(
            from: try XCTUnwrap(field.position(from: field.endOfDocument, in: .left, offset: 1)),
            to: field.endOfDocument
        )
        field.deleteBackward()
        XCTAssertEqual(field.value, "")

        // Delete while empty
        field.selectedTextRange = field.textRange(from: field.beginningOfDocument, to: field.endOfDocument)
        field.deleteBackward()
        XCTAssertEqual(field.value, "")
    }

    func test_paste() {
        UIPasteboard.general.string = "123-456"

        let field = makeSUT()
        field.paste(nil)
        XCTAssertEqual(field.value, "123456")
    }

    // MARK: - UITextInput conformance

    func test_beginningOfDocument() throws {
        let field = makeSUT(value: "123456")

        let position = try XCTUnwrap(field.beginningOfDocument as? OneTimeCodeTextField.TextPosition)
        XCTAssertEqual(position.index, 0)
    }

    func test_endOfDocument() throws {
        let field = makeSUT(value: "123456")

        let position = try XCTUnwrap(field.endOfDocument as? OneTimeCodeTextField.TextPosition)
        XCTAssertEqual(position.index, 6)
    }

    func test_textInRange() {
        let field = makeSUT(value: "123456")

        let result = field.text(in: OneTimeCodeTextField.TextRange(
            start: OneTimeCodeTextField.TextPosition(0),
            end: OneTimeCodeTextField.TextPosition(3)
        ))

        XCTAssertEqual(result, "123")
    }

    func test_textInRange_emptyRange() {
        let field = makeSUT(value: "123456")

        let result = field.text(in: OneTimeCodeTextField.TextRange(
            start: OneTimeCodeTextField.TextPosition(0),
            end: OneTimeCodeTextField.TextPosition(0)
        ))

        XCTAssertNil(result)
    }

    func test_positionFromOffset() {
        let field = makeSUT(value: "123456")

        XCTAssertEqual(
            field.position(from: field.beginningOfDocument, offset: 3),
            OneTimeCodeTextField.TextPosition(3)
        )

        XCTAssertNil(
            field.position(from: field.beginningOfDocument, offset: 10),
            "Should return nil when offsetting to an out of bounds position"
        )

        XCTAssertNil(
            field.position(from: field.beginningOfDocument, offset: -1),
            "Should return nil when offsetting to an out of bounds position"
        )
    }

    func test_positionInDirection() {
        let field = makeSUT(value: "123456")

        XCTAssertEqual(
            field.position(from: field.beginningOfDocument, in: .right, offset: 1),
            OneTimeCodeTextField.TextPosition(1)
        )

        XCTAssertEqual(
            field.position(from: field.endOfDocument, in: .left, offset: 1),
            OneTimeCodeTextField.TextPosition(5)
        )

        // Y axis
        XCTAssertEqual(
            field.position(from: field.beginningOfDocument, in: .up, offset: 1),
            field.beginningOfDocument
        )

        XCTAssertEqual(
            field.position(from: field.beginningOfDocument, in: .down, offset: 1),
            field.endOfDocument
        )
    }

    func test_compare() {
        let field = makeSUT(value: "123456")

        XCTAssertEqual(
            field.compare(field.beginningOfDocument, to: field.beginningOfDocument),
            .orderedSame
        )

        XCTAssertEqual(
            field.compare(field.beginningOfDocument, to: field.endOfDocument),
            .orderedAscending
        )

        XCTAssertEqual(
            field.compare(field.endOfDocument, to: field.beginningOfDocument),
            .orderedDescending
        )
    }

    func test_offsetToPosition() {
        let field = makeSUT(value: "123456")

        XCTAssertEqual(field.offset(from: field.beginningOfDocument, to: field.endOfDocument), 6)
        XCTAssertEqual(field.offset(from: field.endOfDocument, to: field.beginningOfDocument), -6)
        XCTAssertEqual(field.offset(from: field.beginningOfDocument, to: OneTimeCodeTextField.TextPosition(3)), 3)
    }

    func test_positionFarthestInDirection() throws {
        let field = makeSUT(value: "123456")

        let position = try XCTUnwrap(
            OneTimeCodeTextField.TextRange(start: field.beginningOfDocument, end: field.endOfDocument)
        )

        XCTAssertEqual(
            field.position(within: position, farthestIn: .left),
            field.beginningOfDocument
        )

        XCTAssertEqual(
            field.position(within: position, farthestIn: .right),
            field.endOfDocument
        )

        // Y axis
        XCTAssertEqual(
            field.position(within: position, farthestIn: .up),
            field.beginningOfDocument
        )

        XCTAssertEqual(
            field.position(within: position, farthestIn: .down),
            field.endOfDocument
        )
    }

    func test_characterRangeByExtendingInDirection() throws {
        let field = makeSUT(value: "123456")

        let position = OneTimeCodeTextField.TextPosition(3)

        XCTAssertEqual(
            field.characterRange(byExtending: position, in: .left),
            OneTimeCodeTextField.TextRange(start: field.beginningOfDocument, end: position)
        )

        XCTAssertEqual(
            field.characterRange(byExtending: position, in: .right),
            OneTimeCodeTextField.TextRange(start: position, end: field.endOfDocument)
        )

        // Y axis
        XCTAssertNil(field.characterRange(byExtending: position, in: .up))
        XCTAssertNil(field.characterRange(byExtending: position, in: .down))
    }

    func test_firstRectForRange_singleDigit() {
        let sut = makeSUT(value: "123456")

        // A [0,1] text range
        let range = OneTimeCodeTextField.TextRange(
            start: OneTimeCodeTextField.TextPosition(0),
            end: OneTimeCodeTextField.TextPosition(1)
        )
        let rect = sut.firstRect(for: range)
        XCTAssertEqual(rect.minX, 0, accuracy: 0.2)
        XCTAssertEqual(rect.minY, 0, accuracy: 0.2)
        XCTAssertEqual(rect.width, 46.0, accuracy: 0.2)
        XCTAssertEqual(rect.height, 60, accuracy: 0.2)
    }

    func test_firstRectForRange_multipleDigits() {
        let sut = makeSUT(value: "123456")

        // A [0,3] Text range
        let range = OneTimeCodeTextField.TextRange(
            start: OneTimeCodeTextField.TextPosition(0),
            end: OneTimeCodeTextField.TextPosition(3)
        )
        let rect = sut.firstRect(for: range)
        XCTAssertEqual(rect.minX, 0, accuracy: 0.2)
        XCTAssertEqual(rect.minY, 0, accuracy: 0.2)
        XCTAssertEqual(rect.width, 150, accuracy: 0.2)
        XCTAssertEqual(rect.height, 60, accuracy: 0.2)
    }

    func test_caretRectForPosition() {
        let sut = makeSUT()
        let frame = sut.caretRect(for: OneTimeCodeTextField.TextPosition(1))
        XCTAssertEqual(frame.minX, 74, accuracy: 0.2)
        XCTAssertEqual(frame.minY, 18, accuracy: 0.2)
        XCTAssertEqual(frame.width, 2, accuracy: 0.2)
        XCTAssertEqual(frame.height, 24, accuracy: 0.2)
    }

}

// MARK: - Factory methods

private extension OneTimeCodeTextFieldTests {

    func makeSUT(numberOfDigits: Int = 6) -> OneTimeCodeTextField {
        let sut = OneTimeCodeTextField(numberOfDigits: numberOfDigits)
        sut.frame = CGRect(x: 0, y: 0, width: 320, height: 60)
        sut.layoutIfNeeded()
        return sut
    }

    func makeSUT(value: String) -> OneTimeCodeTextField {
        let sut = makeSUT()
        sut.value = value
        return sut
    }

}
