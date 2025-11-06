//
//  PayWithLinkViewController-BaseViewController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_PayWithLinkBaseViewController)
    class BaseViewController: UIViewController, BottomSheetContentViewController {
        weak var coordinator: PayWithLinkCoordinating?

        let context: Context
        let navigationTitle: String?

        var preferredContentMargins: NSDirectionalEdgeInsets {
            LinkUI.contentMargins
        }

        private(set) lazy var contentView = UIView()

        init(context: Context, navigationTitle: String? = nil) {
            self.context = context
            self.navigationTitle = navigationTitle
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .linkSurfacePrimary

            contentView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(contentView)

            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: view.topAnchor),
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

        var requiresFullScreen: Bool { false }

        lazy var navigationBar: SheetNavigationBar = {
            let navBar = LinkSheetNavigationBar(
                isTestMode: false,
                appearance: LinkUI.appearance,
                shouldLogPaymentSheetAnalyticsOnDismissal: false
            )
            navBar.title = navigationTitle
            return navBar
        }()

        func didTapOrSwipeToDismiss() {
            guard context.isDismissible else { return }
            if context.shouldFinishOnClose {
                coordinator?.finish(withResult: .canceled, deferredIntentConfirmationType: nil)
            } else {
                coordinator?.cancel(shouldReturnToPaymentSheet: false)
            }
        }
    }
}
