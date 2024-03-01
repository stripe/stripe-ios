//
//  NetworkingOTPView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/28/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol NetworkingOTPViewDelegate: AnyObject {
    func networkingOTPViewWillStartConsumerLookup(_ view: NetworkingOTPView)
    func networkingOTPViewConsumerNotFound(_ view: NetworkingOTPView)
    func networkingOTPView(_ view: NetworkingOTPView, didFailConsumerLookup error: Error)

    func networkingOTPViewWillStartVerification(_ view: NetworkingOTPView)
    func networkingOTPView(_ view: NetworkingOTPView, didStartVerification consumerSession: ConsumerSessionData)
    func networkingOTPView(_ view: NetworkingOTPView, didFailToStartVerification error: Error)

    func networkingOTPViewWillConfirmVerification(_ view: NetworkingOTPView)
    func networkingOTPViewDidConfirmVerification(_ view: NetworkingOTPView)
    func networkingOTPView(
        _ view: NetworkingOTPView,
        didFailToConfirmVerification error: Error,
        isTerminal: Bool
    )
}

final class NetworkingOTPView: UIView {

    private let dataSource: NetworkingOTPDataSource
    weak var delegate: NetworkingOTPViewDelegate?

    private lazy var verticalStackView: UIStackView = {
        let otpVerticalStackView = UIStackView(
            arrangedSubviews: [
                otpTextField,
            ]
        )
        otpVerticalStackView.axis = .vertical
        otpVerticalStackView.spacing = 16
        return otpVerticalStackView
    }()
    private(set) lazy var otpTextField: OneTimeCodeTextField = {
        let otpTextField = OneTimeCodeTextField(
            configuration: OneTimeCodeTextField.Configuration(
                itemSpacing: 8,
                enableDigitGrouping: false,
                font: UIFont.systemFont(ofSize: 28, weight: .regular),
                itemCornerRadius: 12,
                itemHeight: 58
            ),
            theme: theme
        )
        otpTextField.tintColor = .textBrand
        otpTextField.addTarget(self, action: #selector(otpTextFieldDidChange), for: .valueChanged)
        otpTextField.tintColor = .textActionPrimaryFocused
        return otpTextField
    }()
    private lazy var theme: ElementsUITheme = {
        var theme: ElementsUITheme = .default
        theme.colors = {
            var colors = ElementsUITheme.Color()
            colors.border = .borderDefault
            colors.background = .customBackgroundColor
            colors.textFieldText = .textDefault
            colors.danger = .textFeedbackCritical
            return colors
        }()
        return theme
    }()
    private var lastFooterView: UIView?

    init(dataSource: NetworkingOTPDataSource) {
        self.dataSource = dataSource
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func otpTextFieldDidChange() {
        showErrorText(nil) // clear the error

        if otpTextField.isComplete {
            userDidEnterValidOTPCode(otpTextField.value)
        }
    }

    func showLoadingView(_ show: Bool) {
        lastFooterView?.removeFromSuperview()
        lastFooterView = nil

        if show {
            let activityIndicator = ActivityIndicator(size: .medium)
            activityIndicator.color = .iconActionPrimary
            activityIndicator.startAnimating()
            let loadingView = UIStackView(
                arrangedSubviews: [activityIndicator]
            )
            loadingView.isLayoutMarginsRelativeArrangement = true
            loadingView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 8,
                leading: 0,
                bottom: 8,
                trailing: 0
            )
            self.lastFooterView = loadingView
            verticalStackView.addArrangedSubview(loadingView)
        }
    }

    private func showErrorText(_ errorText: String?) {
        lastFooterView?.removeFromSuperview()
        lastFooterView = nil

        if let errorText = errorText {
            let errorLabel = AttributedTextView(
                font: .label(.medium),
                boldFont: .label(.mediumEmphasized),
                linkFont: .label(.medium),
                textColor: .textFeedbackCritical,
                linkColor: .textFeedbackCritical,
                alignCenter: true
            )
            errorLabel.setText(errorText)
            let errorView = UIStackView(
                arrangedSubviews: [errorLabel]
            )
            errorView.isLayoutMarginsRelativeArrangement = true
            errorView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 8,
                leading: 0,
                bottom: 0,
                trailing: 0
            )
            self.lastFooterView = errorView
            verticalStackView.addArrangedSubview(errorView)
        }
    }

    func lookupConsumerAndStartVerification() {
        delegate?.networkingOTPViewWillStartConsumerLookup(self)
        dataSource.lookupConsumerSession()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let lookupConsumerSessionResponse):
                    if lookupConsumerSessionResponse.exists {
                        self.startVerification()
                    } else {
                        self.delegate?.networkingOTPViewConsumerNotFound(self)
                    }
                case .failure(let error):
                    self.delegate?.networkingOTPView(self, didFailConsumerLookup: error)
                }
            }
    }

    func startVerification() {
        delegate?.networkingOTPViewWillStartVerification(self)
        dataSource.startVerificationSession()
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let consumerSessionResponse):
                    self.delegate?.networkingOTPView(self, didStartVerification: consumerSessionResponse.consumerSession)

                    // call this AFTER the delegate to ensure that the delegate-handler
                    // adds the OTP view to the view-hierarchy
                    self.otpTextField.becomeFirstResponder()
                case .failure(let error):
                    self.delegate?.networkingOTPView(self, didFailToStartVerification: error)
                }
            }
    }

    private func userDidEnterValidOTPCode(_ otpCode: String) {
        otpTextField.resignFirstResponder()
        showLoadingView(true)
        delegate?.networkingOTPViewWillConfirmVerification(self)

        dataSource.confirmVerificationSession(otpCode: otpCode)
            .observe { [weak self] result in
                guard let self = self else { return }
                self.showLoadingView(false)

                switch result {
                case .success:
                    self.delegate?.networkingOTPViewDidConfirmVerification(self)
                case .failure(let error):
                    let isTerminal: Bool
                    if let errorMessage = AuthFlowHelpers.networkingOTPErrorMessage(fromError: error, otpType: self.dataSource.otpType) {
                        self.dataSource
                            .analyticsClient
                            .logExpectedError(
                                error,
                                errorName: "ConfirmVerificationSessionError",
                                pane: self.dataSource.pane
                            )

                        self.otpTextField.performInvalidCodeAnimation(shouldClearValue: false)
                        self.showErrorText(errorMessage)
                        isTerminal = false
                    } else {
                        self.dataSource
                            .analyticsClient
                            .logUnexpectedError(
                                error,
                                errorName: "ConfirmVerificationSessionError",
                                pane: self.dataSource.pane
                            )
                        isTerminal = true
                    }
                    self.delegate?.networkingOTPView(
                        self,
                        didFailToConfirmVerification: error,
                        isTerminal: isTerminal
                    )
                }
            }
    }
}
