//
//  HCaptchaResult__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 06/03/18.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import StripePayments
import XCTest

class HCaptchaResult__Tests: XCTestCase {
    func test__Get_Token() {
        let token = UUID().uuidString
        let manager = HCaptchaWebViewManager()
        let result = HCaptchaResult(manager, token: token)

        do {
            let value = try result.dematerialize()
            XCTAssertEqual(value, token)
        } catch let err {
            XCTFail(err.localizedDescription)
        }
    }

    func test__Get_Token__Error() {
        let error = HCaptchaError.random()
        let manager = HCaptchaWebViewManager()
        let result = HCaptchaResult(manager, error: error)

        do {
            _ = try result.dematerialize()
            XCTFail("Shouldn't have completed")
        } catch let err {
            XCTAssertEqual(err as? HCaptchaError, error)
        }
    }
}
