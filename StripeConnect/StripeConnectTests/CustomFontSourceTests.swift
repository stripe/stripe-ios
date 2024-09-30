//
//  CustomFontSourceTests.swift
//  StripeConnectTests
//
//  Created by Chris Mays on 9/6/24.
//

@_spi(PrivateBetaConnect) @testable import StripeConnect
import UIKit
import XCTest

class CustomFontSourceTests: XCTestCase {
    typealias FontSource = EmbeddedComponentManager.CustomFontSource

    func testHTTPURLProvided() {
        do {
            _ = try FontSource(font: .init(), fileUrl: URL(string: "https://stripe.com")!)
            XCTFail("Expected an error to be thrown")
        } catch {
            XCTAssertEqual(error as? FontSource.FontLoadError, FontSource.FontLoadError.notFileURL)
        }
    }

    func testFakeLocalURL() {
        do {
            _ = try FontSource(font: .systemFont(ofSize: 12), fileUrl: URL(string: "file:///path/to/nonexistent/file.txt")!)
            XCTFail("Expected an error to be thrown")
        } catch {
            // No such file error
            XCTAssertEqual((error as NSError).code, 260)
        }
    }

    func testLoadingFont() throws {
        let fileURL = try fakeFontURL()
        let fontSource = try FontSource(font: .systemFont(ofSize: 12), fileUrl: fileURL)

        XCTAssertEqual(fontSource.family, ".AppleSystemUIFont")
        XCTAssertEqual(fontSource.weight, "400")
        XCTAssertEqual(fontSource.src.stringValue, "url(data:font/txt;charset=utf-8;base64,dGVzdAo=)")
    }

    func testHelveticaFont() throws {
        let fileURL = try fakeFontURL()
        let font = helveticaFont()
        let fontSource = try FontSource(font: font, fileUrl: fileURL)

        XCTAssertEqual(fontSource.family, "Helvetica")
        XCTAssertEqual(fontSource.weight, "400")
        XCTAssertEqual(fontSource.src.stringValue, "url(data:font/txt;charset=utf-8;base64,dGVzdAo=)")
    }

    func testLoadingItalicFont() throws {
        let fileURL = try fakeFontURL()
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
            .withSymbolicTraits([.traitBold, .traitItalic])!
            .withDesign(.default)!

        let boldItalicFont = UIFont(descriptor: descriptor, size: 12)
        let font = try FontSource(font: boldItalicFont, fileUrl: fileURL)

        XCTAssertEqual(font.family, ".AppleSystemUIFont")
        XCTAssertEqual(font.weight, "600")
        XCTAssertEqual(font.style, "italic")
        XCTAssertEqual(font.src.stringValue, "url(data:font/txt;charset=utf-8;base64,dGVzdAo=)")
    }

    func testFontWeight() throws {
        let fontWeights: [UIFont.Weight] = [
            .ultraLight,
            .thin,
            .light,
            .regular,
            .medium,
            .semibold,
            .bold,
            .heavy,
            .black,
        ]

        try fontWeights.forEach { weight in
            let font = UIFont.systemFont(ofSize: 22, weight: weight)
            let testBundle = Bundle(for: type(of: self))
            let fileURL = try XCTUnwrap(testBundle.url(forResource: "FakeFont", withExtension: "txt"))

            let fontSource = try FontSource(font: font, fileUrl: fileURL)

            XCTAssertEqual(fontSource.weight, weight.cssValue)
        }
    }

    func fakeFontURL() throws -> URL {
        let testBundle = Bundle(for: type(of: self))
        return try XCTUnwrap(testBundle.url(forResource: "FakeFont", withExtension: "txt"))
    }

    func helveticaFont(weight: UIFont.Weight = .regular) -> UIFont {
        let traits = [UIFontDescriptor.TraitKey.weight: weight.rawValue]
        let attributes: [UIFontDescriptor.AttributeName: Any] = [
            .family: "Helvetica",
            .traits: traits,
        ]
        let descriptor = UIFontDescriptor(fontAttributes: attributes)
        return UIFont(descriptor: descriptor, size: 12)
    }
}
