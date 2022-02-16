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

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .linkBackground
        }

        override func willMove(toParent parent: UIViewController?) {
            super.willMove(toParent: parent)

            navigationItem.titleView = UIImageView(image: Image.link_logo.makeImage(template: true))
            navigationItem.titleView?.tintColor = .linkNavLogo
            navigationItem.titleView?.accessibilityLabel = "Link" // TODO(ramont): Localize

            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: Image.icon_cancel.makeImage(),
                style: .plain,
                target: self,
                action: #selector(closeButtonTapped(_:))
            )
            navigationItem.rightBarButtonItem?.accessibilityLabel = String.Localized.close

            if #available(iOS 14.0, *) {
                navigationItem.backButtonDisplayMode = .minimal
            } else {
                navigationItem.backButtonTitle = ""
            }
        }

        @objc
        func closeButtonTapped(_ sender: UIBarButtonItem) {
            coordinator?.cancel()
        }

    }

}
