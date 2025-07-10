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

    enum Style {
        /// (default)  Link sign up controller will automatically switch between light and dark mode compatible colors based on device settings.
        case automatic
        /// Link sign up controller will always use colors appropriate for light mode UI.
        case alwaysLight
        /// Link sign up controller will always use colors appropriate for dark mode UI.
        case alwaysDark
    }

    typealias CompletionBlock = (SignUpResult) -> Void

    private var completion: CompletionBlock?
    private var selfRetainer: LinkSignUpController?
    private let signUpViewController: LinkSignUpViewController
    private var bottomSheetViewController: BottomSheetViewController?

    init(
        accountService: LinkAccountServiceProtocol,
        linkAccount: PaymentSheetLinkAccount?,
        country: String?,
        defaultBillingDetails: PaymentSheet.BillingDetails = PaymentSheet.BillingDetails(),
        style: Style = .automatic
    ) {
        self.signUpViewController = LinkSignUpViewController(
            accountService: accountService,
            linkAccount: linkAccount,
            country: country,
            defaultBillingDetails: defaultBillingDetails
        )
        signUpViewController.delegate = self

        let paymentSheetStyle: PaymentSheet.UserInterfaceStyle
        switch style {
        case .automatic: paymentSheetStyle = .automatic
        case .alwaysLight: paymentSheetStyle = .alwaysLight
        case .alwaysDark: paymentSheetStyle = .alwaysDark
        }
        paymentSheetStyle.configure(signUpViewController)
    }

    func present(
        from presentingController: UIViewController,
        completion: @escaping CompletionBlock
    ) {
        self.selfRetainer = self
        self.completion = completion

        let wrapperViewController = LinkSignUpBottomSheetContentWrapper(contentViewController: signUpViewController)
        let bottomSheetViewController = BottomSheetViewController(
            contentViewController: wrapperViewController,
            appearance: .default,
            isTestMode: false,
            didCancelNative3DS2: { }
        )

        // Store reference for later dismissal
        self.bottomSheetViewController = bottomSheetViewController

        // Present as bottom sheet
        presentingController.presentAsBottomSheet(bottomSheetViewController, appearance: .default)
    }

    private func dismissAndComplete(with result: SignUpResult) {
        if let bottomSheetViewController = self.bottomSheetViewController {
            bottomSheetViewController.dismiss(animated: true) { [weak self] in
                self?.completion?(result)
                self?.selfRetainer = nil
                self?.bottomSheetViewController = nil
            }
        } else {
            // Fallback - should not happen in normal flow
            signUpViewController.dismiss(animated: true) { [weak self] in
                self?.completion?(result)
                self?.selfRetainer = nil
            }
        }
    }

}

// MARK: - BottomSheetContentWrapper

private final class LinkSignUpBottomSheetContentWrapper: UIViewController, BottomSheetContentViewController {

    private let contentViewController: LinkSignUpViewController

    lazy var navigationBar: SheetNavigationBar = {
        let navigationBar = LinkSheetNavigationBar(
            isTestMode: false,
            appearance: .init()
        )
        navigationBar.delegate = self
        return navigationBar
    }()

    var requiresFullScreen: Bool { true }

    init(contentViewController: LinkSignUpViewController) {
        self.contentViewController = contentViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(contentViewController)
        view.addSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)

        contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            contentViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func didTapOrSwipeToDismiss() {
        contentViewController.delegate?.signUpControllerDidCancel(contentViewController)
    }
}

extension LinkSignUpBottomSheetContentWrapper: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didTapOrSwipeToDismiss()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        didTapOrSwipeToDismiss()
    }
}

extension LinkSignUpController: LinkSignUpViewControllerDelegate {
    func signUpController(
        _ controller: LinkSignUpViewController,
        didCompleteSignUpWith linkAccount: PaymentSheetLinkAccount
    ) {
        dismissAndComplete(with: .completed(linkAccount))
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
