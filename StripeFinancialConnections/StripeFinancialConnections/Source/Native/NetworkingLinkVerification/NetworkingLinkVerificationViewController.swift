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
        consumerSession: ConsumerSessionData?,
        preventBackNavigation: Bool
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
        return SpinnerView(appearance: dataSource.manifest.appearance)
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
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background
        otpView.startVerification()
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
                    "Enter the code sent to %@",
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

    private func requestNextPane(_ pane: FinancialConnectionsSessionManifest.NextPane, preventBackNavigation: Bool) {
        delegate?.networkingLinkVerificationViewController(
            self,
            didRequestNextPane: pane,
            consumerSession: dataSource.consumerSession,
            preventBackNavigation: preventBackNavigation
        )
    }

    private func attachConsumerToLinkAccountAndSynchronize(from view: NetworkingOTPView) {
        view.showLoadingView(true)

        dataSource
            .attachConsumerToLinkAccountAndSynchronize()
            .observe { [weak self] result in
                guard let self else { return }
                self.hideOTPLoadingViewAfterDelay(view)

                switch result {
                case .success:
                    self.requestNextPane(.linkAccountPicker, preventBackNavigation: true)
                case .failure(let error):
                    self.delegate?.networkingLinkVerificationViewController(self, didReceiveTerminalError: error)
                }
            }
    }

    private func hideOTPLoadingViewAfterDelay(_ view: NetworkingOTPView) {
        // only hide loading view after animation
        // to next screen has completed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak view] in
            view?.showLoadingView(false)
        }
    }
}

// MARK: - NetworkingOTPViewDelegate

extension NetworkingLinkVerificationViewController: NetworkingOTPViewDelegate {

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
        if dataSource.manifest.isProductInstantDebits {
            attachConsumerToLinkAccountAndSynchronize(from: view)
            return
        }

        view.showLoadingView(true)
        dataSource.markLinkVerified()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    if self.dataSource.manifest.isProductInstantDebits {
                        self.attachConsumerToLinkAccountAndSynchronize(from: view)
                    } else {
                        self.dataSource.analyticsClient.log(
                            eventName: "networking.verification.success",
                            pane: .networkingLinkVerification
                        )
                        self.requestNextPane(.linkAccountPicker, preventBackNavigation: false)
                    }
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
                    self.requestNextPane(nextPane, preventBackNavigation: false)
                }

                self.hideOTPLoadingViewAfterDelay(view)
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
