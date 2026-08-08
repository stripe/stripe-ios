//
//  PhoneOtpViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 6/14/23.
//

@_spi(STP) import StripeUICore
import UIKit

class PhoneOtpViewController: IdentityFlowViewController {
    private let phoneOtpContent: StripeAPI.VerificationPageStaticContentPhoneOtpPage

    let phoneOtpView: PhoneOtpView

    var flowViewModel: IdentityFlowView.ViewModel {
        return .init(
            headerViewModel: .init(
                backgroundColor: .systemBackground,
                headerType: .plain,
                titleText: phoneOtpContent.title
            ),
            contentView: phoneOtpView,
            buttons: [
                .init(
                    text: phoneOtpContent.resendButtonText,
                    state: {
                        switch phoneOtpView.viewModel {
                        case .InputtingOTP:
                            return .enabled
                        case .SubmittingOTP:
                            return .disabled
                        case .ErrorOTP:
                            return .enabled
                        case .RequestingOTP:
                            return .loading
                        case .RequestingCannotVerify:
                            return .disabled
                        case .none:
                            return .disabled
                        }
                    }(),
                    isPrimary: false,
                    didTap: { [weak self] in
                        self?.generateOtp()
                    }
                ),
                .init(
                    text: phoneOtpContent.cannotVerifyButtonText,
                    state: {
                        switch phoneOtpView.viewModel {
                        case .InputtingOTP:
                            return .enabled
                        case .SubmittingOTP:
                            return .disabled
                        case .ErrorOTP:
                            return .enabled
                        case .RequestingOTP:
                            return .disabled
                        case .RequestingCannotVerify:
                            return .loading
                        case .none:
                            return .disabled
                        }
                    }(),
                    isPrimary: false,
                    didTap: { [weak self] in
                        guard let self else { return }
                        self.phoneOtpView.configure(with: .RequestingCannotVerify)
                        Task {
                            await self.sheetController?.sendCannotVerifyPhoneOtpAndTransition()
                            self.phoneOtpView.reset()
                        }
                    }
                ),
            ]
        )
    }

    init(
        phoneOtpContent: StripeAPI.VerificationPageStaticContentPhoneOtpPage,
        sheetController: VerificationSheetControllerProtocol
    ) {
        self.phoneOtpContent = phoneOtpContent

        let bodyText = {
            if let localPhoneNumber = sheetController.collectedData.phone {
                // If phone number is collected locally use the non-nil number
                return phoneOtpContent.body.replacingOccurrences(of: "{phone_number}", with: localPhoneNumber.phoneNumber?.suffix(4) ?? "")
            } else {
                // Otherwise use the server provided non-nil number
                return phoneOtpContent.body.replacingOccurrences(of: "{phone_number}", with: phoneOtpContent.redactedPhoneNumber ?? "")
            }
        }()

        phoneOtpView = PhoneOtpView(otpLength: phoneOtpContent.otpLength,
                                    body: bodyText, errorString: phoneOtpContent.errorOtpMessage)

        super.init(sheetController: sheetController, analyticsScreenName: .phoneOtp)

        phoneOtpView.delegate = self

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        generateOtp()
    }

    func updateUI() {
        configure(
            backButtonTitle: STPLocalizedString(
                "Phone Verification",
                "Back button title for returning to the phone verification page"
            ),
            viewModel: flowViewModel
        )
    }
}

extension PhoneOtpViewController: PhoneOtpViewDelegate {
    func didInputFullOtp(newOtp: String) {
        phoneOtpView.configure(with: .SubmittingOTP(newOtp))

        Task { [weak self] in
            guard let sheetController = self?.sheetController else {
                return
            }

            let result = await sheetController.saveOtpAndMaybeTransition(
                from: .phoneOtp,
                otp: newOtp
            )

            guard let self else {
                return
            }

            switch result {
            case .invalidOtp:
                phoneOtpView.configure(with: .ErrorOTP)
            case .transitioned:
                phoneOtpView.reset()
            }
        }
    }

    func viewStateDidUpdate() {
        updateUI()
    }
}

extension PhoneOtpViewController {
    /// Generate OTP, when sucess, trnasition to InputtingOTP
    func generateOtp() {
        phoneOtpView.configure(with: .RequestingOTP)
        Task {
            guard await sheetController?.generatePhoneOtp() != nil else {
                return
            }
            phoneOtpView.configure(with: .InputtingOTP)
        }
    }
}

// MARK: - IdentityDataCollecting
extension PhoneOtpViewController: IdentityDataCollecting {
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return [.phoneOtp]
    }
}
