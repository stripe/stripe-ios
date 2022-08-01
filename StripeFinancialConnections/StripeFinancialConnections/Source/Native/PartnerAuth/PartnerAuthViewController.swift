//
//  PartnerAuthViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/25/22.
//

import Foundation
import UIKit
import AuthenticationServices
@_spi(STP) import StripeUICore

final class PartnerAuthViewController: UIViewController {
    
    private let authorizationSession: FinancialConnectionsAuthorizationSession
    private let manifest: FinancialConnectionsSessionManifest
    private let institution: FinancialConnectionsInstitution
    private var shouldShowPrepane: Bool { // TODO(kgaidis): implement a prepane check based off `flow` of `authorizationSession`
        return !(authorizationSession.institutionSkipAccountSelection ?? true)
    }
    
    init(
        authorizationSession: FinancialConnectionsAuthorizationSession,
        manifest: FinancialConnectionsSessionManifest,
        institution: FinancialConnectionsInstitution
    ) {
        self.authorizationSession = authorizationSession
        self.manifest = manifest
        self.institution = institution
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor
        
        if shouldShowPrepane {
            let prepaneView = PrepaneView(
                institutionName: institution.name,
                partnerName: (authorizationSession.showPartnerDisclosure ?? false) ? authorizationSession.flow?.toInstitutionName() : nil,
                isSingleAccount: manifest.singleAccount,
                showPartnerDisclosure: authorizationSession.showPartnerDisclosure ?? false
            )
            view.addAndPinSubview(prepaneView)
        } else {
            // TODO(kgaidis): add a loading spinner?
            openInstitutionAuthenticationWebView()
        }
    }
    
    private func openInstitutionAuthenticationWebView() {
        guard let urlString = authorizationSession.url, let url = URL(string: urlString) else {
            assertionFailure("Expected to get a URL back from authorization session: \(authorizationSession)")
            return
        }
        
        let authSession = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: url.scheme,
            completionHandler: { [weak self] returnUrl, error in
                if let error = error {
                    print(error)
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    print(returnUrl?.absoluteString ?? "no return url")
                    // TODO(kgaidis): go to next screen
                }
        })
        
        if #available(iOS 13.0, *) {
            authSession.presentationContextProvider = self
            authSession.prefersEphemeralWebBrowserSession = true
        }

        if #available(iOS 13.4, *) {
            if !authSession.canStart {
                // TODO(kgaidis): handle any errors...
            }
        }
        
        authSession.start()
    }
    
    @objc private func didSelectContinue() {
        openInstitutionAuthenticationWebView()
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

/// :nodoc:
@available(iOS 13, *)
extension PartnerAuthViewController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
