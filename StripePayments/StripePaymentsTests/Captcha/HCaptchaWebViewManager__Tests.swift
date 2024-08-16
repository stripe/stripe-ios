//
//  HCaptchaWebViewManager__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 13/04/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import StripePayments

import WebKit
import XCTest

class HCaptchaWebViewManager__Tests: XCTestCase {

    fileprivate var apiKey: String!
    fileprivate var presenterView: UIView!

    override func setUp() {
        super.setUp()

        presenterView = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController?.view
        apiKey = UUID().uuidString
    }

    override func tearDown() {
        presenterView = nil
        apiKey = nil

        super.tearDown()
    }

    // MARK: Validate

    func test__Validate__Token() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "load token")
        var result1: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey)
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { response in
            result1 = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10)

        // Verify
        XCTAssertNotNil(result1)
        XCTAssertNil(result1?.error)
        XCTAssertEqual(result1?.token, apiKey)

        // Validate again
        let exp2 = expectation(description: "reload token")
        var result2: HCaptchaResult?

        // Validate
        manager.validate(on: presenterView) { response in
            result2 = response
            exp2.fulfill()
        }

        waitForExpectations(timeout: 10)

        // Verify
        XCTAssertNotNil(result2)
        XCTAssertNil(result2?.error)
        XCTAssertEqual(result2?.token, apiKey)
    }

    func test__Validate__Show_HCaptcha() {
        let exp = expectation(description: "show hcaptcha")

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.configureWebView { _ in
            exp.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: 10)
    }

    func test__Validate__Message_Error() {
        let exp0 = expectation(description: "should call configureWebView")
        var result: HCaptchaResult?
        let exp1 = expectation(description: "message error")

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "\"foobar\"")
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView, resetOnError: false) { response in
            result = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10)

        // Verify
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.error, .wrongMessageFormat)
        XCTAssertNil(result?.token)
    }

    func test__Validate__JS_Error() {
        var result: HCaptchaResult?
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "js error")

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "foobar")
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView, resetOnError: false) { response in
            result = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10)

        // Verify
        XCTAssertNotNil(result)
        XCTAssertNotNil(result?.error)
        XCTAssertNil(result?.token)

        switch result?.error {
        case .unexpected(let error as NSError):
            XCTAssertEqual(error.code, WKError.javaScriptExceptionOccurred.rawValue)
        default:
            XCTFail("Unexpected error received")
        }
    }

    // MARK: Configure WebView

    func test__Configure_Web_View__Empty() {
        let exp = expectation(description: "configure webview")

        // Configure WebView
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test__Configure_Web_View() {
        let exp = expectation(description: "configure webview")

        // Configure WebView
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.configureWebView { [unowned self] webView in
            XCTAssertEqual(webView.superview, self.presenterView)
            exp.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: 10)
    }

    func test__Configure_Web_View__Called_Once() {
        var count = 0
        let exp0 = expectation(description: "configure webview")

        // Configure WebView
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.configureWebView { _ in
            if count < 3 {
                manager.webView.evaluateJavaScript("execute();") { XCTAssertNil($1) }
            }

            count += 1
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: 10)

        let exp1 = expectation(description: "waiting for extra calls")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: exp1.fulfill)
        waitForExpectations(timeout: 2)

        XCTAssertEqual(count, 1)
    }

    func test__Configure_Web_View__Called_Again_With_Reset() {
        let exp0 = expectation(description: "configure webview 0")

        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        // Configure Webview
        manager.configureWebView { _ in
            manager.webView.evaluateJavaScript("execute();") { XCTAssertNil($1) }
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: 10)

        // Reset and ensure it calls again
        let exp1 = expectation(description: "configure webview 1")

        manager.configureWebView { _ in
            manager.webView.evaluateJavaScript("execute();") { XCTAssertNil($1) }
            exp1.fulfill()
        }

        manager.reset()
        waitForExpectations(timeout: 10)
    }

    func test__Configure_Web_View__Handle_rqdata_Without_JS_Error() {
        let exp0 = expectation(description: "configure webview")
        let exp1 = expectation(description: "execute JS complete")

        // Configure WebView
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}",
                                             rqdata: "some rqdata")
        manager.configureWebView { _ in
            manager.webView.evaluateJavaScript("execute();") {
                XCTAssertNil($1)
                exp1.fulfill()
            }
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not call completion")
        }

        waitForExpectations(timeout: 10)
    }

    // MARK: Stop

    func test__Stop() {
        let exp = expectation(description: "stop loading")

        // Stop
        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}")
        manager.stop()
        manager.configureWebView { _ in
            XCTFail("should not ask to configure the webview")
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not validate")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test__Reset_After_Stop() {
        let exp0 = expectation(description: "stop loading")
        let exp1 = expectation(description: "configureWebView called")
        let exp2 = expectation(description: "token recieved")

        // Stop
        let manager = HCaptchaWebViewManager(messageBody: "{token: \"some_token\"}")
        manager.stop()
        manager.configureWebView { _ in
            XCTFail("should not ask to configure the webview")
        }

        manager.validate(on: presenterView) { _ in
            XCTFail("should not validate")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            exp0.fulfill()
        }

        manager.reset()

        manager.configureWebView { _ in
            exp1.fulfill()
        }

        manager.validate(on: presenterView) { result in
            let token = try? result.dematerialize()
            XCTAssertEqual("some_token", token)
            exp2.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    // MARK: Setup

    func test__Key_Setup() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "setup key")
        var result: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey)
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { response in
            result = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.error)
        XCTAssertEqual(result?.token, apiKey)
    }

    func test__Endpoint_Setup() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "setup endpoint")
        let endpoint = URL(string: "https://some.endpoint")!
        var result: HCaptchaResult?

        let manager = HCaptchaWebViewManager(messageBody: "{token: endpoint}", endpoint: endpoint)
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        manager.validate(on: presenterView) { response in
            result = response
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.error)
        XCTAssertEqual(result?.token, endpoint.absoluteString)
    }

    // MARK: Reset

    func test__Reset() {
        let exp0 = expectation(description: "should call configureWebView #1")
        let exp1 = expectation(description: "fail on first execution")
        var result1: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey, shouldFail: true)
        manager.configureWebView { _ in
            exp0.fulfill()
        }

        // Error
        manager.validate(on: presenterView, resetOnError: false) { result in
            result1 = result
            exp1.fulfill()
        }

        waitForExpectations(timeout: 10)

        let exp2 = expectation(description: "should call configureWebView #2")
        manager.configureWebView { _ in
            exp2.fulfill()
        }

        XCTAssertEqual(result1?.error, .sessionTimeout)

        // Resets and tries again
        let exp3 = expectation(description: "validates after reset")
        var result3: HCaptchaResult?

        manager.reset()
        manager.validate(on: presenterView, resetOnError: false) { result in
            result3 = result
            exp3.fulfill()
        }

        waitForExpectations(timeout: 10)

        XCTAssertNil(result3?.error)
        XCTAssertEqual(result3?.token, apiKey)
    }

    func test__Validate__Reset_On_Error() {
        let exp0 = expectation(description: "should call configureWebView")
        var exp0Count = 0
        let exp1 = expectation(description: "should call onEvent")
        let exp2 = expectation(description: "fail on first execution")
        let exp3 = expectation(description: "hcaptcha opened")
        var result: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey, shouldFail: true)
        manager.configureWebView { _ in
            exp0Count += 1
            if exp0Count == 2 {
                exp0.fulfill()
            }
        }

        manager.onEvent = { (event, error) in
            XCTAssertTrue([.error, .open].contains(event))
            switch event {
            case .error:
                XCTAssertEqual(.error, event)
                XCTAssertEqual(HCaptchaError.sessionTimeout, error as? HCaptchaError)
                exp1.fulfill()
            case .open:
                exp3.fulfill()
            default:
                XCTFail("Unexpected event \(event)")
            }
        }

        // Error
        manager.validate(on: presenterView, resetOnError: true) { response in
            result = response

            exp2.fulfill()
        }

        waitForExpectations(timeout: 10)

        XCTAssertNil(result?.error)
        XCTAssertEqual(result?.token, apiKey)
    }

    func test__Validate__Should_Skip_For_Tests() {
        let exp = expectation(description: "did skip validation")

        let manager = HCaptchaWebViewManager()
        manager.shouldSkipForTests = true

        manager.completion = { result in
            XCTAssertEqual(result.token, "")
            exp.fulfill()
        }

        manager.validate(on: presenterView)

        waitForExpectations(timeout: 1)
    }

    // MARK: Force Challenge Visible

    func test__Force_Visible_Challenge() {
        let manager = HCaptchaWebViewManager()

        // Initial value
        XCTAssertFalse(manager.forceVisibleChallenge)

        // Set True
        manager.forceVisibleChallenge = true
        XCTAssertEqual(manager.webView.customUserAgent, "bot/2.1")

        // Set False
        manager.forceVisibleChallenge = false
        XCTAssertNotEqual(manager.webView.customUserAgent?.isEmpty, false)
    }

    // MARK: On Did Finish Loading

    func test__Did_Finish_Loading__Immediate() {
        let exp = expectation(description: "did finish loading")

        let manager = HCaptchaWebViewManager()

        // // Should call closure immediately since it's already loaded
        manager.onDidFinishLoading = {
            manager.onDidFinishLoading = exp.fulfill
        }

        waitForExpectations(timeout: 5)
    }

    func test__Did_Finish_Loading__Delayed() {
        let exp = expectation(description: "did finish loading")

        let manager = HCaptchaWebViewManager(shouldFail: true)

        var called = false
        manager.onDidFinishLoading = {
            called = true
        }

        XCTAssertFalse(called)

        // Reset
        manager.onDidFinishLoading = exp.fulfill
        manager.reset()

        waitForExpectations(timeout: 5)
    }

    func test__Invalid_Theme() {
        let exp = expectation(description: "bad theme value")

        let manager = HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}",
                                             apiKey: apiKey,
                                             theme: "[Object object]") // invalid theme
        manager.shouldResetOnError = false
        manager.configureWebView { _ in
            XCTFail("should not ask to configure the webview")
        }

        manager.validate(on: presenterView, resetOnError: false) { response in
            XCTAssertEqual(HCaptchaError.htmlLoadError, response.error)
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)
    }

    func test__OnEvent_Open_Callback() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "setup key")
        let exp2 = expectation(description: "hcaptcha opened")
        var result: HCaptchaResult?

        // Validate
        let manager = HCaptchaWebViewManager(messageBody: "{token: key}", apiKey: apiKey)
        manager.configureWebView { _ in
            exp0.fulfill()
        }
        manager.onEvent = { (event, data) in
            XCTAssertNil(data)
            XCTAssertEqual(event, .open)
            exp1.fulfill()
        }

        manager.validate(on: presenterView) { response in
            result = response
            exp2.fulfill()
        }

        waitForExpectations(timeout: 10)

        XCTAssertNotNil(result)
        XCTAssertNil(result?.error)
        XCTAssertEqual(result?.token, apiKey)
    }

    func test__OnEvent_Without_Validation() {
        let testParams: [(String, HCaptchaEvent)] = [("onChallengeExpired", .challengeExpired),
                                                     ("onExpired", .expired),
                                                     ("onClose", .close), ]

        testParams.forEach { (action, expectedEventType) in
            let exp0 = expectation(description: "should call configureWebView")
            let exp = expectation(description: "challenge expired received")

            let manager = HCaptchaWebViewManager(messageBody: "{action: \"\(action)\"}")
            manager.configureWebView { _ in
                exp0.fulfill()
            }
            manager.onEvent = { (event, data) in
                XCTAssertNil(data)
                XCTAssertEqual(expectedEventType, event)
                exp.fulfill()
            }

            manager.validate(on: presenterView) { _ in
                XCTFail("should not validate")
            }

            waitForExpectations(timeout: 5)
        }
    }

    func test__Open_External_Link() {
        let exp0 = expectation(description: "should call configureWebView")
        let exp1 = expectation(description: "_target link should be checked")
        let exp2 = expectation(description: "_target link should be opened")

        class TestURLOpener: HCaptchaURLOpener {
            private let canOpenExpectation: XCTestExpectation
            private let openExpectation: XCTestExpectation

            init(_ canOpen: XCTestExpectation, _ open: XCTestExpectation) {
                self.canOpenExpectation = canOpen
                self.openExpectation = open
            }

            func canOpenURL(_ url: URL) -> Bool {
                canOpenExpectation.fulfill()
                return true
            }

            func openURL(_ url: URL) {
                openExpectation.fulfill()
            }
        }

        let manager = HCaptchaWebViewManager(messageBody: "{token: key, action: \"openExternalPage\"}",
                                             apiKey: apiKey,
                                             urlOpener: TestURLOpener(exp1, exp2))
        manager.configureWebView { _ in
            exp0.fulfill()
        }
        wait(for: [exp0], timeout: 5)
        manager.validate(on: presenterView)

        wait(for: [exp1, exp2], timeout: 5)
    }

    func test__Invalid_HTML() {
        let exp = expectation(description: "bad theme value")

        let manager = HCaptchaWebViewManager(messageBody: "{ invalid json",
                                             apiKey: apiKey)
        manager.shouldResetOnError = false
        manager.configureWebView { _ in
            XCTFail("should not ask to configure the webview")
        }

        manager.validate(on: presenterView, resetOnError: false) { response in
            XCTAssertEqual(HCaptchaError.htmlLoadError, response.error)
            exp.fulfill()
        }

        waitForExpectations(timeout: 10)
    }
}
