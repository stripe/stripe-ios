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
        error: Error?
    )
    func networkingSaveToLinkVerificationViewController(
        _ viewController: NetworkingSaveToLinkVerificationViewController,
        didReceiveTerminalError error: Error
    )
}

final class NetworkingSaveToLinkVerificationViewController: UIViewController {

    private let dataSource: NetworkingSaveToLinkVerificationDataSource
    weak var delegate: NetworkingSaveToLinkVerificationViewControllerDelegate?

    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .textDisabled
        activityIndicator.backgroundColor = .customBackgroundColor
        return activityIndicator
    }()
    private lazy var bodyView: NetworkingSaveToLinkVerificationBodyView = {
        let bodyView = NetworkingSaveToLinkVerificationBodyView(
            email: dataSource.consumerSession.emailAddress,
            otpView: otpView
        )
        return bodyView
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
        view.backgroundColor = .customBackgroundColor

        otpView.startVerification()
    }

    private func showContent(redactedPhoneNumber: String) {
        let pane = PaneWithHeaderLayoutView(
            title: STPLocalizedString(
                "Sign in to Link",
                "The title of a screen where users are informed that they can sign-in-to Link."
            ),
            subtitle: String(format: STPLocalizedString(
                "Enter the code sent to %@.",
                "The subtitle/description of a screen where users are informed that they have received a One-Type-Password (OTP) to their phone. '%@' gets replaced by a redacted phone number."
            ), redactedPhoneNumber),
            contentView: bodyView,
            footerView: NetworkingSaveToLinkFooterView(
                didSelectNotNow: { [weak self] in
                    guard let self = self else { return }
                    self.dataSource
                        .analyticsClient
                        .log(eventName: "click.not_now", pane: .networkingSaveToLinkVerification)
                    self.delegate?.networkingSaveToLinkVerificationViewControllerDidFinish(
                        self,
                        saveToLinkWithStripeSucceeded: nil,
                        error: nil
                    )
                }
            )
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
}

// MARK: - NetworkingOTPViewDelegate

extension NetworkingSaveToLinkVerificationViewController: NetworkingOTPViewDelegate {

    func networkingOTPViewWillStartVerification(_ view: NetworkingOTPView) {
        showLoadingView(true)
    }

    func networkingOTPView(_ view: NetworkingOTPView, didStartVerification consumerSession: ConsumerSessionData) {
        showLoadingView(false)
        showContent(redactedPhoneNumber: consumerSession.redactedPhoneNumber)
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

    func networkingOTPViewDidConfirmVerification(_ view: NetworkingOTPView) {
        dataSource.saveToLink()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "networking.verification.success",
                            pane: .networkingSaveToLinkVerification
                        )
                    self.delegate?.networkingSaveToLinkVerificationViewControllerDidFinish(
                        self,
                        saveToLinkWithStripeSucceeded: true,
                        error: nil
                    )
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .log(
                            eventName: "networking.verification.error",
                            pane: .networkingSaveToLinkVerification
                        )
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error, errorName: "SaveToLinkError",
                            pane: .networkingSaveToLinkVerification
                        )
                    self.delegate?.networkingSaveToLinkVerificationViewControllerDidFinish(
                        self,
                        saveToLinkWithStripeSucceeded: false,
                        error: error
                    )
                }
            }

        dataSource.markLinkVerified()
            .observe { _ in
                // we ignore result
            }
    }

    func networkingOTPView(_ view: NetworkingOTPView, didTerminallyFailToConfirmVerification error: Error) {
        delegate?.networkingSaveToLinkVerificationViewController(self, didReceiveTerminalError: error)
    }

    func networkingOTPViewWillStartConsumerLookup(_ view: NetworkingOTPView) {
        assertionFailure("we shouldn't call `lookup` for NetworkingSaveToLink")
    }

    func networkingOTPViewConsumerNotFound(_ view: NetworkingOTPView) {
        assertionFailure("we shouldn't call `lookup` for NetworkingSaveToLink")
    }

    func networkingOTPView(_ view: NetworkingOTPView, didFailConsumerLookup error: Error) {
        assertionFailure("we shouldn't call `lookup` for NetworkingSaveToLink")
    }
}
