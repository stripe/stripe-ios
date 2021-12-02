//
//  ConnectionsHostViewController.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import UIKit
import AuthenticationServices
import CoreMedia
@_spi(STP) import StripeUICore

final class ConnectionsHostViewController: UIViewController {

    // MARK: - Properties

    fileprivate var authSession: ASWebAuthenticationSession?
    fileprivate let linkAccountSessionClientSecret: String

    // MARK: - Init

    init(linkAccountSessionClientSecret: String) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CompatibleColor.systemBackground
        // TODO(vardges): Make an api call instead
        let url = URL(string: "https://auth.stripe.com/link-accounts#clientSecret=\(linkAccountSessionClientSecret)")!
        authSession = ASWebAuthenticationSession(url: url,
                                                 callbackURLScheme: Constants.callbackScheme,
                                                 completionHandler: { returnUrl, error in
            self.dismiss(animated: true, completion: nil)
        })
        if #available(iOSApplicationExtension 13.0, *) {
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = true
        }

        authSession?.start()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension ConnectionsHostViewController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}

// MARK: - Constants

extension ConnectionsHostViewController {
    enum Constants {
        static let callbackScheme = "stripe-auth"
    }
}
