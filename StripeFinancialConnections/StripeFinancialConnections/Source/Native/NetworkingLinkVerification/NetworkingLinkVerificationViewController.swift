//
//  NetworkingLinkVerificationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkVerificationViewControllerDelegate: AnyObject {
    func networkingLinkVerificationViewController(
        _ viewController: NetworkingLinkVerificationViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        consumerSession: ConsumerSessionData?
    )
    func networkingLinkVerificationViewController(
        _ viewController: NetworkingLinkVerificationViewController,
        didReceiveTerminalError error: Error
    )
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkVerificationViewController: UIViewController {

    private let dataSource: NetworkingLinkVerificationDataSource
    weak var delegate: NetworkingLinkVerificationViewControllerDelegate?

    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .textDisabled
        activityIndicator.backgroundColor = .customBackgroundColor
        return activityIndicator
    }()
    private lazy var bodyView: NetworkingLinkVerificationBodyView = {
        let bodyView = NetworkingLinkVerificationBodyView(email: dataSource.accountholderCustomerEmailAddress)
        bodyView.delegate = self
        return bodyView
    }()

    init(dataSource: NetworkingLinkVerificationDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        showLoadingView(true)
        dataSource.lookupConsumerSession()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let lookupConsumerSessionResponse):
                    if lookupConsumerSessionResponse.exists {
                        self.dataSource.startVerificationSession()
                            .observe { [weak self] result in
                                guard let self = self else { return }
                                self.showLoadingView(false)
                                switch result {
                                case .success(let consumerSessionResponse):
                                    self.showContent(redactedPhoneNumber: consumerSessionResponse.consumerSession.redactedPhoneNumber)
                                case .failure(let error):
                                    self.dataSource.analyticsClient.logUnexpectedError(
                                        error,
                                        errorName: "StartVerificationSessionError",
                                        pane: .networkingLinkVerification
                                    )
                                    self.dataSource.analyticsClient.log(
                                        eventName: "networking.verification.error",
                                        parameters: [
                                            "error": "StartVerificationSession"
                                        ],
                                        pane: .networkingLinkVerification
                                    )
                                    self.delegate?.networkingLinkVerificationViewController(self, didReceiveTerminalError: error)
                                }
                            }
                    } else {
                        self.dataSource.analyticsClient.log(
                            eventName: "networking.verification.error",
                            parameters: [
                                "error": "ConsumerNotFoundError"
                            ],
                            pane: .networkingLinkVerification
                        )
                        self.delegate?.networkingLinkVerificationViewController(self, didRequestNextPane: .institutionPicker, consumerSession: nil)
                        self.showLoadingView(false)
                    }
                case .failure(let error):
                    self.dataSource.analyticsClient.logUnexpectedError(
                        error,
                        errorName: "LookupConsumerSessionError",
                        pane: .networkingLinkVerification
                    )
                    self.dataSource.analyticsClient.log(
                        eventName: "networking.verification.error",
                        parameters: [
                            "error": "LookupConsumerSession"
                        ],
                        pane: .networkingLinkVerification
                    )
                    self.delegate?.networkingLinkVerificationViewController(self, didReceiveTerminalError: error)
                    self.showLoadingView(false)
                }
            }
    }

    private func showContent(redactedPhoneNumber: String) {
        let pane = PaneWithHeaderLayoutView(
            title: STPLocalizedString(
                "Sign in to Link",
                "The title of a screen where users are informed that they can sign-in-to Link."
            ),
            subtitle: STPLocalizedString(
                "Enter the code sent to \(redactedPhoneNumber)",
                "The subtitle/description of a screen where users are informed that they have received a One-Type-Password (OTP) to their phone."
            ),
            contentView: bodyView,
            footerView: nil
        )
        pane.addTo(view: view)
        
        bodyView.otpTextField.becomeFirstResponder()
    }

    private func showLoadingView(_ show: Bool) {
        if show && loadingView.superview == nil {
            // first-time we are showing this, so add the view to hierarchy
            view.addAndPinSubview(loadingView)
        }

        loadingView.isHidden = !show
        if show {
            loadingView.startAnimating()
        } else {
            loadingView.stopAnimating()
        }
        view.bringSubviewToFront(loadingView)  // defensive programming to avoid loadingView being hiddden
    }

    private func requestNextPane(_ pane: FinancialConnectionsSessionManifest.NextPane) {
        if let consumerSession = dataSource.consumerSession {
            delegate?.networkingLinkVerificationViewController(
                self,
                didRequestNextPane: pane,
                consumerSession: consumerSession
            )
        } else {
            assertionFailure("logic error: did not have consumerSession")
            delegate?.networkingLinkVerificationViewController(self, didReceiveTerminalError: FinancialConnectionsSheetError.unknown(debugDescription: "logic error: did not have consumerSession"))
        }
    }
}

// MARK: - NetworkingLinkVerificationBodyViewDelegate

@available(iOSApplicationExtension, unavailable)
extension NetworkingLinkVerificationViewController: NetworkingLinkVerificationBodyViewDelegate {

    func networkingLinkVerificationBodyView(
        _ bodyView: NetworkingLinkVerificationBodyView,
        didEnterValidOTPCode otpCode: String
    ) {
        bodyView.otpTextField.resignFirstResponder()
        // TODO(kgaidis): consider implementing a loading/grayed-out state for `otpTextField`
        
        dataSource.confirmVerificationSession(otpCode: otpCode)
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.dataSource.markLinkVerified()
                        .observe { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success(let manifest):
                                self.dataSource.fetchNetworkedAccounts()
                                    .observe { [weak self] result in
                                        guard let self = self else { return }
                                        switch result {
                                        case .success(let networkedAccountsResponse):
                                            let networkedAccounts = networkedAccountsResponse.data
                                            if networkedAccounts.isEmpty {
                                                self.dataSource.analyticsClient.log(
                                                    eventName: "networking.verification.success_no_accounts",
                                                    pane: .networkingLinkVerification
                                                )
                                                self.requestNextPane(manifest.nextPane)
                                            } else {
                                                self.dataSource.analyticsClient.log(
                                                    eventName: "networking.verification.success",
                                                    pane: .networkingLinkVerification
                                                )
                                                self.requestNextPane(.linkAccountPicker)
                                            }
                                        case .failure(let error):
                                            self.dataSource
                                                .analyticsClient
                                                .logUnexpectedError(
                                                    error,
                                                    errorName: "FetchNetworkedAccountsError",
                                                    pane: .networkingLinkVerification
                                                )
                                            self.dataSource
                                                .analyticsClient
                                                .log(
                                                    eventName: "networking.verification.error",
                                                    parameters: [
                                                        "error": "NetworkedAccountsRetrieveMethodError",
                                                    ],
                                                    pane: .networkingLinkVerification
                                                )
                                            self.requestNextPane(manifest.nextPane)
                                        }
                                    }
                            case .failure(let error):
                                self.dataSource
                                    .analyticsClient
                                    .logUnexpectedError(
                                        error,
                                        errorName: "MarkLinkVerifiedError",
                                        pane: .networkingLinkVerification
                                    )
                                // TODO(kgaidis): go to terminal error but double-check
                                self.delegate?.networkingLinkVerificationViewController(self, didReceiveTerminalError: error)
                            }
                        }
                case .failure(let error):
                    bodyView.otpTextField.performInvalidCodeAnimation(shouldClearValue: false)
                    // TODO(kgaidis): display various known errors, or if unknown error, show terminal error
                    bodyView.showErrorText(error.localizedDescription)
                }
            }
    }
}
