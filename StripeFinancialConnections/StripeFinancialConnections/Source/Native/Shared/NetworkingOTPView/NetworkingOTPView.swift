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

    func networkingOTPViewDidConfirmVerification(_ view: NetworkingOTPView)
    func networkingOTPView(_ view: NetworkingOTPView, didTerminallyFailToConfirmVerification error: Error)
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
        otpVerticalStackView.spacing = 8
        return otpVerticalStackView
    }()
    // TODO(kgaidis): make changes to `OneTimeCodeTextField` to
    // make the font larger
    private(set) lazy var otpTextField: OneTimeCodeTextField = {
        let otpTextField = OneTimeCodeTextField(theme: theme)
        otpTextField.tintColor = .textBrand
        otpTextField.addTarget(self, action: #selector(otpTextFieldDidChange), for: .valueChanged)
        return otpTextField
    }()
    private lazy var theme: ElementsUITheme = {
        var theme: ElementsUITheme = .default
        theme.colors = {
            var colors = ElementsUITheme.Color()
            colors.border = .borderNeutral
            colors.background = .customBackgroundColor
            colors.textFieldText = .textPrimary
            return colors
        }()
        return theme
    }()
    private var lastErrorView: UIView?

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

    private func showErrorText(_ errorText: String?) {
        lastErrorView?.removeFromSuperview()
        lastErrorView = nil

        if let errorText = errorText {
            // TODO(kgaidis): rename & move `ManualEntryErrorView` to be more generic
            let errorView = ManualEntryErrorView(text: errorText)
            self.lastErrorView = errorView
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

        dataSource.confirmVerificationSession(otpCode: otpCode)
            .observe { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.delegate?.networkingOTPViewDidConfirmVerification(self)
                case .failure(let error):
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
                    } else {
                        self.dataSource
                            .analyticsClient
                            .logUnexpectedError(
                                error,
                                errorName: "ConfirmVerificationSessionError",
                                pane: self.dataSource.pane
                            )
                        self.delegate?.networkingOTPView(self, didTerminallyFailToConfirmVerification: error)
                    }
                }
            }
    }
}
