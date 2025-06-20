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
/// 
/// Enhanced LinkVerificationViewController with fixed header navigation.
/// 
/// Features:
/// - Fixed header that remains visible during navigation
/// - Dynamic back button that appears when content is pushed
/// - Smooth animations for logo repositioning
/// - Content area for pushable view controllers
/// - UINavigationController-style slide animations for push/pop transitions
/// 
/// Usage:
/// ```
/// // Push a new view controller (header stays fixed, back button appears)
/// // Animates with slide transition from right to left
/// verificationController.pushViewController(newVC, animated: true)
/// 
/// // Pop back to previous view  
/// // Animates with slide transition from left to right
/// verificationController.popViewController(animated: true)
/// 
/// // Pop to root verification view
/// // Animates current view sliding out to reveal root view
/// verificationController.popToRootViewController(animated: true)
/// ```
@objc(STP_Internal_LinkVerificationViewController)
final class LinkVerificationViewController: LinkNavigationController<LinkVerificationView.Header> {
    enum VerificationResult {
        /// Verification was completed successfully.
        case completed
        /// Verification was canceled by the user.
        case canceled
        /// Verification failed due to an unrecoverable error.
        case failed(Error)
    }

    weak var delegate: LinkVerificationViewControllerDelegate?

    let mode: LinkVerificationView.Mode
    let linkAccount: PaymentSheetLinkAccount

    private lazy var verificationView: LinkVerificationView = {
        guard linkAccount.redactedPhoneNumber != nil else {
            preconditionFailure("Verification(2FA) presented without a phone number on file")
        }

        let verificationView = LinkVerificationView(mode: mode, linkAccount: linkAccount)
        verificationView.delegate = self
        verificationView.backgroundColor = .clear
        verificationView.translatesAutoresizingMaskIntoConstraints = false

        return verificationView
    }()

    private lazy var activityIndicator: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        return activityIndicator
    }()

    required init(
        mode: LinkVerificationView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount
    ) {
        self.mode = mode
        self.linkAccount = linkAccount
        super.init(nibName: nil, bundle: nil)

        if mode.requiresModalPresentation {
            modalPresentationStyle = .custom
            transitioningDelegate = TransitioningDelegate.sharedDelegate
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - LinkNavigationController Overrides

    override var shouldShowHeader: Bool {
        return mode.requiresModalPresentation
    }

    override func createHeader() -> LinkVerificationView.Header {
        let header = LinkVerificationView.Header()
        header.closeButton.addTarget(self, action: #selector(headerCloseButtonTapped), for: .touchUpInside)
        header.backButton.addTarget(self, action: #selector(headerBackButtonTapped), for: .touchUpInside)
        return header
    }

    override func setupInitialContent() {
        contentContainer.addSubview(verificationView)
        contentContainer.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Verification view
            verificationView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            verificationView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            verificationView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            verificationView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            verificationView.widthAnchor.constraint(equalTo: contentContainer.widthAnchor),
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
        ])

        if mode.requiresModalPresentation {
            view.layer.masksToBounds = true
            view.layer.cornerRadius = LinkUI.largeCornerRadius
        }
    }

    override func setupInitialContentOffScreen() {
        contentContainer.addSubview(verificationView)
        contentContainer.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            // Verification view
            verificationView.topAnchor.constraint(equalTo: contentContainer.topAnchor),
            verificationView.bottomAnchor.constraint(equalTo: contentContainer.bottomAnchor),
            verificationView.leadingAnchor.constraint(equalTo: contentContainer.leadingAnchor),
            verificationView.trailingAnchor.constraint(equalTo: contentContainer.trailingAnchor),
            verificationView.widthAnchor.constraint(equalTo: contentContainer.widthAnchor),
            // Activity indicator
            activityIndicator.centerXAnchor.constraint(equalTo: contentContainer.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentContainer.centerYAnchor),
        ])

        // Position off-screen to the left
        verificationView.transform = CGAffineTransform(translationX: -contentContainer.bounds.width, y: 0)
        activityIndicator.transform = CGAffineTransform(translationX: -contentContainer.bounds.width, y: 0)
    }

    override func animateInitialContentOut() {
        verificationView.transform = CGAffineTransform(translationX: -contentContainer.bounds.width, y: 0)
        activityIndicator.transform = CGAffineTransform(translationX: -contentContainer.bounds.width, y: 0)
    }

    override func animateInitialContentIn() {
        verificationView.transform = .identity
        activityIndicator.transform = .identity
    }

    override func removeInitialContent() {
        verificationView.removeFromSuperview()
        activityIndicator.removeFromSuperview()
        verificationView.transform = .identity
        activityIndicator.transform = .identity
    }

    // MARK: - Header Actions

    @objc private func headerCloseButtonTapped() {
        linkAccount.markEmailAsLoggedOut()
        STPAnalyticsClient.sharedClient.logLink2FACancel()
        finish(withResult: .canceled)
    }

    @objc private func headerBackButtonTapped() {
        popViewController(animated: true)
    }

    @objc private func pushAnotherViewTapped() {
        let anotherVC = UIViewController()
        anotherVC.view.backgroundColor = .systemGreen

        let anotherLabel = UILabel()
        anotherLabel.text = "Another View"
        anotherLabel.textAlignment = .center
        anotherLabel.numberOfLines = 0
        anotherLabel.font = UIFont.systemFont(ofSize: 16)
        anotherLabel.translatesAutoresizingMaskIntoConstraints = false

        let popToRootButton = UIButton(type: .system)
        popToRootButton.setTitle("Pop to root", for: .normal)
        popToRootButton.backgroundColor = .systemBlue
        popToRootButton.setTitleColor(.white, for: .normal)
        popToRootButton.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 14.0, *) {
            popToRootButton.addAction(UIAction { [weak self] _ in
                self?.popToRootViewController(animated: true)
            }, for: .touchUpInside)
        } else {
            popToRootButton.addTarget(self, action: #selector(popToRootTapped), for: .touchUpInside)
        }

        let stackView = UIStackView(arrangedSubviews: [anotherLabel, popToRootButton])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        anotherVC.view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: anotherVC.view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: anotherVC.view.centerYAnchor),
        ])

        pushViewController(anotherVC, animated: true)
    }

    @objc private func popToRootTapped() {
        popToRootViewController(animated: true)
    }

    // MARK: - View Lifecycle

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if let presentationController = presentationController as? PresentationController {
            presentationController.updatePresentedViewFrame()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        activityIndicator.startAnimating()

        if linkAccount.sessionState == .requiresVerification {
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
        } else {
            verificationView.codeField.becomeFirstResponder()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logLink2FAStart()
    }

    // MARK: - Helper Methods

    private func finish(withResult result: VerificationResult) {
        // Delete the last "signup email" cookie, if any, after the user completes or declines verification.
        LinkAccountService.defaultCookieStore.delete(key: .lastSignupEmail)
        delegate?.verificationController(self, didFinishWithResult: result)
    }
}

