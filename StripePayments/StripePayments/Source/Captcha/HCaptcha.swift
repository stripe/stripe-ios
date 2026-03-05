//
//  HCaptcha.swift
//  HCaptcha
//
//  Created by Flávio Caetano on 22/03/17.
//  Copyright © 2018 HCaptcha. All rights reserved.
//

import JavaScriptCore
import UIKit
import WebKit

/**
  hCaptcha SDK facade (entry point)
*/
@objc
@_spi(STP) public class HCaptcha: NSObject {
    fileprivate struct Constants {
        struct InfoDictKeys {
            static let APIKey = "HCaptchaKey"
            static let Domain = "HCaptchaDomain"
        }
    }

    typealias Log = HCaptchaLogger

    /// The worker that handles webview events and communication
    let manager: HCaptchaWebViewManager

    /**
     - parameters:
         - apiKey: The API key sent to the HCaptcha init
         - baseURL: The base URL sent to the HCaptcha init
         - locale: A locale value to translate HCaptcha into a different language
         - size: A HCaptcha size check `HCaptchaSize` for more details
         - orientation: A HCaptcha orientation: `.portrait` or `.landscape` is available
         -  jsSrc: See Enterprise docs
         - rqdata: See Enterprise docs.
         - sentry: See Enterprise docs
         - endpoint: See Enterprise docs
         - reportapi: See Enterprise docs
         - assethost: See Enterprise docs
         - imghost: See Enterprise docs
         - host: See Enterprise docs
         - theme: HCaptcha supports `.light`, `dark` and `.contrast` themes
         - customTheme: See Enterprise docs
         - diagnosticLog: Emit detailed console logs for debugging

     Initializes a HCaptcha object

     Both `apiKey` and `baseURL` may be nil, in which case the lib will look for entries of `HCaptchaKey` and
     `HCaptchaDomain`, respectively, in the project's Info.plist

     - Throws: `HCaptchaError.htmlLoadError`: if is unable to load the HTML embedded in the bundle.
     - Throws: `HCaptchaError.apiKeyNotFound`: if an `apiKey` is not provided and can't find one in the project's
         Info.plist.
     - Throws: `HCaptchaError.baseURLNotFound`: if a `baseURL` is not provided and can't find one in the project's
         Info.plist.
     - Throws: Rethrows any exceptions thrown by `String(contentsOfFile:)`
     */
    @objc
    public convenience init(
        apiKey: String? = nil,
        passiveApiKey: Bool = false,
        baseURL: URL? = URL(string: "http://localhost"),
        locale: Locale? = nil,
        size: HCaptchaSize = .invisible,
        orientation: HCaptchaOrientation = .portrait,
        jsSrc: URL = URL(string: "https://js.hcaptcha.com/1/api.js")!,
        rqdata: String? = nil,
        sentry: Bool = false,
        endpoint: URL? = nil,
        reportapi: URL? = nil,
        assethost: URL? = nil,
        imghost: URL? = nil,
        host: String? = nil,
        theme: String = "light",
        customTheme: String? = nil,
        diagnosticLog: Bool = false
    ) throws {
        Log.minLevel = diagnosticLog ? .debug : .warning

        let infoDict = Bundle.main.infoDictionary

        let plistApiKey = infoDict?[Constants.InfoDictKeys.APIKey] as? String
        let plistDomain = (infoDict?[Constants.InfoDictKeys.Domain] as? String).flatMap(URL.init(string:))

        let config = try HCaptchaConfig(apiKey: apiKey,
                                        passiveApiKey: passiveApiKey,
                                        infoPlistKey: plistApiKey,
                                        baseURL: baseURL,
                                        infoPlistURL: plistDomain,
                                        jsSrc: jsSrc,
                                        size: size,
                                        orientation: orientation,
                                        rqdata: rqdata,
                                        sentry: sentry,
                                        endpoint: endpoint,
                                        reportapi: reportapi,
                                        assethost: assethost,
                                        imghost: imghost,
                                        host: host,
                                        theme: theme,
                                        customTheme: customTheme,
                                        locale: locale)

        Log.debug(".init with: \(config)")

        self.init(manager: HCaptchaWebViewManager(config: config))
    }

    /**
     - parameter manager: A HCaptchaWebViewManager instance.

      Initializes HCaptcha with the given manager
    */
    init(manager: HCaptchaWebViewManager) {
        self.manager = manager
    }

    /**
     - parameters:
         - view: The view that should present the webview.
         - resetOnError: If HCaptcha should be reset if it errors. Defaults to `true`.
         - completion: A closure that receives a HCaptchaResult which may contain a valid result token.

     Starts the challenge validation
    */
    @objc
    public func validate(on view: UIView? = nil, resetOnError: Bool = true, completion: @escaping (HCaptchaResult) -> Void) {
        Log.debug(".validate on: \(String(describing: view)) resetOnError: \(resetOnError)")

        manager.shouldResetOnError = resetOnError
        manager.completion = completion

        manager.validate(on: view)
    }

    /// Stops the execution of the webview
    @objc
    public func stop() {
        Log.debug(".stop")

        manager.stop()
    }

}
