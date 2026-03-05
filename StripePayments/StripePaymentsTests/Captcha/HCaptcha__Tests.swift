//
//  HCaptcha__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 26/09/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@_spi(STP) @testable import StripePayments
import XCTest

class HCaptcha__Tests: XCTestCase {
    fileprivate struct Constants {
        struct InfoDictKeys {
            static let APIKey = "HCaptchaKey"
            static let Domain = "HCaptchaDomain"
        }
    }

    func test__valid_js_customTheme() {
        let customTheme = """
              {
                primary: {
                  main: "#00FF00"
                },
                text: {
                  heading: "#454545",
                  body   : "#8C8C8C"
                }
              }
            """
        do {
            _ = try HCaptcha(customTheme: customTheme)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }
    }

    func test__valid_json_customTheme() {
        let customTheme = """
              {
                "primary": {
                  "main": "#00FF00"
                },
                "text": {
                  "heading": "#454545",
                  "body"   : "#8C8C8C"
                }
              }
            """
        do {
            _ = try HCaptcha(customTheme: customTheme)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }
    }

    func test__invalid_js_customTheme() {
        let customTheme = """
              {
                primary: {
                  main: "#00FF00"
                },
                text: {
                  heading: "#454545",
                  body   : "#8C8C8C"
                }
              // } missing last bracket
            """
        do {
            _ = try HCaptcha(customTheme: customTheme)
            XCTFail("Should not be reached. Error expected")
        } catch let e as HCaptchaError {
            print(e)
            XCTAssertEqual(e, HCaptchaError.invalidCustomTheme)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }
    }

}

private extension Bundle {
    @objc func failHTMLLoad(_ resource: String, type: String) -> String? {
        guard resource == "hcaptcha" && type == "html" else {
            return failHTMLLoad(resource, type: type)
        }

        return nil
    }
}
