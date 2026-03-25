//
//  HCaptchaConfig+Helpers.swift
//  HCaptcha_Tests
//
//  Created by Алексей Берёзка on 17.08.2021.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

import Foundation
@_spi(STP) @testable import StripePayments

extension HCaptchaConfig {
    init(html: String = HCaptchaHtml.template,
         apiKey: String? = UUID().uuidString,
         passiveApiKey: Bool = false,
         infoPlistKey: String? = "api-key",
         baseURL: URL? = URL(string: "http://localhost")!,
         infoPlistURL: URL? = nil,
         size: HCaptchaSize = .invisible,
         orientation: HCaptchaOrientation = .portrait,
         rqdata: String? = nil,
         endpoint: URL = URL(string: "https://api.hcaptcha.com")!,
         host: String? = nil,
         theme: String = "\"light\"",
         customTheme: String? = nil,
         locale: Locale? = nil) throws {

        try self.init(html: html,
                      apiKey: apiKey,
                      passiveApiKey: passiveApiKey,
                      infoPlistKey: infoPlistKey,
                      baseURL: baseURL,
                      infoPlistURL: infoPlistURL,
                      jsSrc: URL(string: "https://hcaptcha.com/1/api.js")!,
                      size: size,
                      orientation: orientation,
                      rqdata: rqdata,
                      sentry: false,
                      endpoint: endpoint,
                      reportapi: URL(string: "https://accounts.hcaptcha.com")!,
                      assethost: URL(string: "https://newassets.hcaptcha.com")!,
                      imghost: URL(string: "https://imgs.hcaptcha.com")!,
                      host: host,
                      theme: theme,
                      customTheme: customTheme,
                      locale: locale)
    }

    init(apiKey: String = "some-api-key",
         host: String? = nil,
         customTheme: String? = nil,
         locale: Locale? = nil) throws {
        try self.init(apiKey: apiKey,
                      infoPlistKey: nil,
                      baseURL: URL(string: "https://localhost")!,
                      infoPlistURL: nil,
                      host: host,
                      customTheme: customTheme,
                      locale: locale)
    }
}
