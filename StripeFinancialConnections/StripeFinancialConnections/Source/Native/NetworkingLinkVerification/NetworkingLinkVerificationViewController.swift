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

final class NetworkingLinkVerificationViewController: UIViewController {

    private let dataSource: NetworkingLinkVerificationDataSource
    weak var delegate: NetworkingLinkVerificationViewControllerDelegate?

    private lazy var loadingView: UIView = {
        return SpinnerView()
    }()
    private lazy var otpView: NetworkingOTPView = {
        let otpView = NetworkingOTPView(dataSource: dataSource.networkingOTPDataSource)
        otpView.delegate = self
        return otpView
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
        otpView.lookupConsumerAndStartVerification()
    }

    private func showContent(redactedPhoneNumber: String) {
        let paneLayoutView = PaneLayoutView(
            contentView: PaneLayoutView.createContentView(
                iconView: nil,
                title: STPLocalizedString(
                    "Confirm it's you",
                    "The title of a screen where users are informed that they can sign-in-to Link."
                ),
                subtitle: String(format: STPLocalizedString(
                    "Enter the code sent to %@.",
                    "The subtitle/description of a screen where users are informed that they have received a One-Type-Password (OTP) to their phone. '%@' gets replaced by a redacted phone number."
                ), AuthFlowHelpers.formatRedactedPhoneNumber(redactedPhoneNumber)),
                contentView: otpView
            ),
            footerView: nil
        )
        paneLayoutView.addTo(view: view)
    }

    private func showLoadingView(_ show: Bool) {
        if show && loadingView.superview == nil {
            // first-time we are showing this, so add the view to hierarchy
            view.addAndPinSubviewToSafeArea(loadingView)
        }

        loadingView.isHidden = !show
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

// MARK: - NetworkingOTPViewDelegate

extension NetworkingLinkVerificationViewController: NetworkingOTPViewDelegate {

    func networkingOTPViewWillStartConsumerLookup(_ view: NetworkingOTPView) {
        showLoadingView(true)
    }

    func networkingOTPViewConsumerNotFound(_ view: NetworkingOTPView) {
        dataSource.analyticsClient.log(
            eventName: "networking.verification.error",
            parameters: [
                "error": "ConsumerNotFoundError"
            ],
            pane: .networkingLinkVerification
        )
        delegate?.networkingLinkVerificationViewController(self, didRequestNextPane: .institutionPicker, consumerSession: nil)
        showLoadingView(false) // started in networkingOTPViewWillStartConsumerLookup
    }

    func networkingOTPView(_ view: NetworkingOTPView, didFailConsumerLookup error: Error) {
        dataSource.analyticsClient.logUnexpectedError(
            error,
            errorName: "LookupConsumerSessionError",
            pane: .networkingLinkVerification
        )
        dataSource.analyticsClient.log(
            eventName: "networking.verification.error",
            parameters: [
                "error": "LookupConsumerSession"
            ],
            pane: .networkingLinkVerification
        )
        delegate?.networkingLinkVerificationViewController(self, didReceiveTerminalError: error)
        showLoadingView(false) // started in networkingOTPViewWillStartConsumerLookup
    }

    func networkingOTPViewWillStartVerification(_ view: NetworkingOTPView) {
        // no-op
    }

    func networkingOTPView(_ view: NetworkingOTPView, didStartVerification consumerSession: ConsumerSessionData) {
        showLoadingView(false) // started in networkingOTPViewWillStartConsumerLookup
        showContent(redactedPhoneNumber: consumerSession.redactedFormattedPhoneNumber)
    }

    func networkingOTPView(_ view: NetworkingOTPView, didFailToStartVerification error: Error) {
        showLoadingView(false) // started in networkingOTPViewWillStartConsumerLookup

        dataSource.analyticsClient.logUnexpectedError(
            error,
            errorName: "StartVerificationSessionError",
            pane: .networkingLinkVerification
        )
        dataSource.analyticsClient.log(
            eventName: "networking.verification.error",
            parameters: [
                "error": "StartVerificationSession"
            ],
            pane: .networkingLinkVerification
        )
        delegate?.networkingLinkVerificationViewController(self, didReceiveTerminalError: error)
    }

    func networkingOTPViewWillConfirmVerification(_ view: NetworkingOTPView) {
        // no-op
    }

    func networkingOTPViewDidConfirmVerification(_ view: NetworkingOTPView) {
        view.showLoadingView(true)
        dataSource.markLinkVerified()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.dataSource.analyticsClient.log(
                        eventName: "networking.verification.success",
                        pane: .networkingLinkVerification
                    )
                    self.requestNextPane(.linkAccountPicker)
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "networking.verification.error",
                            parameters: [
                                "error": "MarkLinkVerifiedError",
                            ],
                            pane: .networkingLinkVerification
                        )
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "MarkLinkVerifiedError",
                            pane: .networkingLinkVerification
                        )

                    let nextPane: FinancialConnectionsSessionManifest.NextPane
                    if self.dataSource.manifest.initialInstitution != nil {
                        nextPane = .partnerAuth
                    } else {
                        nextPane = .institutionPicker
                    }
                    self.requestNextPane(nextPane)
                }

                // only hide loading view after animation
                // to next screen has completed
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1.0
                ) { [weak view] in
                    view?.showLoadingView(false)
                }
            }
    }

    func networkingOTPView(
        _ view: NetworkingOTPView,
        didFailToConfirmVerification error: Error,
        isTerminal: Bool
    ) {
        if isTerminal {
            delegate?.networkingLinkVerificationViewController(
                self,
                didReceiveTerminalError: error
            )
        }
    }
}
