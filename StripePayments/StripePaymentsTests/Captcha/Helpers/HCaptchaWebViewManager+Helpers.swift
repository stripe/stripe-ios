//
//  HCaptchaWebViewManager+Helpers.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 13/04/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import Foundation
@testable import StripePayments
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
        endpoint: URL? = nil,
        shouldFail: Bool = false, // will fail with retriable sessionTimeout
        size: HCaptchaSize = .invisible,
        rqdata: String? = nil,
        theme: String = "\"light\"",
        urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener()
    ) {
        let html = String(format: HCaptchaWebViewManager.unformattedHTML,
                          arguments: [
                            "message": messageBody,
                            "shouldFail": shouldFail.description,
                          ])

        self.init(
            html: html,
            apiKey: apiKey,
            endpoint: endpoint,
            size: size,
            rqdata: rqdata,
            theme: theme,
            urlOpener: urlOpener
        )
    }

    convenience init(
        html: String,
        apiKey: String? = nil,
        endpoint: URL? = nil,
        size: HCaptchaSize = .invisible,
        orientation: HCaptchaOrientation = .portrait,
        rqdata: String? = nil,
        theme: String = "\"light\"",
        urlOpener: HCaptchaURLOpener = HCapchaAppURLOpener()
    ) {
        let localhost = URL(string: "http://localhost")!

        self.init(
            html: html,
            apiKey: apiKey ?? UUID().uuidString,
            baseURL: localhost,
            endpoint: endpoint ?? localhost,
            size: size,
            orientation: orientation,
            rqdata: rqdata,
            theme: theme,
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