// MARK: - LinkVerificationViewDelegate

/// :nodoc:
extension LinkVerificationViewController: LinkVerificationViewDelegate {

    func verificationViewDidCancel(_ view: LinkVerificationView) {
        // Mark email as logged out to prevent automatically showing
        // the 2FA modal in future checkout sessions.
        linkAccount.markEmailAsLoggedOut()

        STPAnalyticsClient.sharedClient.logLink2FACancel()
        finish(withResult: .canceled)
    }

    func verificationViewResendCode(_ view: LinkVerificationView) {
        view.sendingCode = true
        view.errorMessage = nil

        // To resend the code we just start a new verification session.
        linkAccount.startVerification { [weak self] (result) in
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
        finish(withResult: .canceled)
    }

    func verificationViewSendCodeToEmail(_ view: LinkVerificationView) {
        // Example: Push a new view controller while keeping the header fixed
        let emailVerificationVC = UIViewController()
        emailVerificationVC.view.backgroundColor = .systemBackground

        // Add some demo content
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        emailVerificationVC.view.addSubview(stackView)

        let label = UILabel()
        label.text = "Email verification view"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)

        let pushAnotherButton = UIButton(type: .system)
        pushAnotherButton.setTitle("Push Another View", for: .normal)
        pushAnotherButton.backgroundColor = .systemBlue
        pushAnotherButton.setTitleColor(.white, for: .normal)
        pushAnotherButton.layer.cornerRadius = 8
        pushAnotherButton.contentEdgeInsets = UIEdgeInsets(top: 12, left: 24, bottom: 12, right: 24)

        if #available(iOS 14.0, *) {
            pushAnotherButton.addAction(UIAction { [weak self] _ in
                self?.pushAnotherViewTapped()
            }, for: .touchUpInside)
        } else {
            // Fallback for iOS 13 and earlier
            pushAnotherButton.addTarget(self, action: #selector(pushAnotherViewTapped), for: .touchUpInside)
        }

        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(pushAnotherButton)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: emailVerificationVC.view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: emailVerificationVC.view.centerYAnchor),
            pushAnotherButton.widthAnchor.constraint(equalToConstant: 200),
        ])

        // Push the new view controller - header stays fixed and shows back button
        pushViewController(emailVerificationVC, animated: true)
    }

    func verificationView(_ view: LinkVerificationView, didEnterCode code: String) {
        view.codeField.resignFirstResponder()

        linkAccount.verify(with: code) { [weak self] result in
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
