//
//  ParsedEnumTests.swift
//  StripeCoreTests
//

import Foundation
@_spi(STP)@testable import StripeCore
import XCTest

private enum Color: String, SafeParsedEnumCodable {
    case red = "RED"
    case blue = "BLUE"
}

private struct Container: Codable {
    let color: ParsedEnum<Color>
    let colors: [ParsedEnum<Color>]
}

class ParsedEnumTests: XCTestCase {

    // MARK: - Decoding

    func test_decodesKnownValue() throws {
        let json = #"{"color":"RED","colors":["RED","BLUE"]}"#
        let result = try JSONDecoder().decode(Container.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(result.color.value, .red)
        XCTAssertEqual(result.color.rawValue, "RED")
    }

    func test_decodesUnknownValue() throws {
        let json = #"{"color":"GREEN","colors":[]}"#
        let result = try JSONDecoder().decode(Container.self, from: json.data(using: .utf8)!)
        XCTAssertNil(result.color.value)
        XCTAssertEqual(result.color.rawValue, "GREEN")
        XCTAssertTrue(result.color.isUnparsed)
    }

    func test_decodesArrayOfMixed() throws {
        let json = #"{"color":"RED","colors":["RED","GREEN","BLUE"]}"#
        let result = try JSONDecoder().decode(Container.self, from: json.data(using: .utf8)!)
        XCTAssertEqual(result.colors[0].value, .red)
        XCTAssertNil(result.colors[1].value)
        XCTAssertEqual(result.colors[1].rawValue, "GREEN")
        XCTAssertEqual(result.colors[2].value, .blue)
    }

    // MARK: - Encoding

    func test_encodesKnownValue() throws {
        let container = Container(color: ParsedEnum(.red), colors: [])
        let data = try JSONEncoder().encode(container)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["color"] as? String, "RED")
    }

    func test_encodesUnknownValuePreservingRawString() throws {
        let container = Container(color: ParsedEnum(rawValue: "GREEN"), colors: [])
        let data = try JSONEncoder().encode(container)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["color"] as? String, "GREEN")
    }

    // MARK: - Hashable / Equatable

    func test_equalityBasedOnRawValue() {
        XCTAssertEqual(ParsedEnum<Color>(.red), ParsedEnum(rawValue: "RED"))
        XCTAssertNotEqual(ParsedEnum<Color>(.red), ParsedEnum(.blue))
        XCTAssertNotEqual(ParsedEnum<Color>(.red), ParsedEnum(rawValue: "green"))
    }

    func test_setDeduplicationByRawValue() {
        let set: Set<ParsedEnum<Color>> = [ParsedEnum(.red), ParsedEnum(rawValue: "RED")]
        XCTAssertEqual(set.count, 1)
    }

    func test_unknownValuesHashableInSet() {
        let set: Set<ParsedEnum<Color>> = [ParsedEnum(rawValue: "GREEN"), ParsedEnum(rawValue: "GREEN")]
        XCTAssertEqual(set.count, 1)
    }

    // MARK: - Convenience operators

    func test_comparisonWithEnumValue() {
        let parsed = ParsedEnum<Color>(.red)
        XCTAssertTrue(parsed == Color.red)
        XCTAssertFalse(parsed == Color.blue)
    }

    func test_comparisonWithUnknownValue() {
        let parsed = ParsedEnum<Color>(rawValue: "GREEN")
        XCTAssertFalse(parsed == Color.red)
        XCTAssertFalse(parsed == Color.blue)
    }

    // MARK: - Set convenience extension

    func test_setContainsEnumValue() {
        let set: Set<ParsedEnum<Color>> = [ParsedEnum(.red), ParsedEnum(rawValue: "GREEN")]
        XCTAssertTrue(set.contains(Color.red))
        XCTAssertFalse(set.contains(Color.blue))
    }

    func test_setInsertEnumValue() {
        var set: Set<ParsedEnum<Color>> = []
        set.insert(Color.red)
        XCTAssertTrue(set.contains(Color.red))
        XCTAssertEqual(set.count, 1)
    }
}
