//
//  HCaptchaWebViewManager+Helpers.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 13/04/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
@_spi(STP) @testable import StripePayments
import WebKit

extension HCaptchaWebViewManager {
    private static let unformattedHTML: String! = {
        Bundle(for: HCaptchaWebViewManager__Tests.self)
            .path(forResource: "mock", ofType: "html")
            .flatMap { try? String(contentsOfFile: $0) }
    }()

    convenience init(
        messageBody: String = "undefined",
        apiKey: String? = nil,
        passiveApiKey: Bool = false,
        endpoint: URL? = nil,
        shouldFail: Bool = false, // will fail with retriable sessionTimeout
        size: HCaptchaSize = .invisible,
        rqdata: String? = nil,
        theme: String = "light",
        customTheme: String? = nil,
        urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener()
    ) {
        let html = String(format: HCaptchaWebViewManager.unformattedHTML,
                          arguments: [
                            "message": messageBody,
                            "shouldFail": shouldFail.description,
                          ])

        self.init(
            html: html,
            apiKey: apiKey ?? "api-key",
            passiveApiKey: passiveApiKey,
            endpoint: endpoint ?? URL(string: "https://api.hcaptcha.com")!,
            size: size,
            rqdata: rqdata,
            theme: theme,
            customTheme: customTheme,
            urlOpener: urlOpener
        )
    }

    convenience init(
        html: String,
        apiKey: String,
        passiveApiKey: Bool = false,
        endpoint: URL = URL(string: "https://api.hcaptcha.com")!,
        size: HCaptchaSize = .invisible,
        orientation: HCaptchaOrientation = .portrait,
        rqdata: String? = nil,
        theme: String = "light",
        customTheme: String? = nil,
        urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener()
    ) {
        let localhost = URL(string: "http://localhost")!

        // swiftlint:disable:next force_try
        let config = try! HCaptchaConfig(html: html,
                                         apiKey: apiKey,
                                         passiveApiKey: passiveApiKey,
                                         baseURL: localhost,
                                         size: size,
                                         orientation: orientation,
                                         rqdata: rqdata,
                                         endpoint: endpoint,
                                         theme: theme,
                                         customTheme: customTheme)

        self.init(
            config: config,
            urlOpener: urlOpener
        )
    }

    func configureWebView(_ configure: @escaping (WKWebView) -> Void) {
        configureWebView = configure
    }

    func validate(on view: UIView, resetOnError: Bool = true, completion: @escaping (HCaptchaResult) -> Void) {
        self.shouldResetOnError = resetOnError
        self.completion = completion

        validate(on: view)
    }
}
