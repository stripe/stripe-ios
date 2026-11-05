//
//  PhoneOtpView.swift
//  StripeIdentity
//
//  Created by Chen Cen on 6/14/23.
//
@_spi(STP) import StripeUICore
import UIKit

protocol PhoneOtpViewDelegate: AnyObject {
    func didInputFullOtp(newOtp: String)

    func viewStateDidUpdate()
}

class PhoneOtpView: UIView {

    enum ViewModel: Equatable {
        case InputtingOTP // When user is inputting OTP
        case SubmittingOTP(String) // When OTP is being submitted through Post VerificationPageData
        case ErrorOTP // When wrong OTP is submitted
        case RequestingOTP // When GenerateOTP is outstanding
        case RequestingCannotVerify // When CannotVerify is outstanding
    }

    weak var delegate: PhoneOtpViewDelegate?

    private let otpTextField: OneTimeCodeTextField
    private let otpBodyLabel = {
        let label = UILabel()
        label.font = IdentityUI.instructionsFont
        label.numberOfLines = 0
        return label
    }()
    private let otpErrorLabel = {
        let label = UILabel()
        label.font = IdentityUI.instructionsFont
        label.textColor = IdentityUI.identityElementsUITheme.colors.danger
        label.numberOfLines = 1
        return label
    }()

    private let otpErrorField = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.spacing = 8
        return stackView
    }()

    private let submittingIndicator = ActivityIndicator()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 16
        return stackView
    }()

    var viewModel: ViewModel?

    init(
        otpLength: Int,
        body: String,
        errorString: String
    ) {
        otpTextField = OneTimeCodeTextField(
            configuration: OneTimeCodeTextField.Configuration(
                numberOfDigits: otpLength
            ),
            theme: IdentityUI.identityElementsUITheme
        )
        otpBodyLabel.text = body
        otpErrorLabel.text = errorString

        super.init(frame: .zero)
        otpTextField.addTarget(self, action: #selector(otpTextFieldDidChange), for: .valueChanged)

        let warningIconView = UIImageView()
        warningIconView.contentMode = .scaleToFill
        warningIconView.image = Image.iconWarning2.makeImage().withTintColor(.systemRed)

        otpErrorField.addArrangedSubview(warningIconView)
        otpErrorField.addArrangedSubview(otpErrorLabel)
        stackView.addArrangedSubview(otpBodyLabel)
        stackView.addArrangedSubview(otpTextField)
        stackView.addArrangedSubview(otpErrorField)
        stackView.addArrangedSubview(submittingIndicator)

        NSLayoutConstraint.activate([
            warningIconView.widthAnchor.constraint(equalToConstant: 16),
            warningIconView.heightAnchor.constraint(equalToConstant: 16),
            otpTextField.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            otpTextField.trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
        ])

        addAndPinSubview(stackView)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewModel: ViewModel? = nil) {
        self.viewModel = viewModel
        switch viewModel {
        case .InputtingOTP:
            otpTextField.isEnabled = true
            otpTextField.becomeFirstResponder()
            otpErrorField.isHidden = true
            submittingIndicator.isHidden = true
            submittingIndicator.stopAnimating()
        case .SubmittingOTP:
            otpTextField.isEnabled = false
            otpErrorField.isHidden = true
            submittingIndicator.isHidden = false
            submittingIndicator.startAnimating()
        case .ErrorOTP:
            otpTextField.performInvalidCodeAnimation()
            otpTextField.resignFirstResponder()
            otpTextField.isEnabled = true
            otpErrorField.isHidden = false
            submittingIndicator.isHidden = true
            submittingIndicator.stopAnimating()
        case .RequestingOTP:
            otpTextField.isEnabled = false
            otpErrorField.isHidden = true
            submittingIndicator.isHidden = true
            submittingIndicator.stopAnimating()
        case .RequestingCannotVerify:
            otpTextField.isEnabled = false
            otpErrorField.isHidden = true
            submittingIndicator.isHidden = true
            submittingIndicator.stopAnimating()
        case .none:
            otpTextField.isEnabled = false
            otpErrorField.isHidden = true
            submittingIndicator.isHidden = true
        }
        delegate?.viewStateDidUpdate()
    }

    @objc private func otpTextFieldDidChange() {
        if self.viewModel == .ErrorOTP {
            self.configure(with: .InputtingOTP)
        }
        if otpTextField.isComplete {
            otpTextField.isEnabled = false
            otpTextField.resignFirstResponder()
            self.delegate?.didInputFullOtp(newOtp: otpTextField.value)
        }
    }

}

extension PhoneOtpView {
    fileprivate func installViews() {
        stackView.addArrangedSubview(otpTextField)
        addAndPinSubview(stackView)
    }

    func reset() {
        configure(with: .InputtingOTP)
        otpTextField.value = ""
    }
}
