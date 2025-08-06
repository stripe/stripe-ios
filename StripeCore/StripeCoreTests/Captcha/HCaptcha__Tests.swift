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

    func test__passiveSiteKey_configure_not_called() {
        let loaded = expectation(description: "hCaptcha WebView loaded")
        let tokenRecieved = expectation(description: "hCaptcha token recieved")
        let hcaptcha = HCaptcha(manager: HCaptchaWebViewManager(messageBody: "{token: \"some_token\"}",
                                                                passiveApiKey: true))
        hcaptcha.configureWebView { _ in
            XCTFail("configureWebView should not be called for passive sitekey")
        }
        hcaptcha.didFinishLoading {
            loaded.fulfill()
        }
        let view = UIApplication.shared.windows.first!.rootViewController!.view!
        hcaptcha.validate(on: view) { result in
            XCTAssertEqual("some_token", result.token)
            tokenRecieved.fulfill()
        }
        wait(for: [loaded, tokenRecieved], timeout: 10)
    }

    func test__convenience_inits_is_not_recursive() throws {
        XCTAssertNotNil(try? HCaptcha(locale: Locale.current))
        XCTAssertNotNil(try? HCaptcha(size: .compact))
        XCTAssertNotNil(try? HCaptcha(passiveApiKey: true))
        XCTAssertNotNil(try? HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001"))
        XCTAssertNotNil(try? HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001",
                                      baseURL: URL(string: "http://localhost")!))
        XCTAssertNotNil(try? HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001",
                                      baseURL: URL(string: "http://localhost")!,
                                      locale: Locale.current))
        XCTAssertNotNil(try? HCaptcha(apiKey: "10000000-ffff-ffff-ffff-000000000001",
                                      baseURL: URL(string: "http://localhost")!,
                                      locale: Locale.current,
                                      size: .normal))
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
