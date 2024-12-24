//
//  PayWithLinkViewController-BaseViewController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_PayWithLinkBaseViewController)
    class BaseViewController: UIViewController {
        weak var coordinator: PayWithLinkCoordinating?

        let context: Context

        var preferredContentMargins: NSDirectionalEdgeInsets {
            return customNavigationBar.isLarge
                ? LinkUI.contentMarginsWithLargeNav
                : LinkUI.contentMargins
        }

        private(set) lazy var customNavigationBar: LinkNavigationBar = {
            let navigationBar = LinkNavigationBar()
            navigationBar.backButton.addTarget(
                self,
                action: #selector(onBackButtonTapped(_:)),
                for: .touchUpInside
            )
            navigationBar.closeButton.addTarget(
                self,
                action: #selector(onCloseButtonTapped(_:)),
                for: .touchUpInside
            )
            navigationBar.menuButton.addTarget(
                self,
                action: #selector(onMenuButtonTapped(_:)),
                for: .touchUpInside
            )
            return navigationBar
        }()

        private(set) lazy var contentView = UIView()

        init(context: Context) {
            self.context = context
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .linkBackground

            customNavigationBar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(customNavigationBar)

            contentView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(contentView)

            NSLayoutConstraint.activate([
                // Navigation bar
                customNavigationBar.topAnchor.constraint(equalTo: view.topAnchor),
                customNavigationBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                customNavigationBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                // Content view
                contentView.topAnchor.constraint(equalTo: customNavigationBar.bottomAnchor),
                contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        override func present(
            _ viewControllerToPresent: UIViewController,
            animated flag: Bool,
            completion: (() -> Void)? = nil
        ) {
            // Any view controller presented by this controller should also be customized.
            context.configuration.style.configure(viewControllerToPresent)
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }

        @objc
        func onBackButtonTapped(_ sender: UIButton) {
            navigationController?.popViewController(animated: true)
        }

        @objc
        func onCloseButtonTapped(_ sender: UIButton) {
            if context.shouldFinishOnClose {
                coordinator?.finish(withResult: .canceled, deferredIntentConfirmationType: nil)
            } else {
                coordinator?.cancel()
            }
        }

        @objc
        func onMenuButtonTapped(_ sender: UIButton) {
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(
                title: STPLocalizedString("Log out of Link", "Title of the logout action."),
                style: .destructive,
                handler: { [weak self] _ in
                    self?.coordinator?.logout(cancel: true)
                }
            ))
            actionSheet.addAction(UIAlertAction(title: String.Localized.cancel, style: .cancel))

            // iPad support
            actionSheet.popoverPresentationController?.sourceView = sender
            actionSheet.popoverPresentationController?.sourceRect = sender.bounds

            present(actionSheet, animated: true)
        }
    }

}
