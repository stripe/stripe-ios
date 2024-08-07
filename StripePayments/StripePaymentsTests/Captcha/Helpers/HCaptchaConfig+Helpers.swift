//
//  HCaptchaConfig+Helpers.swift
//  HCaptcha_Tests
//
//  Created by Алексей Берёзка on 17.08.2021.
//  Copyright © 2021 HCaptcha. All rights reserved.
//

import Foundation
@testable import StripePayments

extension HCaptchaConfig {
    init(apiKey: String?,
         infoPlistKey: String?,
         baseURL: URL?,
         infoPlistURL: URL?,
         host: String? = nil,
         customTheme: String? = nil) throws {
        try self.init(apiKey: apiKey,
                      infoPlistKey: infoPlistKey,
                      baseURL: baseURL,
                      infoPlistURL: infoPlistURL,
                      jsSrc: URL(string: "https://hcaptcha.com/1/api.js")!,
                      size: .invisible,
                      orientation: .portrait,
                      rqdata: nil,
                      sentry: false,
                      endpoint: URL(string: "https://api.hcaptcha.com")!,
                      reportapi: URL(string: "https://accounts.hcaptcha.com")!,
                      assethost: URL(string: "https://newassets.hcaptcha.com")!,
                      imghost: URL(string: "https://imgs.hcaptcha.com")!,
                      host: host,
                      theme: "light",
                      customTheme: customTheme)
    }
}
