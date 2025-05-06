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
            activityIndicator.translatesAutoresizingMaskIntoConstraints = false

            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(activityIndicator)
            view.addSubview(containerView)

            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                containerView.heightAnchor.constraint(equalToConstant: 80),
            ])
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            activityIndicator.startAnimating()
        }

    }

}
