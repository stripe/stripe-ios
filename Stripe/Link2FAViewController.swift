//
//  Link2FAViewController.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 3/24/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_Link2FAViewController)
final class Link2FAViewController: UIViewController {
    enum CompletionStatus {
        case canceled
        case completed
    }

    let mode: Link2FAView.Mode
    let linkAccount: PaymentSheetLinkAccount
    let completionBlock: ((CompletionStatus)->Void)

    private lazy var twoFAView : Link2FAView = {
        guard linkAccount.redactedPhoneNumber != nil else {
            preconditionFailure("2FA presented without a phone number on file")
        }

        let twoFAView = Link2FAView(mode: mode, linkAccount: linkAccount)
        twoFAView.delegate = self
        twoFAView.backgroundColor = .clear
        twoFAView.translatesAutoresizingMaskIntoConstraints = false

        return twoFAView
    }()

    private lazy var scrollView = LinkKeyboardAvoidingScrollView()

    required init(
        mode: Link2FAView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount,
        completionBlock: @escaping ((CompletionStatus)->Void)
    ) {
        self.mode = mode
        self.linkAccount = linkAccount
        self.completionBlock = completionBlock
        super.init(nibName: nil, bundle: nil)

        if mode.requiresModalPresentation {
            modalPresentationStyle = .custom
            transitioningDelegate = TransitioningDelegate.sharedDelegate
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = scrollView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.tintColor = .linkBrand
        view.backgroundColor = CompatibleColor.systemBackground

        view.addSubview(twoFAView)

        NSLayoutConstraint.activate([
            twoFAView.topAnchor.constraint(equalTo: view.topAnchor),
            twoFAView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            twoFAView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            twoFAView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            twoFAView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])

        if mode.requiresModalPresentation {
            view.layer.masksToBounds = true
            view.layer.cornerRadius = LinkUI.cornerRadius
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = twoFAView.codeField.becomeFirstResponder()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        STPAnalyticsClient.sharedClient.logLink2FAStart()
    }

}

/// :nodoc:
extension Link2FAViewController: Link2FAViewDelegate {

    func link2FAViewDidCancel(_ view: Link2FAView) {
        // Mark email as logged out to prevent automatically showing
        // the 2FA modal in future checkout sessions.
        linkAccount.markEmailAsLoggedOut()

        STPAnalyticsClient.sharedClient.logLink2FACancel()
        completionBlock(.canceled)
    }

    func link2FAViewResendCode(_ view: Link2FAView) {
        view.sendingCode = true

        // To resend the code we just start a new verification session.
        linkAccount.startVerification { [weak self] (result) in
            view.sendingCode = false

            switch result {
            case .success(_):
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

    func link2FAViewLogout(_ view: Link2FAView) {
        STPAnalyticsClient.sharedClient.logLink2FACancel()
        completionBlock(.canceled)
    }

    func link2FAView(_ view: Link2FAView, didEnterCode code: String) {
        view.codeField.resignFirstResponder()

        linkAccount.verify(with: code) { [weak self] result in
            switch result {
            case .success:
                self?.completionBlock(.completed)
                STPAnalyticsClient.sharedClient.logLink2FAComplete()
            case .failure(_):
                view.codeField.performInvalidCodeAnimation()
                STPAnalyticsClient.sharedClient.logLink2FAFailure()
            }
        }
    }

}

// MARK: - Transitioning Delegate

extension Link2FAViewController {

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
