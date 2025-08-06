//
//  HCaptchaDecoder__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 13/04/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import StripePayments

import WebKit
import XCTest

class HCaptchaDecoder__Tests: XCTestCase {
    fileprivate typealias Result = HCaptchaDecoder.Result

    fileprivate var assertResult: ((Result) -> Void)?
    fileprivate var decoder: HCaptchaDecoder!

    override func setUp() {
        super.setUp()

        decoder = HCaptchaDecoder { [weak self] result in
            self?.assertResult?(result)
        }
    }

    func test__Send_Error() {
        let exp = expectation(description: "send error message")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let err = HCaptchaError.random()
        decoder.send(error: err)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertNotNil(result)
        XCTAssertEqual(result, .error(err))
    }

    func test__Decode__Wrong_Format() {
        let exp = expectation(description: "send unsupported message")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let message = MockMessage(message: "foobar")
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .error(HCaptchaError.wrongMessageFormat))
    }

    func test__Decode__Unexpected_Action() {
        let exp = expectation(description: "send message with unexpected action")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let message = MockMessage(message: ["action": "bar"])
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .error(HCaptchaError.wrongMessageFormat))
    }

    func test__Decode__ShowHCaptcha() {
        let exp = expectation(description: "send showHCaptcha message")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let message = MockMessage(message: ["action": "showHCaptcha"])
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .showHCaptcha)
    }

    func test__Decode__Token() {
        let exp = expectation(description: "send token message")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let token = UUID().uuidString
        let message = MockMessage(message: ["token": token])
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .token(token))
    }

    func test__Decode__DidLoad() {
        let exp = expectation(description: "send did load message")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let message = MockMessage(message: ["action": "didLoad"])
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .didLoad)
    }

    func test__Decode__Error_Setup_Failed() {
        let exp = expectation(description: "send error")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let message = MockMessage(message: ["error": 29])
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .error(.failedSetup))
    }

    func test__Decode__Error_Response_Expired() {
        let exp = expectation(description: "send error")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let message = MockMessage(message: ["error": 15])
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .error(.sessionTimeout))
    }

    func test__Decode__Error_Render_Failed() {
        let exp = expectation(description: "send error")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let message = MockMessage(message: ["error": 31])
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .error(.rateLimit))
    }

    func test__Decode__Error_Wrong_Format() {
        let exp = expectation(description: "send error")
        var result: Result?

        assertResult = { res in
            result = res
            exp.fulfill()
        }

        // Send
        let message = MockMessage(message: ["error": 26])
        decoder.send(message: message)

        waitForExpectations(timeout: 1)

        // Check
        XCTAssertEqual(result, .error(.wrongMessageFormat))
    }
}
