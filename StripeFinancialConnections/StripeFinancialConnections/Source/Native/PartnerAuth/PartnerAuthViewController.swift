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
@_spi(STP) import StripeCore

@available(iOSApplicationExtension, unavailable)
final class PartnerAuthViewController: UIViewController {
    
    enum PaneType {
        case success(FinancialConnectionsAuthorizationSession)
        case error(Error)
    }
    
    private let paneType: PaneType
    private let manifest: FinancialConnectionsSessionManifest
    private let institution: FinancialConnectionsInstitution
    private var shouldShowPrepane: Bool {
        switch paneType {
        case .success(let authorizationSession):
            return (authorizationSession.flow?.isOAuth() ?? false)
        case .error(_):
            return true
        }
    }
    
    init(
        institution: FinancialConnectionsInstitution,
        paneType: PaneType,
        manifest: FinancialConnectionsSessionManifest
    ) {
        self.paneType = paneType
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
        
        switch paneType {
        case .success(let authorizationSession):
            handleSuccess(authorizationSession)
        case .error(let error):
            handleError(error)
        }
    }
    
    private func handleSuccess(_ authorizationSession: FinancialConnectionsAuthorizationSession) {
        if shouldShowPrepane {
            let prepaneView = PrepaneView(
                institutionName: institution.name,
                partnerName: (authorizationSession.showPartnerDisclosure ?? false) ? authorizationSession.flow?.toInstitutionName() : nil,
                isSingleAccount: manifest.singleAccount,
                didSelectContinue: { [weak self] in
                    self?.openInstitutionAuthenticationWebView(urlString: authorizationSession.url)
                }
            )
            view.addAndPinSubview(prepaneView)
        } else {
            // TODO(kgaidis): add a loading spinner?
            openInstitutionAuthenticationWebView(urlString: authorizationSession.url)
        }
    }
    
    private func handleError(_ error: Error) {
        if
            let error = error as? StripeError,
            case .apiError(let apiError) = error,
            let extraFields = apiError.allResponseFields["extra_fields"] as? [String:Any],
            let institutionUnavailable = extraFields["institution_unavailable"] as? Bool,
            institutionUnavailable
        {
            if let expectedToBeAvailableAt = extraFields["expected_to_be_available_at"] as? TimeInterval {
                let expectedToBeAvailableDate = Date(timeIntervalSince1970: expectedToBeAvailableAt)
                print("~~~~~~~~~~~~~~~~~~ DOWN BANK (SCHEDULED): \(expectedToBeAvailableDate)")
            } else {
                print("~~~~~~~~~~~~~~~~~~ DOWN BANK (UNSCHEDULED)")
            }
            
            return // we handled the error
        }
        
        // if we didn't get specific errors back, we don't know
        // what's wrong, so show a generic error
        print("~~~~~~~~~~~~~~~~~~ DOWN BANK (UNKNOWN ERROR)")
    }
    
    private func openInstitutionAuthenticationWebView(urlString: String?) {
        guard let urlString = urlString, let url = URL(string: urlString) else {
            assertionFailure("Expected to get a URL back from authorization session.")
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
        guard case .success(let authorizationSession) = paneType else {
            assertionFailure("We should never be able to continue on a non-success authorization session.")
            return
        }
        openInstitutionAuthenticationWebView(urlString: authorizationSession.url)
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

/// :nodoc:
@available(iOS 13, *)
@available(iOSApplicationExtension, unavailable)
extension PartnerAuthViewController: ASWebAuthenticationPresentationContextProviding {

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return self.view.window ?? ASPresentationAnchor()
    }
}
