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

protocol NetworkingLinkStepUpVerificationViewControllerDelegate: AnyObject {
    func networkingLinkStepUpVerificationViewController(
        _ viewController: NetworkingLinkStepUpVerificationViewController,
        didCompleteVerificationWithInstitution institution: FinancialConnectionsInstitution
    )
    func networkingLinkStepUpVerificationViewController(
        _ viewController: NetworkingLinkStepUpVerificationViewController,
        didReceiveTerminalError error: Error
    )
    func networkingLinkStepUpVerificationViewControllerEncounteredSoftError(
        _ viewController: NetworkingLinkStepUpVerificationViewController
    )
}

final class NetworkingLinkStepUpVerificationViewController: UIViewController {

    private let dataSource: NetworkingLinkStepUpVerificationDataSource
    weak var delegate: NetworkingLinkStepUpVerificationViewControllerDelegate?

    private lazy var fullScreenLoadingView: UIView = {
        return SpinnerView()
    }()
    private lazy var bodyView: NetworkingLinkStepUpVerificationBodyView = {
        let bodyView = NetworkingLinkStepUpVerificationBodyView(
            otpView: otpView,
            didSelectResendCode: { [weak self] in
                self?.didSelectResendCode()
            }
        )
        return bodyView
    }()
    private lazy var otpView: NetworkingOTPView = {
        let otpView = NetworkingOTPView(dataSource: dataSource.networkingOTPDataSource)
        otpView.delegate = self
        return otpView
    }()
    // used to track whether we show loading view when calling `lookupConsumerAndStartVerification`
    private var didShowContent: Bool = false

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

        otpView.lookupConsumerAndStartVerification()
    }

    private func handleFailure(error: Error, errorName: String) {
        dataSource.analyticsClient.log(
            eventName: "networking.verification.step_up.error",
            parameters: [
                "error": errorName
            ],
            pane: .networkingLinkStepUpVerification
        )
        dataSource.analyticsClient.logUnexpectedError(
            error,
            errorName: errorName,
            pane: .networkingLinkStepUpVerification
        )
        delegate?.networkingLinkStepUpVerificationViewController(
            self,
            didReceiveTerminalError: error
        )
    }

    private func showContent() {
        didShowContent = true

        let paneLayoutView = PaneLayoutView(
            contentView: PaneLayoutView.createContentView(
                iconView: nil,
                title: STPLocalizedString(
                    "Verify your email",
                    "The title of a screen where users are asked to enter a one-time-password (OTP) that they received in their email."
                ),
                subtitle: String(
                    format: STPLocalizedString(
                        "Enter the code sent to %@. We periodically request this extra step to keep your account safe.",
                        "The subtitle/description of a screen where users are asked to enter a one-time-password (OTP) that they received in their email. '%@' is replaced with an email, for example, 'test@test.com'."
                    ), dataSource.consumerSession.emailAddress
                ),
                contentView: bodyView
            ),
            footerView: nil
        )
        paneLayoutView.addTo(view: view)
    }

    private func showFullScreenLoadingView(_ show: Bool) {
        if show && fullScreenLoadingView.superview == nil {
            // first-time we are showing this, so add the view to hierarchy
            view.addAndPinSubview(fullScreenLoadingView)
        }

        fullScreenLoadingView.isHidden = !show
        view.bringSubviewToFront(fullScreenLoadingView)  // defensive programming to avoid loadingView being hiddden
    }

    private func showSmallLoadingView(_ showLoadingView: Bool) {
        bodyView.showResendCodeLabel(!showLoadingView)
        otpView.showLoadingView(showLoadingView)
    }

    private func didSelectResendCode() {
        otpView.lookupConsumerAndStartVerification()
    }
}

// MARK: - NetworkingOTPViewDelegate

extension NetworkingLinkStepUpVerificationViewController: NetworkingOTPViewDelegate {

    func networkingOTPViewWillStartConsumerLookup(_ view: NetworkingOTPView) {
        if !didShowContent {
            showFullScreenLoadingView(true)
        } else {
            showSmallLoadingView(true)
        }
    }

