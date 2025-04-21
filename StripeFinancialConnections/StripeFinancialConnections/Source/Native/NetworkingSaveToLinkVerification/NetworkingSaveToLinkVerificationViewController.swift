//
//  NetworkingSaveToLinkVerification.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/14/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol NetworkingSaveToLinkVerificationViewControllerDelegate: AnyObject {
    func networkingSaveToLinkVerificationViewControllerDidFinish(
        _ viewController: NetworkingSaveToLinkVerificationViewController,
        saveToLinkWithStripeSucceeded: Bool?,
        customSuccessPaneMessage: String?
    )
    func networkingSaveToLinkVerificationViewController(
        _ viewController: NetworkingSaveToLinkVerificationViewController,
        didReceiveTerminalError error: Error
    )
}

final class NetworkingSaveToLinkVerificationViewController: UIViewController {

    private let dataSource: NetworkingSaveToLinkVerificationDataSource
    weak var delegate: NetworkingSaveToLinkVerificationViewControllerDelegate?

    private lazy var loadingView: SpinnerView = {
        return SpinnerView(appearance: dataSource.manifest.appearance)
    }()
    private lazy var otpView: NetworkingOTPView = {
        let otpView = NetworkingOTPView(dataSource: dataSource.networkingOTPDataSource)
        otpView.delegate = self
        return otpView
    }()

    init(dataSource: NetworkingSaveToLinkVerificationDataSource) {
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
        // if we automatically moved to this pane due to
        // prefilled email, we shot the "not now" button
        let showNotNowButton = (dataSource.manifest.accountholderCustomerEmailAddress != nil)
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
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: nil,
                secondaryButtonConfiguration: showNotNowButton ? PaneLayoutView.ButtonConfiguration(
                    title: STPLocalizedString("Not now", "Title of a button that allows users to skip the current screen."),
                    action: { [weak self] in
                        guard let self = self else { return }
                        self.dataSource
                            .analyticsClient
                            .log(eventName: "click.not_now", pane: .networkingSaveToLinkVerification)
                        self.delegate?.networkingSaveToLinkVerificationViewControllerDidFinish(
                            self,
                            saveToLinkWithStripeSucceeded: nil,
                            customSuccessPaneMessage: nil
                        )
                    }
                ) : nil,
                appearance: dataSource.manifest.appearance
            ).footerView
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

    private func markLinkVerified(
        saveToLinkSucceeded: Bool,
        customSuccessPaneMessage: String?
    ) {
        dataSource.markLinkVerified()
            .observe { [weak self] result in
                guard let self else { return }
                switch result {
                case .success:
                    self.delegate?.networkingSaveToLinkVerificationViewControllerDidFinish(
                        self,
                        saveToLinkWithStripeSucceeded: saveToLinkSucceeded,
                        customSuccessPaneMessage: customSuccessPaneMessage
                    )
                case .failure(let error):
                    self.delegate?.networkingSaveToLinkVerificationViewController(
                        self,
                        didReceiveTerminalError: error
                    )
                }

                // only hide loading view after animation
                // to next screen has completed
                DispatchQueue.main.asyncAfter(
                    deadline: .now() + 1.0
                ) { [weak self] in
                    self?.otpView.showLoadingView(false)
                }
            }
    }
}

// MARK: - NetworkingOTPViewDelegate

extension NetworkingSaveToLinkVerificationViewController: NetworkingOTPViewDelegate {

    func networkingOTPViewWillStartVerification(_ view: NetworkingOTPView) {
        showLoadingView(true)
    }

    func networkingOTPView(_ view: NetworkingOTPView, didStartVerification consumerSession: ConsumerSessionData) {
        showLoadingView(false)
        showContent(redactedPhoneNumber: consumerSession.redactedFormattedPhoneNumber)
    }

    func networkingOTPView(_ view: NetworkingOTPView, didFailToStartVerification error: Error) {
        showLoadingView(false)
        dataSource.analyticsClient.log(
            eventName: "networking.verification.error",
            parameters: [
                "error": "StartVerificationSessionError"
            ],
            pane: .networkingSaveToLinkVerification
        )
        dataSource.analyticsClient.logUnexpectedError(
            error,
            errorName: "StartVerificationSessionError",
            pane: .networkingSaveToLinkVerification
        )
        delegate?.networkingSaveToLinkVerificationViewController(self, didReceiveTerminalError: error)
    }

    func networkingOTPViewWillConfirmVerification(_ view: NetworkingOTPView) {
        // no-op
    }

    func networkingOTPViewDidConfirmVerification(_ view: NetworkingOTPView) {
        view.showLoadingView(true)
        dataSource.saveToLink()
            .observe { [weak self] result in
                guard let self else { return }
                let saveToLinkSucceeded: Bool
                let customSuccessPaneMessage: String?
                switch result {
                case .success(let _customSuccessPaneMessage):
                    customSuccessPaneMessage = _customSuccessPaneMessage
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "networking.verification.success",
                            pane: .networkingSaveToLinkVerification
                        )
                    saveToLinkSucceeded = true
                case .failure(let error):
                    customSuccessPaneMessage = nil
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "networking.verification.error",
                            pane: .networkingSaveToLinkVerification
                        )
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "SaveToLinkError",
                            pane: .networkingSaveToLinkVerification
                        )
                    saveToLinkSucceeded = false
                }

                self.markLinkVerified(
                    saveToLinkSucceeded: saveToLinkSucceeded,
                    customSuccessPaneMessage: customSuccessPaneMessage
                )
            }
    }

    func networkingOTPView(
        _ view: NetworkingOTPView,
        didFailToConfirmVerification error: Error,
        isTerminal: Bool
    ) {
        if isTerminal {
            delegate?.networkingSaveToLinkVerificationViewController(
                self,
                didReceiveTerminalError: error
            )
        }
    }
}
