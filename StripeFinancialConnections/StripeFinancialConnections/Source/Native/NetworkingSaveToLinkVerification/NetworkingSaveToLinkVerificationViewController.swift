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

@available(iOSApplicationExtension, unavailable)
protocol NetworkingSaveToLinkVerificationViewControllerDelegate: AnyObject {
    func networkingSaveToLinkVerificationViewControllerDidFinish(
        _ viewController: NetworkingSaveToLinkVerificationViewController,
        error: Error?
    )
    func networkingSaveToLinkVerificationViewController(
        _ viewController: NetworkingSaveToLinkVerificationViewController,
        didReceiveTerminalError error: Error
    )
}

@available(iOSApplicationExtension, unavailable)
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
        let bodyView = NetworkingSaveToLinkVerificationBodyView(email: dataSource.consumerSession.emailAddress)
        bodyView.delegate = self
        return bodyView
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
                        pane: .networkingSaveToLinkVerification
                    )
                    self.delegate?.networkingSaveToLinkVerificationViewController(self, didReceiveTerminalError: error)
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
            footerView: NetworkingSaveToLinkFooterView(
                didSelectNotNow: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.networkingSaveToLinkVerificationViewControllerDidFinish(self, error: nil)
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

// MARK: - NetworkingSaveToLinkVerificationBodyViewDelegate

@available(iOSApplicationExtension, unavailable)
extension NetworkingSaveToLinkVerificationViewController: NetworkingSaveToLinkVerificationBodyViewDelegate {

    func networkingSaveToLinkVerificationBodyView(
        _ view: NetworkingSaveToLinkVerificationBodyView,
        didEnterValidOTPCode otpCode: String
    ) {
        view.otpTextField.text = "CONFIRMING OTP..."

        dataSource.confirmVerificationSession(otpCode: otpCode)
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    view.otpTextField.text = "SUCCESS! CALLING saveToLink AND markLinkVerified..."

                    self.dataSource.saveToLink()
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
                                self.delegate?.networkingSaveToLinkVerificationViewControllerDidFinish(self, error: nil)
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
                                self.delegate?.networkingSaveToLinkVerificationViewControllerDidFinish(self, error: error)
                            }
                        }

                    self.dataSource.markLinkVerified()
                        .observe { _ in
                            // we ignore result
                        }
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "ConfirmVerificationSessionError",
                            pane: .networkingSaveToLinkVerification
                        )
                    view.otpTextField.text = "FAILURE...\(error.localizedDescription)"
                    // TODO(kgaidis): display various known errors to OTP, or if unknown error, show terminal error
                }
            }
    }
}
