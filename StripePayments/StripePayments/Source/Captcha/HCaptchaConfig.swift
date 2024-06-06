//
//  HCaptchaConfig.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import JavaScriptCore
import UIKit
import WebKit

/** Widget display mode
 */
@objc
enum HCaptchaSize: Int, RawRepresentable {
    case invisible
    case compact
    case normal

    typealias RawValue = String

    var rawValue: RawValue {
        switch self {
        case .invisible:
            return "invisible"
        case .compact:
            return "compact"
        case .normal:
            return "normal"
        }
    }

    init?(rawValue: RawValue) {
        switch rawValue {
        case "invisible":
            self = .invisible
        case "compact":
            self = .compact
        case "normal":
            self = .normal
        default:
            return nil
        }
    }
}

/** Widget orientation mode
 */
@objc
enum HCaptchaOrientation: Int, RawRepresentable {
    case portrait
    case landscape

    typealias RawValue = String

    var rawValue: RawValue {
        switch self {
        case .portrait:
            return "portrait"
        case .landscape:
            return "landscape"
        }
    }

    init?(rawValue: RawValue) {
        switch rawValue {
        case "portrait":
            self = .portrait
        case "landscape":
            self = .landscape
        default:
            return nil
        }
    }
}

/** Internal data model to keep SDK init params
 */
struct HCaptchaConfig: CustomDebugStringConvertible {
    /// The raw unformated HTML file content
    let html: String

    /// The API key that will be sent to the HCaptcha API
    let apiKey: String

    /// Size of visible area
    let size: HCaptchaSize

    /// Orientation of widget
    let orientation: HCaptchaOrientation

    /// The base url to be used to resolve relative URLs in the webview
    let baseURL: URL

    /// The url of api.js
    /// Default: https://hcaptcha.com/1/api.js
    let jsSrc: URL

    /// Custom supplied challenge data
    let rqdata: String?

    /// Enable / Disable sentry error reporting.
    let sentry: Bool?

    /// Point hCaptcha JS Ajax Requests to alternative API Endpoint.
    /// Default: https://hcaptcha.com
    let endpoint: URL?

    /// Point hCaptcha Bug Reporting Request to alternative API Endpoint.
    /// Default: https://accounts.hcaptcha.com
    let reportapi: URL?

    /// Points loaded hCaptcha assets to a user defined asset location, used for proxies.
    /// Default: https://assets.hcaptcha.com
    let assethost: URL?

    /// Points loaded hCaptcha challenge images to a user defined image location, used for proxies.
    /// Default: https://imgs.hcaptcha.com
    let imghost: URL?

    /// SDK's host identifier. nil value means that it will be generated.
    let host: String?

    /// Set the color theme of the widget. Default is "light".
    let theme: String

    /// Custom theme JSON string.
    let customTheme: String?

    /// Return actual theme value based on init params. It must return valid JS object.
    var actualTheme: String {
        self.customTheme ?? "\"\(theme)\""
    }

    /// The Bundle that holds HCaptcha's assets
    private static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let bundle = Bundle(for: HCaptcha.self)
        guard let cocoapodsBundle = bundle
                .path(forResource: "HCaptcha", ofType: "bundle")
                .flatMap(Bundle.init(path:)) else {
            return bundle
        }

