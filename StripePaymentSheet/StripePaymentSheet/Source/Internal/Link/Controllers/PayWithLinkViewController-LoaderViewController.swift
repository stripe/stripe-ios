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
            view.addSubview(activityIndicator)

            NSLayoutConstraint.activate([
                activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            activityIndicator.startAnimating()
        }

    }

}
