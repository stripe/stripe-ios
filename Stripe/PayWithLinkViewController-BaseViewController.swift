//
//  PayWithLinkViewController-BaseViewController.swift
//  StripeiOS
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    /// For internal SDK use only
    @objc(STP_Internal_PayWithLinkBaseViewController)
    class BaseViewController: UIViewController {
        weak var coordinator: PayWithLinkCoordinating?

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
            return navigationBar
        }()

        private(set) lazy var contentView = UIView()

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
                contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        @objc
        func onBackButtonTapped(_ sender: UIButton) {
            navigationController?.popViewController(animated: true)
        }

        @objc
        func onCloseButtonTapped(_ sender: UIButton) {
            coordinator?.cancel(logout: false)
        }

    }

}
