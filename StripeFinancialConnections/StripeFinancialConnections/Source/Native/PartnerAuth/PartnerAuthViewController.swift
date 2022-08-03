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
protocol PartnerAuthViewControllerDelegate: AnyObject {
    func partnerAuthViewControllerDidRequestBankPicker(_ viewController: PartnerAuthViewController)
    func partnerAuthViewControllerDidRequestManualEntry(_ viewController: PartnerAuthViewController)
    func partnerAuthViewControllerDidSelectClose(_ viewController: PartnerAuthViewController)
}

@available(iOSApplicationExtension, unavailable)
final class PartnerAuthViewController: UIViewController {
    
    enum PaneType {
        case success(FinancialConnectionsAuthorizationSession)
        case error(Error)
    }
    
    private let paneType: PaneType
    private let institution: FinancialConnectionsInstitution
    weak var delegate: PartnerAuthViewControllerDelegate?
    
    init(
        institution: FinancialConnectionsInstitution,
        paneType: PaneType
    ) {
        self.paneType = paneType
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
            handlePaneTypeSuccess(authorizationSession)
        case .error(let error):
            handlePaneTypeError(error)
        }
    }
    
    private func handlePaneTypeSuccess(_ authorizationSession: FinancialConnectionsAuthorizationSession) {
        let shouldShowPrepane = (authorizationSession.flow?.isOAuth() ?? false)
        if shouldShowPrepane {
            let prepaneView = PrepaneView(
                institutionName: institution.name,
                partnerName: (authorizationSession.showPartnerDisclosure ?? false) ? authorizationSession.flow?.toInstitutionName() : nil,
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
    
    private func handlePaneTypeError(_ error: Error) {
        let errorView: UIView
        if
            let error = error as? StripeError,
            case .apiError(let apiError) = error,
            let extraFields = apiError.allResponseFields["extra_fields"] as? [String:Any],
            let institutionUnavailable = extraFields["institution_unavailable"] as? Bool,
            institutionUnavailable
        {
            let primaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: STPLocalizedString("Select another bank", "The title of a button in a screen that shows an error. The error indicates that the bank user selected is currently under maintenance. The button allows users to go back to selecting a different bank. Hopefully a bank that is not under maintenance!"),
                action: { [weak self] in
                    self?.navigateBackToBankPicker()
                }
            )
            if let expectedToBeAvailableAt = extraFields["expected_to_be_available_at"] as? TimeInterval {
                let expectedToBeAvailableDate = Date(timeIntervalSince1970: expectedToBeAvailableAt)
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .short
                let expectedToBeAvailableTimeString = dateFormatter.string(from: expectedToBeAvailableDate)
                errorView = ReusableInformationView(
                    iconType: .loading,
                    title: String(format: STPLocalizedString("%@ is undergoing maintenance", "Title of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."), institution.name),
                    subtitle: String(format: STPLocalizedString("Maintenance is scheduled to end at %@. Please select another bank or try again later.", "The subtitle/description of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."), expectedToBeAvailableTimeString),
                    primaryButtonConfiguration: primaryButtonConfiguration
                )
            } else {
                errorView = ReusableInformationView(
                    iconType: .loading,
                    title: String(format: STPLocalizedString("%@ is currently unavailable", "Title of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."), institution.name),
                    subtitle:  STPLocalizedString("Please enter your bank details manually or select another bank.", "The subtitle/description of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."),
                    primaryButtonConfiguration: primaryButtonConfiguration,
                    secondaryButtonConfiguration: ReusableInformationView.ButtonConfiguration(
                        title: STPLocalizedString("Enter bank details manually", "The title of a button in a screen that shows an error. The error indicates that the bank user selected is currently under maintenance. The button allows users to manually enter their bank details (ex. routing number and account number)."),
                        action: { [weak self] in
                            guard let self = self else { return }
                            self.delegate?.partnerAuthViewControllerDidRequestManualEntry(self)
                        }
                    )
                )
            }
        } else {
            // if we didn't get specific errors back, we don't know
            // what's wrong, so show a generic error
            errorView = ReusableInformationView(
                iconType: .loading,
                title: STPLocalizedString("Something went wrong", "Title of a screen that shows an error. The error screen appears after user has selected a bank. The error is a generic one: something wrong happened and we are not sure what."),
                subtitle: STPLocalizedString("Your account can't be linked at this time. Please try again later.", "The subtitle/description of a screen that shows an error. The error screen appears after user has selected a bank. The error is a generic one: something wrong happened and we are not sure what."),
                primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration(
                    title: "Close", // TODO(kgaidis): once we localize use String.Localized.close
                    action: { [weak self] in
                        guard let self = self else { return }
                        self.delegate?.partnerAuthViewControllerDidSelectClose(self)
                    }
                )
            )
            navigationItem.hidesBackButton = true
        }
        view.addAndPinSubviewToSafeArea(errorView)
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
                    self?.navigateBackToBankPicker()
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
    
    private func navigateBackToBankPicker() {
        delegate?.partnerAuthViewControllerDidRequestBankPicker(self)
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
