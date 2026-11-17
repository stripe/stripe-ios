//
//  InlineContractTests.swift
//  StripeConnectTests
//

@testable import StripeConnect
import XCTest

class InlineContractTests: XCTestCase {
    private let componentURL = StripeConnectConstants.connectJSBaseURL

    private func sheetId(_ url: String) -> String? {
        InlineContract.sheetId(fromWindowURL: URL(string: url)!, componentURL: componentURL)
    }

    // MARK: - Sheet window URLs

    func testAcceptsAccessoryLayerWindowAtComponentOrigin() {
        XCTAssertEqual(sheetId("https://connect-js.stripe.com/accessory_layer_0123abcdef.html#layer_type=overlay&os_sheet=true&os_sheet_id=sheet-1"), "sheet-1")
    }

    func testAcceptsExplicitDefaultPort() {
        XCTAssertEqual(sheetId("https://connect-js.stripe.com:443/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1"), "sheet-1")
    }

    func testAcceptsUppercaseHost() {
        XCTAssertEqual(sheetId("https://CONNECT-JS.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1"), "sheet-1")
    }

    func testAcceptsPercentEncodedSheetId() {
        XCTAssertEqual(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet%2D1"), "sheet-1")
    }

    func testRejectsLookalikeHost() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com.evil.example/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsSubdomainOfComponentHost() {
        XCTAssertNil(sheetId("https://evil.connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsUserInfo() {
        XCTAssertNil(sheetId("https://user@connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsWrongPort() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com:8443/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsHTTP() {
        XCTAssertNil(sheetId("http://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsWrongPath() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/ios_webview.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsFolderPath() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/v1.0/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsAccessoryLayerPathWithoutHash() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsAccessoryLayerPathWithNonAlphanumericHash() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_ab%2Fc.html#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsAboutBlank() {
        XCTAssertNil(sheetId("about:blank#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsDataURL() {
        XCTAssertNil(sheetId("data:text/html,hello#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsJavaScriptURL() {
        XCTAssertNil(sheetId("javascript:alert(1)//#os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsMissingOSSheet() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet_id=sheet-1"))
    }

    func testRejectsOSSheetThatIsNotTrue() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=false&os_sheet_id=sheet-1"))
    }

    func testRejectsMissingHash() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html"))
    }

    func testRejectsDuplicateSheetIdParam() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=sheet-1&os_sheet_id=sheet-2"))
    }

    func testRejectsDuplicateOSSheetParam() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsDuplicateUnrelatedParam() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#layer_type=overlay&layer_type=overlay&os_sheet=true&os_sheet_id=sheet-1"))
    }

    func testRejectsEmptySheetId() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id="))
    }

    func testRejectsSheetIdWithInvalidCharacters() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=__proto__"))
    }

    func testRejectsSheetIdWithEncodedQuote() {
        XCTAssertNil(sheetId("https://connect-js.stripe.com/accessory_layer_abc.html#os_sheet=true&os_sheet_id=a%22b"))
    }

    // MARK: - Sheet requests

    func testWindowWithOSSheetIsSheetRequest() {
        XCTAssertTrue(InlineContract.isSheetRequest(URL(string: "https://evil.example/x#os_sheet=true")!))
    }

    func testWindowWithDuplicateOSSheetIsSheetRequest() {
        XCTAssertTrue(InlineContract.isSheetRequest(URL(string: "https://evil.example/x#os_sheet=true&os_sheet=true")!))
    }

    func testWindowWithoutOSSheetIsNotSheetRequest() {
        XCTAssertFalse(InlineContract.isSheetRequest(URL(string: "https://connect.stripe.com/help#section=1")!))
    }

    // MARK: - Sheet ids

    func testAcceptsSheetIdOf64Characters() {
        XCTAssertTrue(InlineContract.isValidSheetId(String(repeating: "a", count: 64)))
    }

    func testRejectsSheetIdLongerThan64Characters() {
        XCTAssertFalse(InlineContract.isValidSheetId(String(repeating: "a", count: 65)))
    }

    func testAcceptsUUIDSheetId() {
        XCTAssertTrue(InlineContract.isValidSheetId("0b7f3c1e-8d2a-4c5b-9e6f-1a2b3c4d5e6f"))
    }

    func testRejectsNonASCIISheetId() {
        XCTAssertFalse(InlineContract.isValidSheetId("shéet"))
    }

    // MARK: - Origins

    func testMatchesComponentOriginWithDefaultPortReportedAsZero() {
        XCTAssertTrue(InlineContract.isOrigin(scheme: "https", host: "connect-js.stripe.com", port: 0, of: componentURL))
    }

    func testMatchesComponentOriginWithExplicitDefaultPort() {
        XCTAssertTrue(InlineContract.isOrigin(scheme: "https", host: "connect-js.stripe.com", port: 443, of: componentURL))
    }

    func testDoesNotMatchOtherHost() {
        XCTAssertFalse(InlineContract.isOrigin(scheme: "https", host: "connect.stripe.com", port: 0, of: componentURL))
    }

    func testDoesNotMatchOtherPort() {
        XCTAssertFalse(InlineContract.isOrigin(scheme: "https", host: "connect-js.stripe.com", port: 8443, of: componentURL))
    }

    func testDoesNotMatchOtherScheme() {
        XCTAssertFalse(InlineContract.isOrigin(scheme: "http", host: "connect-js.stripe.com", port: 0, of: componentURL))
    }

    func testDoesNotMatchOpaqueOrigin() {
        XCTAssertFalse(InlineContract.isOrigin(scheme: "", host: "", port: 0, of: componentURL))
    }

    // MARK: - Heights

    func testKeepsHeightInRange() {
        XCTAssertEqual(InlineContract.clampedHeight(248), 248)
    }

    func testClampsHeightAboveMaximum() {
        XCTAssertEqual(InlineContract.clampedHeight(20_000), 10_000)
    }

    func testClampsNegativeHeightToZero() {
        XCTAssertEqual(InlineContract.clampedHeight(-10), 0)
    }

    func testRejectsNaNHeight() {
        XCTAssertNil(InlineContract.clampedHeight(.nan))
    }

    func testRejectsInfiniteHeight() {
        XCTAssertNil(InlineContract.clampedHeight(.infinity))
    }
}