        return cocoapodsBundle
        #endif
    }()

    var debugDescription: String {
        let mirror = Mirror(reflecting: self)

        var result = "HCaptchaConfig("
        for (label, value) in mirror.children {
            if let label = label, label != "html" {
                result.append("\(label): \(value), ")
            }
        }

        if !mirror.children.isEmpty {
            let lastIndex = result.index(result.endIndex, offsetBy: -2)
            result.removeSubrange(lastIndex...)
        }

        return result + ")"
    }

    /**
     - parameters:
         - apiKey: The API key sent to the HCaptcha init
         - infoPlistKey: The API key retrived from the application's Info.plist
         - baseURL: The base URL sent to the HCaptcha init
         - infoPlistURL: The base URL retrieved from the application's Info.plist

     - Throws: `HCaptchaError.htmlLoadError`: if is unable to load the HTML embedded in the bundle.
     - Throws: `HCaptchaError.apiKeyNotFound`: if an `apiKey` is not provided and can't find one in the project's
     Info.plist.
     - Throws: `HCaptchaError.baseURLNotFound`: if a `baseURL` is not provided and can't find one in the project's
     Info.plist.
     - Throws: Rethrows any exceptions thrown by `String(contentsOfFile:)`
     */
    init(apiKey: String?,
         infoPlistKey: String?,
         baseURL: URL?,
         infoPlistURL: URL?,
         jsSrc: URL,
         size: HCaptchaSize,
         orientation: HCaptchaOrientation,
         rqdata: String?,
         sentry: Bool?,
         endpoint: URL?,
         reportapi: URL?,
         assethost: URL?,
         imghost: URL?,
         host: String?,
         theme: String,
         customTheme: String?) throws {
        guard let apiKey = apiKey ?? infoPlistKey else {
            throw HCaptchaError.apiKeyNotFound
        }

        guard let domain = baseURL ?? infoPlistURL else {
            throw HCaptchaError.baseURLNotFound
        }

        if let customTheme = customTheme {
            let validationJS: String = "(function() { return \(customTheme) })()"
            let context = JSContext()!
            context.exceptionHandler = { _, err in
                HCaptchaLogger.error("customTheme validation error: \(String(describing: err))")
            }
            let result = context.evaluateScript(validationJS)
            if result?.isObject != true {
                throw HCaptchaError.invalidCustomTheme
            }
        }

        self.html = HCaptchaHtml.template
        self.apiKey = apiKey
        self.size = size
        self.orientation = orientation
        self.baseURL = HCaptchaConfig.fixSchemeIfNeeded(for: domain)
        self.jsSrc = jsSrc
        self.rqdata = rqdata
        self.sentry = sentry
        self.endpoint = endpoint
        self.reportapi = reportapi
        self.assethost = assethost
        self.imghost = imghost
        self.host = host
        self.theme = theme
        self.customTheme = customTheme
    }

    /**
     The JS API endpoint to be loaded onto the HTML file.
     - parameter url: The URL to be fixed
     */
    func getEndpointURL(locale: Locale? = nil) -> URL {
        var result = URLComponents(url: jsSrc, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "onload", value: "onloadCallback"),
            URLQueryItem(name: "render", value: "explicit"),
            URLQueryItem(name: "recaptchacompat", value: "off"),
            URLQueryItem(name: "host", value: host ?? "\(apiKey).ios-sdk.hcaptcha.com"),
        ]

        if let sentry = sentry {
            queryItems.append(URLQueryItem(name: "sentry", value: String(sentry)))
        }
        if let url = endpoint {
            queryItems.append(URLQueryItem(name: "endpoint", value: url.absoluteString))
        }
        if let url = assethost {
            queryItems.append(URLQueryItem(name: "assethost", value: url.absoluteString))
        }
        if let url = imghost {
            queryItems.append(URLQueryItem(name: "imghost", value: url.absoluteString))
        }
        if let url = reportapi {
            queryItems.append(URLQueryItem(name: "reportapi", value: url.absoluteString))
        }
        if let locale = locale {
            queryItems.append(URLQueryItem(name: "hl", value: locale.identifier))
        }
        if customTheme != nil {
            queryItems.append(URLQueryItem(name: "custom", value: String(true)))
        }

        result.percentEncodedQuery = queryItems.map {
            $0.name +
            "=" +
            $0.value!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
        }.joined(separator: "&")

        return result.url!
    }
}

// MARK: - Private Methods

private extension HCaptchaConfig {
    /**
     - parameter url: The URL to be fixed
     - returns: An URL with scheme

     If the given URL has no scheme, prepends `http://` to it and return the fixed URL.
     */
    static func fixSchemeIfNeeded(for url: URL) -> URL {
        guard url.scheme?.isEmpty != false else {
            return url
        }

        HCaptchaLogger.warn("""
                               ⚠️ WARNING! Protocol not found for HCaptcha domain (\(url))!
                               You should add http:// or https:// to it!
                            """)

        if let fixedURL = URL(string: "http://" + url.absoluteString) {
            return fixedURL
        }

        return url
    }
}