    func networkingOTPViewConsumerNotFound(_ view: NetworkingOTPView) {
        // side-note: it is redundant to call `showLoadingView` & `showSmallLoadingView` because
        // usually only one needs to be hidden, but this keeps the code simple
        showFullScreenLoadingView(false)
        showSmallLoadingView(false)

        dataSource.analyticsClient.log(
            eventName: "networking.verification.step_up.error",
            parameters: [
                "error": "ConsumerNotFoundError",
            ],
            pane: .networkingLinkStepUpVerification
        )
        delegate?.networkingLinkStepUpVerificationViewControllerEncounteredSoftError(self)
    }

    func networkingOTPView(_ view: NetworkingOTPView, didFailConsumerLookup error: Error) {
        // side-note: it is redundant to call both (`showLoadingView` & `isResendingCode`) because
        // only one needs to be hidden (depends on the state), but this keeps the code simple
        showFullScreenLoadingView(false)
        showSmallLoadingView(false)

        handleFailure(error: error, errorName: "LookupConsumerSessionError")
    }

    func networkingOTPViewWillStartVerification(_ view: NetworkingOTPView) {
        // no-op
    }

    func networkingOTPView(_ view: NetworkingOTPView, didStartVerification consumerSession: ConsumerSessionData) {
        // it's important to call this BEFORE we call `showContent` because of `didShowContent`
        if !didShowContent {
            showFullScreenLoadingView(false)
        } else {
            showSmallLoadingView(false)
        }

        showContent()
    }

    func networkingOTPView(_ view: NetworkingOTPView, didFailToStartVerification error: Error) {
        // side-note: it is redundant to call `showLoadingView` & `showSmallLoadingView` because
        // usually only one needs to be hidden, but this keeps the code simple
        showFullScreenLoadingView(false)
        showSmallLoadingView(false)

        handleFailure(error: error, errorName: "StartVerificationSessionError")
    }

    func networkingOTPViewWillConfirmVerification(_ view: NetworkingOTPView) {
        showSmallLoadingView(true)
    }

    func networkingOTPViewDidConfirmVerification(_ view: NetworkingOTPView) {
        showSmallLoadingView(true)
        dataSource.markLinkStepUpAuthenticationVerified()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "networking.verification.step_up.success",
                            pane: .networkingLinkStepUpVerification
                        )
                    self.dataSource.selectNetworkedAccount()
                        .observe { [weak self] result in
                            guard let self = self else { return }
                            switch result {
                            case .success(let institutionList):
                                self.dataSource
                                    .analyticsClient
                                    .log(
                                        eventName: "click.link_accounts",
                                        pane: .networkingLinkStepUpVerification
                                    )

                                if let institution = institutionList.data.first {
                                    self.delegate?.networkingLinkStepUpVerificationViewController(
                                        self,
                                        didCompleteVerificationWithInstitution: institution
                                    )
                                } else {
                                    // this shouldn't happen, but in case it does, we navigate to `institutionPicker` so user
                                    // could still have a chance at successfully connecting their account
                                    self.delegate?.networkingLinkStepUpVerificationViewControllerEncounteredSoftError(self)
                                }

                                // only hide loading view after animation
                                // to next screen has completed
                                DispatchQueue.main.asyncAfter(
                                    deadline: .now() + 1.0
                                ) { [weak self] in
                                    self?.showSmallLoadingView(false)
                                }
                            case .failure(let error):
                                self.dataSource
                                    .analyticsClient
                                    .logUnexpectedError(
                                        error,
                                        errorName: "SelectNetworkedAccountError",
                                        pane: .networkingLinkStepUpVerification
                                    )
                                self.delegate?.networkingLinkStepUpVerificationViewController(
                                    self,
                                    didReceiveTerminalError: error
                                )
                            }
                        }
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "MarkLinkStepUpAuthenticationVerifiedError",
                            pane: .networkingLinkStepUpVerification
                        )
                    self.delegate?.networkingLinkStepUpVerificationViewController(
                        self,
                        didReceiveTerminalError: error
                    )
                }
            }
    }

    func networkingOTPView(
        _ view: NetworkingOTPView,
        didFailToConfirmVerification error: Error,
        isTerminal: Bool
    ) {
        showSmallLoadingView(false)

        if isTerminal {
            delegate?.networkingLinkStepUpVerificationViewController(
                self,
                didReceiveTerminalError: error
            )
        }
    }
}
