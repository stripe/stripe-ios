//
//  FormSpecPaymentHandler.swift
//  StripePaymentSheet
//
//  Created by David Estes on 9/22/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments

class PaymentSheetFormSpecPaymentHandler {
    let urlSession: URLSession
    let formSpecProvider: FormSpecProvider
    init(urlSession: URLSession? = nil, formSpecProvider: FormSpecProvider? = nil) {
        self.urlSession =
            urlSession
            ?? URLSession(configuration: .default, delegate: STPPaymentHandlerURLSessionDelegate(), delegateQueue: nil)
        self.formSpecProvider = formSpecProvider ?? FormSpecProvider.shared
    }
}

extension PaymentSheetFormSpecPaymentHandler: FormSpecPaymentHandler {
    func handlePostConfirmPIStatusSpec(
        for paymentIntent: StripePayments.STPPaymentIntent?,
        action: StripePayments.STPPaymentHandlerPaymentIntentActionParams,
        paymentHandler: StripePayments.STPPaymentHandler
    ) -> Bool {
        if let spec = paymentHandler._specForPostConfirmPIStatus(
            paymentIntent: paymentIntent,
            formSpecProvider: formSpecProvider
        ) {
            paymentHandler._handlePostConfirmPIStatusSpec(forAction: action, paymentIntentStatusSpec: spec)
            return true
        }
        return false
    }

    func isPIStatusSpecFinishedForPostConfirmPIStatus(
        paymentIntent: StripePayments.STPPaymentIntent?,
        paymentHandler: STPPaymentHandler
    ) -> Bool {
        guard
            let spec = paymentHandler._specForPostConfirmPIStatus(
                paymentIntent: paymentIntent,
                formSpecProvider: formSpecProvider
            )
        else {
            return false
        }
        return paymentHandler._isPIStatusSpecFinished(paymentIntentStatusSpec: spec)
    }

    func handleNextActionSpec(
        for paymentIntent: STPPaymentIntent,
        action: STPPaymentHandlerPaymentIntentActionParams,
        paymentHandler: STPPaymentHandler
    ) -> Bool {
        if let paymentIntentStatusSpec = paymentHandler._specForConfirmResponse(
            paymentIntent: paymentIntent,
            formSpecProvider: formSpecProvider
        ) {
            paymentHandler._handleNextActionSpec(
                forAction: action,
                paymentIntentStatusSpec: paymentIntentStatusSpec,
                urlSession: self.urlSession
            )
            return true
        }
        return false
    }

}

extension STPPaymentHandler {
    func _specForConfirmResponse(paymentIntent: STPPaymentIntent, formSpecProvider: FormSpecProvider) -> FormSpec
        .NextActionSpec.ConfirmResponseStatusSpecs?
    {
        guard
            let nextActionSpec = FormSpec.nextActionSpec(
                paymentIntent: paymentIntent,
                formSpecProvider: formSpecProvider
            )
        else {
            return nil
        }

        if let status = paymentIntent.allResponseFields["status"] as? String,
            let spec = nextActionSpec.confirmResponseStatusSpecs[status]
        {
            return spec
        }
        return nil
    }

