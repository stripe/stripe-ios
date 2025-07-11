//
//  LinkSignUpController.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 7/9/25.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

final class LinkSignUpController {
    enum SignUpResult {
        /// Sign up was completed successfully.
        case completed(PaymentSheetLinkAccount)
        /// Sign up was canceled by the user.
        case canceled
        /// Sign up failed due to an unrecoverable error.
        case failed(Error)
        /// Sign up encountered an attestation error and should bail to web flow.
        case attestationError
    }

    typealias CompletionBlock = (SignUpResult) -> Void

    private var completion: CompletionBlock?
    private var selfRetainer: LinkSignUpController?
    private let linkAccount: PaymentSheetLinkAccount?
    private let accountService: LinkAccountServiceProtocol
    private let country: String?
    private var bottomSheetViewController: BottomSheetViewController?
    private let configuration: PaymentElementConfiguration

    init(
        accountService: LinkAccountServiceProtocol,
        linkAccount: PaymentSheetLinkAccount?,
        country: String? = nil,
        configuration: PaymentElementConfiguration
    ) {
        self.accountService = accountService
        self.linkAccount = linkAccount
        self.country = country
        self.configuration = configuration
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping CompletionBlock
    ) {
        self.selfRetainer = self
        self.completion = completion

        guard let initialViewController = initialViewController() else {
            // If there is no initial view controller, the account is already verified.
            // `dismissAndComplete` with a `.completed` result has been called.
            return
        }

        let wrapperViewController = LinkSignUpBottomSheetContentWrapper(
            contentViewController: initialViewController,
            onDismiss: { [weak self] in
                self?.dismissAndComplete(with: .canceled)
            }
        )
        let bottomSheetViewController = BottomSheetViewController(
            contentViewController: wrapperViewController,
            appearance: .default,
            isTestMode: false,
            didCancelNative3DS2: { }
        )

        self.bottomSheetViewController = bottomSheetViewController
        presentingController.presentAsBottomSheet(bottomSheetViewController, appearance: .default)
    }

    private func initialViewController() -> UIViewController? {
        guard let linkAccount else {
            return createSignUpViewController()
        }

        switch linkAccount.sessionState {
        case .requiresSignUp:
            return createSignUpViewController()
        case .requiresVerification:
            return VerifyAccountViewController(
                linkAccount: linkAccount,
                completionHandler: { [weak self] result in
                    self?.dismissAndComplete(with: result)
                }
            )
        case .verified:
            // Complete the flow in this scenario.
            DispatchQueue.main.async { [weak self] in
                self?.dismissAndComplete(with: .completed(linkAccount))
            }

            return nil
        }
    }

    private func createSignUpViewController() -> LinkSignUpViewController {
        let signUpViewController = LinkSignUpViewController(
            accountService: accountService,
            linkAccount: linkAccount,
            country: country,
            defaultBillingDetails: configuration.defaultBillingDetails
        )
        signUpViewController.delegate = self
        configuration.style.configure(signUpViewController)
        return signUpViewController
    }

    private func dismissAndComplete(with result: SignUpResult) {
        if let bottomSheetViewController = self.bottomSheetViewController {
            bottomSheetViewController.dismiss(animated: true) { [weak self] in
                self?.completion?(result)
                self?.selfRetainer = nil
                self?.bottomSheetViewController = nil
            }
        } else {
            completion?(result)
            selfRetainer = nil
        }
    }

    private func pushVerificationController(with linkAccount: PaymentSheetLinkAccount) {
        let verificationViewController = VerifyAccountViewController(
            linkAccount: linkAccount,
            completionHandler: { [weak self] result in
                self?.dismissAndComplete(with: result)
            }
        )
        bottomSheetViewController?.pushContentViewController(verificationViewController)
    }
}

// MARK: - VerifyAccountViewController

extension LinkSignUpController {
    final class VerifyAccountViewController: UIViewController, BottomSheetContentViewController {

        private let linkAccount: PaymentSheetLinkAccount
        private let completionHandler: (LinkSignUpController.SignUpResult) -> Void

        lazy var navigationBar: SheetNavigationBar = {
            let navigationBar = LinkSheetNavigationBar(
                isTestMode: false,
                appearance: .init()
            )
            navigationBar.delegate = self
            return navigationBar
        }()

        var requiresFullScreen: Bool { true }

        private lazy var verificationVC: LinkVerificationViewController = {
            let vc = LinkVerificationViewController(mode: .embedded, linkAccount: linkAccount)
            vc.delegate = self
            vc.view.backgroundColor = .clear
            return vc
        }()

        init(linkAccount: PaymentSheetLinkAccount, completionHandler: @escaping (LinkSignUpController.SignUpResult) -> Void) {
            self.linkAccount = linkAccount
            self.completionHandler = completionHandler
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()

            addChild(verificationVC)
            view.addSubview(verificationVC.view)
            verificationVC.didMove(toParent: self)
            verificationVC.view.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                verificationVC.view.topAnchor.constraint(equalTo: view.topAnchor),
                verificationVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                verificationVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                verificationVC.view.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
                view.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),
            ])
        }

        func didTapOrSwipeToDismiss() {
            completionHandler(.canceled)
        }
    }
}

// MARK: - VerifyAccountViewController SheetNavigationBarDelegate

extension LinkSignUpController.VerifyAccountViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didTapOrSwipeToDismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        didTapOrSwipeToDismiss()
    }
}

// MARK: - VerifyAccountViewController LinkVerificationViewControllerDelegate

extension LinkSignUpController.VerifyAccountViewController: LinkVerificationViewControllerDelegate {
    func verificationController(
        _ controller: LinkVerificationViewController,
        didFinishWithResult result: LinkVerificationViewController.VerificationResult
    ) {
        switch result {
        case .completed:
            completionHandler(.completed(linkAccount))
        case .canceled:
            completionHandler(.canceled)
        case .failed(let error):
            completionHandler(.failed(error))
        }
    }
}

// MARK: - LinkSignUpController LinkSignUpViewControllerDelegate

extension LinkSignUpController: LinkSignUpViewControllerDelegate {
    func signUpController(
        _ controller: LinkSignUpViewController,
        didCompleteSignUpWith linkAccount: PaymentSheetLinkAccount
    ) {
        switch linkAccount.sessionState {
        case .requiresVerification:
            pushVerificationController(with: linkAccount)
        case .verified:
            dismissAndComplete(with: .completed(linkAccount))
        case .requiresSignUp:
            break
        }
    }

    func signUpController(
        _ controller: LinkSignUpViewController,
        didFailWithError error: Error
    ) {
        dismissAndComplete(with: .failed(error))
    }

    func signUpControllerDidCancel(_ controller: LinkSignUpViewController) {
        dismissAndComplete(with: .canceled)
    }

    func signUpControllerDidEncounterAttestationError(_ controller: LinkSignUpViewController) {
        dismissAndComplete(with: .attestationError)
    }
}
