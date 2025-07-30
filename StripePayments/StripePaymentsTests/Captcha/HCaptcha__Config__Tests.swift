//
//  HCaptcha__Config__Tests.swift
//  HCaptcha_Tests
//
//  Created by CAMOBAP on 12/20/21.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

@_spi(STP) @testable import StripePayments
import XCTest

class HCaptcha__Config__Tests: XCTestCase {
    private let expected = "https://hcaptcha.com/1/api.js?onload=onloadCallback&render=explicit&recaptchacompat=off"
        + "&host=some-api-key.ios-sdk.hcaptcha.com&sentry=false&endpoint=https%3A%2F%2Fapi.hcaptcha.com"
        + "&assethost=https%3A%2F%2Fnewassets.hcaptcha.com&imghost=https%3A%2F%2Fimgs.hcaptcha.com"
        + "&reportapi=https%3A%2F%2Faccounts.hcaptcha.com"

    func test__Base_URL() {
        // Ensures baseURL failure when nil
        do {
            _ = try HCaptchaConfig(apiKey: "", infoPlistKey: nil, baseURL: nil, infoPlistURL: nil)
            XCTFail("Should have failed")
        } catch let e as HCaptchaError {
            print(e)
            XCTAssertEqual(e, HCaptchaError.baseURLNotFound)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }

        // Ensures plist url if nil key
        let plistURL = URL(string: "https://bar")!
        let config1 = try? HCaptchaConfig(apiKey: "", infoPlistKey: nil, baseURL: nil, infoPlistURL: plistURL)
        XCTAssertEqual(config1?.baseURL, plistURL)

        // Ensures preference of given url over plist entry
        let url = URL(string: "ftp://foo")!
        let config2 = try? HCaptchaConfig(apiKey: "", infoPlistKey: nil, baseURL: url, infoPlistURL: plistURL)
        XCTAssertEqual(config2?.baseURL, url)
    }

    func test__Base_URL_Without_Scheme() {
        // Ignores URL with scheme
        let goodURL = URL(string: "https://foo.bar")!
        let config0 = try? HCaptchaConfig(apiKey: "", infoPlistKey: nil, baseURL: goodURL, infoPlistURL: nil)
        XCTAssertEqual(config0?.baseURL, goodURL)

        // Fixes URL without scheme
        let badURL = URL(string: "foo")!
        let config = try? HCaptchaConfig(apiKey: "", infoPlistKey: nil, baseURL: badURL, infoPlistURL: nil)
        XCTAssertEqual(config?.baseURL.absoluteString, "http://" + badURL.absoluteString)
    }

    func test__API_Key() {
        // Ensures key failure when nil
        do {
            _ = try HCaptchaConfig(apiKey: nil, infoPlistKey: nil, baseURL: nil, infoPlistURL: nil)
            XCTFail("Should have failed")
        } catch let e as HCaptchaError {
            print(e)
            XCTAssertEqual(e, HCaptchaError.apiKeyNotFound)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }

        // Ensures plist key if nil key
        let plistKey = "bar"
        let config1 = try? HCaptchaConfig(
            apiKey: nil,
            infoPlistKey: plistKey,
            baseURL: URL(string: "foo"),
            infoPlistURL: nil
        )
        XCTAssertEqual(config1?.apiKey, plistKey)

        // Ensures preference of given key over plist entry
        let key = "foo"
        let config2 = try? HCaptchaConfig(
            apiKey: key,
            infoPlistKey: plistKey,
            baseURL: URL(string: "foo"),
            infoPlistURL: nil
        )
        XCTAssertEqual(config2?.apiKey, key)
    }

    func test__Locale__Nil() {
        let config = try? HCaptchaConfig()
        let actual = config?.actualEndpoint.absoluteString
        XCTAssertEqual(actual, expected)
    }

    func test__Locale__Valid() {
        let locale = Locale(identifier: "pt-BR")
        let config = try? HCaptchaConfig(locale: locale)
        let actual = config?.actualEndpoint.absoluteString
        XCTAssertEqual(actual, "\(expected)&hl=\(locale.identifier)")
    }

    func test__Custom__Host() {
        let host = "custom-host"
        let config = try? HCaptchaConfig(host: host)
        let actual = config?.actualEndpoint.absoluteString
        XCTAssertEqual(actual, expected.replacingOccurrences(
            of: "some-api-key.ios-sdk.hcaptcha.com",
            with: host))
    }

    func test__Custom__Theme() {
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
        let config = try? HCaptchaConfig(customTheme: customTheme)
        let actual = config?.actualEndpoint.absoluteString
        XCTAssertEqual(actual, expected + "&custom=true")
    }

    func test__Invalid_Theme() {
        do {
            _ = try HCaptchaConfig(customTheme: "[Object object]")
            XCTFail("Should have failed")
        } catch let e as HCaptchaError {
            print(e)
            XCTAssertEqual(e, HCaptchaError.invalidCustomTheme)
        } catch let e {
            XCTFail("Unexpected error: \(e)")
        }
    }

    func test__Pat() {
        let config = try? HCaptchaConfig(disablePat: true)
        let actual = config!.actualEndpoint.absoluteString
        XCTAssertTrue(actual.contains("pat=off"))
    }
}
