//
//  LinkVerificationViewController.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 3/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol LinkVerificationViewControllerDelegate: AnyObject {
    func verificationController(
        _ controller: LinkVerificationViewController,
        didFinishWithResult result: LinkVerificationViewController.VerificationResult
    )
}

/// For internal SDK use only
@objc(STP_Internal_LinkVerificationViewController)
final class LinkVerificationViewController: UIViewController {
    enum VerificationResult {
        /// Verification was completed successfully.
        case completed
        /// Verification was canceled by the user.
        case canceled
        /// The user requested to switch to a different account.
        case switchAccount
        /// Verification failed due to an unrecoverable error.
        case failed(Error)
    }

    weak var delegate: LinkVerificationViewControllerDelegate?

    let mode: LinkVerificationView.Mode
    let linkAccount: PaymentSheetLinkAccount

    private let appearance: LinkAppearance?
    private let allowLogoutInDialog: Bool
    private let consentViewModel: LinkConsentViewModel?

    private lazy var verificationView: LinkVerificationView = {
        guard linkAccount.redactedPhoneNumber != nil else {
            preconditionFailure("Verification(2FA) presented without a phone number on file")
        }

        let verificationView = LinkVerificationView(
            mode: mode,
            linkAccount: linkAccount,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog,
            consentViewModel: consentViewModel
        )
        verificationView.delegate = self
        verificationView.backgroundColor = .clear
        verificationView.translatesAutoresizingMaskIntoConstraints = false

        return verificationView
    }()

    private lazy var activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        if let appearancePrimaryColor = appearance?.colors?.primary {
            activityIndicator.tintColor = appearancePrimaryColor
        }

        return activityIndicator
    }()

    required init(
        mode: LinkVerificationView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool = false,
        consentViewModel: LinkConsentViewModel? = nil
    ) {
        self.mode = mode
        self.linkAccount = linkAccount
        self.appearance = appearance
        self.allowLogoutInDialog = allowLogoutInDialog
        self.consentViewModel = consentViewModel
        super.init(nibName: nil, bundle: nil)

        if mode.requiresModalPresentation {
            modalPresentationStyle = .custom
            transitioningDelegate = TransitioningDelegate.sharedDelegate
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = .linkIconBrand
        view.backgroundColor = .systemBackground

        view.addSubview(verificationView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Verification view
            verificationView.topAnchor.constraint(equalTo: view.topAnchor),
            verificationView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            verificationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            verificationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            verificationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        if mode.requiresModalPresentation {
            view.layer.masksToBounds = true
            view.layer.cornerRadius = LinkUI.largeCornerRadius
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let presentationController = presentationController as? PresentationController {
            presentationController.updatePresentedViewFrame()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicator.startAnimating()

        verificationView.isHidden = true

        linkAccount.startVerification { [weak self] result in
            switch result {
            case .success(let collectOTP):
                if collectOTP {
                    self?.activityIndicator.stopAnimating()
                    self?.verificationView.isHidden = false
                    self?.verificationView.codeField.becomeFirstResponder()
                } else {
                    // No OTP collection is required.
                    self?.finish(withResult: .completed)
                }
            case .failure(let error):
                STPAnalyticsClient.sharedClient.logLink2FAStartFailure()
                self?.finish(withResult: .failed(error))
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logLink2FAStart()
    }

}

/// :nodoc:
extension LinkVerificationViewController: LinkVerificationViewDelegate {

    func verificationViewDidCancel(_ view: LinkVerificationView) {
        STPAnalyticsClient.sharedClient.logLink2FACancel()
        finish(withResult: .canceled)
    }

    func verificationViewResendCode(_ view: LinkVerificationView) {
        STPAnalyticsClient.sharedClient.logLink2FAResendCode()

        view.sendingCode = true
        view.errorMessage = nil

        // To resend the code we just start a new verification session.
        linkAccount.startVerification(isResendingSmsCode: true) { [weak self] (result) in
            view.sendingCode = false

            switch result {
            case .success:
                let toast = LinkToast(
                    type: .success,
                    text: STPLocalizedString(
                        "Code sent",
                        "Text of a notification shown to the user when a login code is successfully sent via SMS."
                    )
                )
                toast.show(from: view)
            case .failure(let error):
                let alertController = UIAlertController(
                    title: nil,
                    message: error.localizedDescription,
                    preferredStyle: .alert
                )

                alertController.addAction(UIAlertAction(
                    title: String.Localized.ok,
                    style: .default
                ))

                self?.present(alertController, animated: true)
            }
        }
    }

    func verificationViewLogout(_ view: LinkVerificationView) {
        STPAnalyticsClient.sharedClient.logLink2FACancel()
        finish(withResult: .switchAccount)
    }

    func verificationView(_ view: LinkVerificationView, didEnterCode code: String) {
        view.codeField.resignFirstResponder()

        // Check if inline consent was shown
        let consentGranted: Bool?
        if case .inline = consentViewModel {
            consentGranted = true
        } else {
            consentGranted = nil
        }

        linkAccount.verify(with: code, consentGranted: consentGranted) { [weak self] result in
            switch result {
            case .success:
                self?.finish(withResult: .completed)
                STPAnalyticsClient.sharedClient.logLink2FAComplete()
            case .failure(let error):
                view.codeField.performInvalidCodeAnimation()
                view.errorMessage = LinkUtils.getLocalizedErrorMessage(from: error)
                STPAnalyticsClient.sharedClient.logLink2FAFailure()
            }
        }
    }

}

extension LinkVerificationViewController {

    private func finish(withResult result: VerificationResult) {
        delegate?.verificationController(self, didFinishWithResult: result)
    }

}

// MARK: - Transitioning Delegate

extension LinkVerificationViewController {

    final class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
        static let sharedDelegate: TransitioningDelegate = TransitioningDelegate()

        func presentationController(forPresented presented: UIViewController,
                                    presenting: UIViewController?,
                                    source: UIViewController) -> UIPresentationController? {
            return PresentationController(presentedViewController: presented,
                                          presenting: presenting)
        }
    }

}