    func _handleNextActionSpec(
        forAction action: STPPaymentHandlerPaymentIntentActionParams,
        paymentIntentStatusSpec: FormSpec.NextActionSpec.ConfirmResponseStatusSpecs,
        urlSession: URLSession
    ) {

        guard let paymentIntent = action.paymentIntent else {
            assert(false, "Calling _handleNextActionStateSpec without a paymentIntent")
            return
        }

        switch paymentIntentStatusSpec.type {
        case .redirect_to_url(let redirectToUrl):
            if let urlString = paymentIntent.allResponseFields.stp_forLUXEJSONPath(redirectToUrl.urlPath) as? String,
                let url = URL(string: urlString)
            {

                var returnUrl: URL?
                if let returnString = paymentIntent.allResponseFields.stp_forLUXEJSONPath(redirectToUrl.returnUrlPath)
                    as? String
                {
                    returnUrl = URL(string: returnString)
                }
                switch redirectToUrl.redirectStrategy {
                case .external_browser:
                    self._handleRedirectToExternalBrowser(to: url, withReturn: returnUrl)
                case .follow_redirects:
                    let resultingRedirectURL = self.followRedirects(to: url, urlSession: urlSession)
                    self._handleRedirect(to: resultingRedirectURL, withReturn: returnUrl)
                default:
                    self._handleRedirect(to: url, withReturn: returnUrl)
                }
            } else {
                action.complete(
                    with: STPPaymentHandlerActionStatus.failed,
                    error: _error(
                        for: .unsupportedAuthenticationErrorCode,
                        userInfo: [
                            "STPIntentAction": action.nextAction()?.description ?? ""
                        ]
                    )
                )
            }
        case .finished:
            action.complete(with: .succeeded, error: nil)
        case .unknown:
            action.complete(
                with: .failed,
                error: _error(
                    for: .intentStatusErrorCode,
                    userInfo: [
                        "STPIntentAction": action.nextAction()?.description ?? ""
                    ]
                )
            )
        }
    }

    func _specForPostConfirmPIStatus(paymentIntent: STPPaymentIntent?, formSpecProvider: FormSpecProvider) -> FormSpec
        .NextActionSpec.PostConfirmHandlingPiStatusSpecs?
    {
        guard let paymentIntent = paymentIntent,
            let nextActionSpec = FormSpec.nextActionSpec(
                paymentIntent: paymentIntent,
                formSpecProvider: formSpecProvider
            ),
            let responseSpec = nextActionSpec.postConfirmHandlingPiStatusSpecs,
            !responseSpec.isEmpty
        else {
            return nil
        }
        if let status = paymentIntent.allResponseFields["status"] as? String,
            let spec = responseSpec[status]
        {
            return spec
        }
        return nil
    }
    func _handlePostConfirmPIStatusSpec(
        forAction action: STPPaymentHandlerPaymentIntentActionParams,
        paymentIntentStatusSpec: FormSpec.NextActionSpec.PostConfirmHandlingPiStatusSpecs
    ) {
        switch paymentIntentStatusSpec.type {
        case .finished:
            action.complete(with: .succeeded, error: nil)
        case .canceled:
            action.complete(with: .canceled, error: nil)
        default:
            assert(false, "programming error")
        }
    }
    func _isPIStatusSpecFinished(paymentIntentStatusSpec: FormSpec.NextActionSpec.PostConfirmHandlingPiStatusSpecs)
        -> Bool
    {
        return paymentIntentStatusSpec.type == .finished
    }
}

class STPPaymentHandlerURLSessionDelegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        completionHandler(request)
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    @_spi(STP) public func stp_forLUXEJSONPath(_ path: String) -> Any? {
        let pathComponents = Dictionary.stp_parseLUXEJSONPath(path)
        var currDict = self
        for currKey in pathComponents {
            if let dict = currDict[currKey] as? [AnyHashable: Value] {
                currDict = dict
                if currKey == pathComponents.last {
                    return currDict
                }
            } else if let val = currDict[currKey] {
                return val
            } else {
                return nil
            }
        }
        return nil
    }

    // Splits a string to an array of strings
    // "key" returns ["key"]
    // "key[key1]" returns ["key", "key1"]
    // "key[key1][key2]" returns ["key", "key1", "key2"]
    static func stp_parseLUXEJSONPath(_ path: String) -> [String] {
        var currWord = ""
        let charArray = Array(path)
        var arrayWords: [String] = []
        for char in charArray {
            if char == "[" {
                if !currWord.isEmpty {
                    arrayWords.append(currWord)
                }
                currWord = ""
            } else if char == "]" {
                if !currWord.isEmpty {
                    arrayWords.append(currWord)
                }
                currWord = ""
            } else {
                currWord.append(char)
            }
        }
        if !currWord.isEmpty {
            arrayWords.append(currWord)
        }
        return arrayWords
    }

}
