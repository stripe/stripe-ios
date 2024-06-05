//
//  HCaptcha__Tests.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 26/09/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

@testable import StripePayments
import XCTest

class HCaptcha__Tests: XCTestCase {
    fileprivate struct Constants {
        struct InfoDictKeys {
            static let APIKey = "HCaptchaKey"
            static let Domain = "HCaptchaDomain"
        }
    }

    func test__Force_Visible_Challenge() {
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager())

        // Initial value
        XCTAssertFalse(hcaptcha.forceVisibleChallenge)

        // Set true
        hcaptcha.forceVisibleChallenge = true
        XCTAssertTrue(hcaptcha.forceVisibleChallenge)
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

    func test__validate_from_didFinishLoading() {
        let exp = expectation(description: "execute js function must be called only once")
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}"))
        hcaptcha.didFinishLoading {
            let view = UIApplication.shared.windows.first?.rootViewController?.view
            hcaptcha.onEvent { e, _ in
                if e == .open {
                    exp.fulfill()
                }
            }
            hcaptcha.validate(on: view!) { _ in
                XCTFail("Should not be called")
            }
        }
        wait(for: [exp], timeout: 10)
    }

    func test__reconfigure() {
        let exp = expectation(description: "configureWebView called twice")
        var configureCounter = 0
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{action: \"showHCaptcha\"}"))
        hcaptcha.configureWebView { _ in
            configureCounter += 1
            if configureCounter == 2 {
                exp.fulfill()
            }
        }
        hcaptcha.didFinishLoading {
            let view = UIApplication.shared.windows.first?.rootViewController?.view
            hcaptcha.onEvent { e, _ in
                if e == .open {
                    hcaptcha.redrawView()
                }
            }
            hcaptcha.validate(on: view!) { _ in
                XCTFail("Should not be called")
            }
        }
        wait(for: [exp], timeout: 10)
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
