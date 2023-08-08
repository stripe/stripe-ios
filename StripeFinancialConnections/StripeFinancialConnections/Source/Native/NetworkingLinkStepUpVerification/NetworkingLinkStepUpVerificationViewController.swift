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

    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .textDisabled
        activityIndicator.backgroundColor = .customBackgroundColor
        return activityIndicator
    }()
    private lazy var bodyView: NetworkingLinkStepUpVerificationBodyView = {
        let bodyView = NetworkingLinkStepUpVerificationBodyView(
            email: dataSource.consumerSession.emailAddress,
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

        let pane = PaneWithHeaderLayoutView(
            title: STPLocalizedString(
                "Check your email to confirm your identity",
                "The title of a screen where users are asked to enter a one-time-password (OTP) that they received in their email."
            ),
            subtitle: String(
                format: STPLocalizedString(
                    "To keep your Link account safe, we periodically need to confirm you're you. Enter the code sent to your email %@.",
                    "The subtitle/description of a screen where users are asked to enter a one-time-password (OTP) that they received in their email. '%@' is replaced with an email, for example, 'test@test.com'."
                ), "**\(dataSource.consumerSession.emailAddress)**" // asterisks make the e-mail bold
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

    private func didSelectResendCode() {
        otpView.lookupConsumerAndStartVerification()
    }
}

// MARK: - NetworkingOTPViewDelegate

extension NetworkingLinkStepUpVerificationViewController: NetworkingOTPViewDelegate {

    func networkingOTPViewWillStartConsumerLookup(_ view: NetworkingOTPView) {
        if !didShowContent {
            showLoadingView(true)
        } else {
            bodyView.isResendingCode(true)
        }
    }

    func networkingOTPViewConsumerNotFound(_ view: NetworkingOTPView) {
        // side-note: it is redundant to call `showLoadingView` & `isResendingCode` because
        // usually only one needs to be hidden, but this keeps the code simple
        showLoadingView(false)
        bodyView.isResendingCode(false)

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
        showLoadingView(false)
        bodyView.isResendingCode(false)

        handleFailure(error: error, errorName: "LookupConsumerSessionError")
    }

    func networkingOTPViewWillStartVerification(_ view: NetworkingOTPView) {
        // no-op
    }

    func networkingOTPView(_ view: NetworkingOTPView, didStartVerification consumerSession: ConsumerSessionData) {
        // it's important to call this BEFORE we call `showContent` because of `didShowContent`
        if !didShowContent {
            showLoadingView(false)
        } else {
            bodyView.isResendingCode(false)
        }

        showContent()
    }

    func networkingOTPView(_ view: NetworkingOTPView, didFailToStartVerification error: Error) {
        // side-note: it is redundant to call `showLoadingView` & `isResendingCode` because
        // usually only one needs to be hidden, but this keeps the code simple
        showLoadingView(false)
        bodyView.isResendingCode(false)

        handleFailure(error: error, errorName: "StartVerificationSessionError")
    }

    func networkingOTPViewDidConfirmVerification(_ view: NetworkingOTPView) {
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

    func networkingOTPView(_ view: NetworkingOTPView, didTerminallyFailToConfirmVerification error: Error) {
        delegate?.networkingLinkStepUpVerificationViewController(self, didReceiveTerminalError: error)
    }
}
