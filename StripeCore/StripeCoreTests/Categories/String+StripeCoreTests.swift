//
//  String+StripeCoreTests.swift
//  StripeCoreTests
//
//  Test for String+StripeCore extension methods
//

import Foundation
@_spi(STP) @testable import StripeCore
import XCTest

final class String_StripeCoreTests: XCTestCase {

    // MARK: - stp_stringByRemovingCharacters tests

    func testRemovingCharacters_removesDigits() {
        let input = "abc123def456"
        let output = input.stp_stringByRemovingCharacters(from: .decimalDigits)
        XCTAssertEqual(output, "abcdef")
    }

    func testRemovingCharacters_removesWhitespace() {
        let input = "hello world test"
        let output = input.stp_stringByRemovingCharacters(from: .whitespaces)
        XCTAssertEqual(output, "helloworldtest")
    }

    func testRemovingCharacters_emptyString() {
        let input = ""
        let output = input.stp_stringByRemovingCharacters(from: .decimalDigits)
        XCTAssertEqual(output, "")
    }

    // MARK: - stp_stringByRemovingEmoji tests

    func testRemovingEmoji_removesBasicEmoji() {
        let input = "Hello 👋 World 🌍"
        let output = input.stp_stringByRemovingEmoji()
        XCTAssertEqual(output, "Hello  World ")
    }

    func testRemovingEmoji_keepsRegularText() {
        let input = "Hello World"
        let output = input.stp_stringByRemovingEmoji()
        XCTAssertEqual(output, "Hello World")
    }

    func testRemovingEmoji_keepsNumbers() {
        let input = "Test 123"
        let output = input.stp_stringByRemovingEmoji()
        XCTAssertEqual(output, "Test 123")
    }

    // MARK: - isSecretKey tests

    func testIsSecretKey_trueForSecretKey() {
        XCTAssertTrue("sk_test_123456".isSecretKey)
        XCTAssertTrue("sk_live_123456".isSecretKey)
        XCTAssertTrue("sk_".isSecretKey)
    }

    func testIsSecretKey_falseForPublicKey() {
        XCTAssertFalse("pk_test_123456".isSecretKey)
        XCTAssertFalse("pk_live_123456".isSecretKey)
    }

    func testIsSecretKey_falseForOtherStrings() {
        XCTAssertFalse("random_string".isSecretKey)
        XCTAssertFalse("".isSecretKey)
        XCTAssertFalse("sk".isSecretKey)
    }

    // MARK: - nonEmpty tests

    func testNonEmpty_returnsStringWhenNotEmpty() {
        let input = "hello"
        XCTAssertEqual(input.nonEmpty, "hello")
    }

    func testNonEmpty_returnsNilWhenEmpty() {
        let input = ""
        XCTAssertNil(input.nonEmpty)
    }

    // MARK: - sanitizedKey tests

    func testSanitizedKey_preservesPublicKey() {
        let publicKey = "pk_test_123456"
        XCTAssertEqual(publicKey.sanitizedKey, "pk_test_123456")
    }

    func testSanitizedKey_redactsSecretKey() {
        let secretKey = "sk_test_123456"
        XCTAssertEqual(secretKey.sanitizedKey, "[REDACTED_LIVE_KEY]")
    }

    func testSanitizedKey_redactsOtherKeys() {
        let otherKey = "rk_test_123456"
        XCTAssertEqual(otherKey.sanitizedKey, "[REDACTED_LIVE_KEY]")
    }
}
