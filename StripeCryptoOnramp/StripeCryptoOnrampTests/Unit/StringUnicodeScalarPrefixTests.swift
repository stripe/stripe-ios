//
//  StringUnicodeScalarPrefixTests.swift
//  StripeCryptoOnrampTests
//
//  Created by Michael Liberatore on 10/6/26.
//

@testable import StripeCryptoOnramp
import XCTest

final class StringUnicodeScalarPrefixTests: XCTestCase {
    func testPrefixHandlesBounds() {
        XCTAssertEqual(String("abc".prefix(unicodeScalarsCount: -1)), "")
        XCTAssertEqual(String("".prefix(unicodeScalarsCount: 0)), "")
        XCTAssertEqual(String("".prefix(unicodeScalarsCount: 3)), "")
        XCTAssertEqual(String("abc".prefix(unicodeScalarsCount: 0)), "")
        XCTAssertEqual(String("abc".prefix(unicodeScalarsCount: 2)), "ab")
        XCTAssertEqual(String("abc".prefix(unicodeScalarsCount: 3)), "abc")
        XCTAssertEqual(String("abc".prefix(unicodeScalarsCount: 4)), "abc")
    }

    func testPrefixKeepsMultiScalarCharactersWhole() {
        let accentedE = "é" // 2 Unicode scalars: U+0065, U+0301
        XCTAssertEqual(String(accentedE.prefix(unicodeScalarsCount: 1)), "")
        XCTAssertEqual(String(accentedE.prefix(unicodeScalarsCount: 2)), "é")

        let substringWithAccentedE = "aéb" // 4 Unicode scalars: U+0061, U+0065, U+0301, U+0062
        XCTAssertEqual(String(substringWithAccentedE.prefix(unicodeScalarsCount: 1)), "a")
        XCTAssertEqual(String(substringWithAccentedE.prefix(unicodeScalarsCount: 2)), "a")
        XCTAssertEqual(String(substringWithAccentedE.prefix(unicodeScalarsCount: 3)), "aé")
        XCTAssertEqual(String(substringWithAccentedE.prefix(unicodeScalarsCount: 4)), "aéb")

        let joinedEmoji = "👨‍💻" // 3 Unicode scalars: U+1F468, U+200D, U+1F4BB
        XCTAssertEqual(String(joinedEmoji.prefix(unicodeScalarsCount: 2)), "")
        XCTAssertEqual(String(joinedEmoji.prefix(unicodeScalarsCount: 3)), "👨‍💻")
    }
}
