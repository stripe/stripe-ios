//
//  AuthenticationManager.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/9/24.
//

import AuthenticationServices
import UIKit
@_spi(STP) import StripeCore

class AuthenticationSessionManager: NSObject {

    let componentType: String
    let componentVars: [String: String]
    let window: UIWindow?

    private var authSession: ASWebAuthenticationSession?

    init(componentType: String,
         window: UIWindow?,
         componentVars: [String: String] = [:]) {
        self.componentType = componentType
        self.window = window
        self.componentVars = componentVars
    }

    func start(stripeConnectInstance: StripeConnectInstance) async {
        guard let clientSecret = await stripeConnectInstance.fetchClientSecret(),
              let publishableKey = stripeConnectInstance.apiClient.publishableKey else {
            // TODO: return error
            debugPrint("Missing secret or PK")
            return
        }

        let queryDict = [
            "callbackScheme": StripeConnectConstants.secureHostedCallbackScheme,
            "clientSecret": clientSecret,
            "publishableKey": publishableKey,
            "locale": Locale.autoupdatingCurrent.webIdentifier,
            "componentType": componentType
        ]
            .mergingAssertingOnOverwrites(componentVars)
            .mergingAssertingOnOverwrites(stripeConnectInstance.appearance.variablesDictionary)

        var components = URLComponents(url: StripeConnectConstants.secureHostedURL,
                                       resolvingAgainstBaseURL: true)
        components?.queryItems = queryDict.map { .init(name: $0, value: $1) }

        guard let queryURL = components?.url,
              let url = URL(string: queryURL.absoluteString.replacingOccurrences(of: "?", with: "#")) else {
            // TODO: return error
            debugPrint("Couldn't create URL")
            return
        }
        debugPrint(url)

        let authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: StripeConnectConstants.secureHostedCallbackScheme) { returnURL, error in
                debugPrint(returnURL as Any)
                debugPrint(error as Any)
            }
        authSession.presentationContextProvider = self
        self.authSession = authSession

        guard authSession.canStart else {
            debugPrint("Can't start")
            return
        }
        guard authSession.start() else {
            debugPrint("Failed to start")
            return
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension AuthenticationSessionManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        self.window ?? ASPresentationAnchor()
    }
}
