//
//  AuthFlowHelpers.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 10/5/22.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore

final class AuthFlowHelpers {

    private init() {}  // only static functions used

    static func formatUrlString(_ urlString: String?) -> String? {
        guard var urlString = urlString else {
            return nil
        }
        if urlString.hasPrefix("https://") {
            urlString.removeFirst("https://".count)
        }
        if urlString.hasPrefix("http://") {
            urlString.removeFirst("http://".count)
        }
        if urlString.hasPrefix("www.") {
            urlString.removeFirst("www.".count)
        }
        if urlString.hasSuffix("/") {
            urlString.removeLast()
        }
        return urlString
    }

    static func handleURLInTextFromBackend(
        url: URL,
        pane: FinancialConnectionsSessionManifest.NextPane,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        handleURL: (_ urlHost: String?, _ nextPaneOrDrawerOnSecondaryCta: String?) -> Void
    ) {
        let internalLinkToPaneId: [String: String] = [
            "manual-entry": "manual_entry"
        ]
        let urlParameters = URLComponents(url: url, resolvingAgainstBaseURL: true)
        if
            let urlParameters,
            let eventName = urlParameters.queryItems?.first(
                where: { $0.name == "eventName" }
            )?.value
        {
            analyticsClient
                .log(
                    eventName: eventName,
                    pane: pane
                )
        }

        var nextPaneOrDrawerOnSecondaryCta: String?
        if
            let urlParameters,
            let _nextPaneOrDrawerOnSecondaryCta = urlParameters.queryItems?.first(
                where: { $0.name == "nextPaneOrDrawerOnSecondaryCta" }
            )?.value
        {
            nextPaneOrDrawerOnSecondaryCta = internalLinkToPaneId[_nextPaneOrDrawerOnSecondaryCta]
        }

        if url.scheme == "stripe" {
            handleURL(url.host, nextPaneOrDrawerOnSecondaryCta)
        } else {
            SFSafariViewController.present(url: url)
        }
    }

    static func networkingOTPErrorMessage(
        fromError error: Error,
        otpType: String
    ) -> String? {
        if
            let error = error as? StripeError,
            case .apiError(let apiError) = error
        {
            if apiError.code == "consumer_verification_code_invalid" {
                return STPLocalizedString("Hmm, that code didn’t work. Double check it and try again.", "Error message when one-time-passcode (OTP) is invalid.")
            } else if
                apiError.code == "consumer_session_expired"
                || apiError.code == "consumer_verification_expired"
                || apiError.code == "consumer_verification_max_attempts_exceeded"
            {
                let leadingMessage = STPLocalizedString("It looks like the verification code you provided is not valid anymore.", "The leading text in an error message that explains that the one-type-passcode (OTP) the user provided is invalid. This is leading text embedded inside of larger text: 'It looks like the verification code you provided is not valid anymore. Try again, or contact us.'")
                let trailingMessage = (otpType == "EMAIL") ? STPLocalizedString("Click “Resend code” and try again, or %@.", "Text as part of an error message that shows up when user entered an invalid one-time-passcode (OTP). '%@' will be replaced by text with a link: 'contact us'") : STPLocalizedString("Try again, or %@.", "Text as part of an error message that shows up when user entered an invalid one-time-passcode (OTP). '%@' will be replaced by text with a link: 'contact us'")

                let contactUsText = STPLocalizedString("contact us", "A link/button inside of text that can be tapped to visit a support website. This link will be embedded inside of larger text: 'It looks like the verification code you provided is not valid anymore. Try again, or contact us.'")
                let contactUsUrlString = "https://support.link.co/contact/email?skipVerification=true"
                let contactUsWithUrlText = "[\(contactUsText)](\(contactUsUrlString))"

                return leadingMessage + " " + String(format: trailingMessage, contactUsWithUrlText)
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    static func formatRedactedPhoneNumber(_ redactedPhoneNumber: String) -> String {
        return redactedPhoneNumber.replacingOccurrences(of: "*", with: "•")
    }
}
