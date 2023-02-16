//
//  NetworkingLinkStepUpVerificationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/16/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol NetworkingLinkStepUpVerificationViewControllerDelegate: AnyObject {
    func networkingLinkStepUpVerificationViewController(
        _ viewController: NetworkingLinkStepUpVerificationViewController,
        didRequestNextPane nextPane: FinancialConnectionsSessionManifest.NextPane,
        consumerSession: ConsumerSessionData
    )
    func networkingLinkStepUpVerificationViewController(
        _ viewController: NetworkingLinkStepUpVerificationViewController,
        didReceiveTerminalError error: Error
    )
}

@available(iOSApplicationExtension, unavailable)
final class NetworkingLinkStepUpVerificationViewController: UIViewController {

    private let dataSource: NetworkingLinkStepUpVerificationDataSource
    weak var delegate: NetworkingLinkStepUpVerificationViewControllerDelegate?

    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .textDisabled
        activityIndicator.backgroundColor = .customBackgroundColor
        return activityIndicator
    }()
    private lazy var bodyView: NetworkingLinkStepUpVerificationBodyView = {
        let bodyView = NetworkingLinkStepUpVerificationBodyView(email: dataSource.accountholderCustomerEmailAddress)
        bodyView.delegate = self
        return bodyView
    }()

    init(dataSource: NetworkingLinkStepUpVerificationDataSource) {
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
        dataSource.startVerificationSession()
            .observe { [weak self] result in
                guard let self = self else { return }
                self.showLoadingView(false)
                switch result {
                case .success(let consumerSessionResponse):
                    self.showContent(redactedPhoneNumber: consumerSessionResponse.consumerSession.redactedPhoneNumber)
                case .failure(let error):
                    self.dataSource.analyticsClient.log(
                        eventName: "networking.verification.error",
                        parameters: [
                            // TODO(kgaidis): figure out a proper way to log this error
                            "error": "here"
                        ],
                        pane: .networkingLinkStepUpVerification
                    )
                    self.delegate?.networkingLinkStepUpVerificationViewController(self, didReceiveTerminalError: error)
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
            delegate?.networkingLinkStepUpVerificationViewController(
                self,
                didRequestNextPane: pane,
                consumerSession: consumerSession
            )
        } else {
            assertionFailure("logic error: did not have consumerSession")
            delegate?.networkingLinkStepUpVerificationViewController(self, didReceiveTerminalError: FinancialConnectionsSheetError.unknown(debugDescription: "logic error: did not have consumerSession"))
        }
    }
}

// MARK: - NetworkingLinkStepUpVerificationBodyViewDelegate

@available(iOSApplicationExtension, unavailable)
extension NetworkingLinkStepUpVerificationViewController: NetworkingLinkStepUpVerificationBodyViewDelegate {

    func networkingLinkStepUpVerificationBodyView(
        _ view: NetworkingLinkStepUpVerificationBodyView,
        didEnterValidOTPCode otpCode: String
    ) {
        view.otpTextField.text = "CONFIRMING OTP..."

        dataSource.confirmVerificationSession(otpCode: otpCode)
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    view.otpTextField.text = "SUCCESS! CALLING markLinkVerified..."

                    self.dataSource.markLinkVerified()
                        .observe { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success(let manifest):
                                view.otpTextField.text = "markLinkVerified SUCCESS! Wait on accounts..."

                                self.dataSource.fetchNetworkedAccounts()
                                    .observe { [weak self] result in
                                        guard let self = self else { return }
                                        switch result {
                                        case .success(let networkedAccountsResponse):
                                            let networkedAccounts = networkedAccountsResponse.data
                                            if networkedAccounts.isEmpty {
                                                self.dataSource.analyticsClient.log(
                                                    eventName: "networking.verification.success_no_accounts",
                                                    pane: .networkingLinkStepUpVerification
                                                )
                                                self.requestNextPane(manifest.nextPane)
                                            } else {
                                                self.dataSource.analyticsClient.log(
                                                    eventName: "networking.verification.success",
                                                    pane: .networkingLinkStepUpVerification
                                                )
                                                self.requestNextPane(.linkAccountPicker)
                                            }
                                        case .failure(let error):
                                            // TODO(kgaidis): log the error using the standard error logging too
                                            self.dataSource
                                                .analyticsClient
                                                .log(
                                                    eventName: "networking.verification.error",
                                                    parameters: [
                                                        "error": "NetworkedAccountsRetrieveMethodError",
                                                    ],
                                                    pane: .networkingLinkStepUpVerification
                                                )
                                            print(error) // TODO(kgaidis): remove print
                                            self.requestNextPane(manifest.nextPane)
                                        }
                                    }
                            case .failure(let error):
                                print(error) // TODO(kgaidis): remove print
                                view.otpTextField.text = "markLinkVerified FAILURE: \(error.localizedDescription)"
                                // TODO(kgaidis): go to terminal error but double-check
                                self.delegate?.networkingLinkStepUpVerificationViewController(self, didReceiveTerminalError: error)
                            }
                        }
                case .failure(let error):
                    print(error) // TODO(kgaidis): remove print
                    view.otpTextField.text = "FAILURE...\(error.localizedDescription)"
                    // TODO(kgaidis): display various known errors, or if unknown error, show terminal error
                }
            }
    }
}
