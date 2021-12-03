//
//  ConnectionsHostViewController.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 12/1/21.
//

import UIKit
import AuthenticationServices
import CoreMedia
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOS 12, *)
final class ConnectionsHostViewController: UIViewController {

    // MARK: - Properties

    fileprivate var authSession: ASWebAuthenticationSession?
    fileprivate let linkAccountSessionClientSecret: String
    fileprivate let apiClient: ConnectionsAPIClient

    // MARK: - Init

    init(linkAccountSessionClientSecret: String,
         apiClient: ConnectionsAPIClient) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
        self.apiClient = apiClient
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CompatibleColor.systemBackground

        apiClient
            .generateLinkAccountSessionManifest(clientSecret: linkAccountSessionClientSecret)
            .observe { [weak self] result in
            switch result {
            case .success(let manifest):
                self?.startAuthenticationSession(manifest: manifest)
            case .failure(let error):
                // TODO(vardges): Do proper error handling
                print("ERROR \(error.localizedDescription)")
            }

        }
    }
}

// MARK: - Helpers

@available(iOS 12, *)
extension ConnectionsHostViewController {
    fileprivate func startAuthenticationSession(manifest: LinkAccountSessionManifest) {
        guard let url = URL(string: manifest.hostedAuthUrl) else {
            // TODO(vardges): communicate failure here
            return
        }
        authSession = ASWebAuthenticationSession(url: url,
                                                 callbackURLScheme: Constants.callbackScheme,
                                                 completionHandler: { returnUrl, error in
            self.dismiss(animated: true, completion: nil)
        })
        if #available(iOS 13.0, *) {
            authSession?.presentationContextProvider = self
            authSession?.prefersEphemeralWebBrowserSession = true
        }

        authSession?.start()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

@available(iOS 13, *)
extension ConnectionsHostViewController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? ASPresentationAnchor()
    }
}

// MARK: - Constants

@available(iOS 12, *)
extension ConnectionsHostViewController {
    enum Constants {
        static let callbackScheme = "stripe-auth"
    }
}
