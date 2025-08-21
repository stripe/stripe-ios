//
//  PayWithLinkViewController-LoaderViewController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeUICore

extension PayWithLinkViewController {

    /// A view controller that manages and displays a loading indicator
    final class LoaderViewController: BaseViewController {
        private let activityIndicator = ActivityIndicator(size: .large)

        override func viewDidLoad() {
            super.viewDidLoad()

            activityIndicator.tintColor = context.linkAppearance?.colors?.primary ?? .linkIconBrand
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false

            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(activityIndicator)

            contentView.addAndPinSubview(containerView, insets: .insets(bottom: LinkUI.bottomInset))

            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                containerView.heightAnchor.constraint(equalToConstant: LoadingViewController.Constants.defaultLoadingViewHeight - LinkUI.bottomInset),
            ])
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            activityIndicator.startAnimating()
        }
    }
}
