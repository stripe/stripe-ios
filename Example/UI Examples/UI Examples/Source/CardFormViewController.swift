//
//  CardFormViewController.swift
//  UI Examples
//
//  Created by Cameron Sabol on 3/2/21.
//  Copyright © 2021 Stripe. All rights reserved.
//

import Stripe
@_spi(STP) import StripePaymentsUI
import UIKit

class CardFormViewController: UIViewController {
    var alwaysEnableCBC: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Card Form"
        view.backgroundColor = .systemBackground

        let cardForm = STPCardFormView(billingAddressCollection: .automatic, cbcEnabledOverride: alwaysEnableCBC ? true : nil)
        cardForm.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cardForm)

        NSLayoutConstraint.activate([
            cardForm.leadingAnchor.constraint(equalToSystemSpacingAfter: view.safeAreaLayoutGuide.leadingAnchor, multiplier: 4),
            view.safeAreaLayoutGuide.trailingAnchor.constraint(equalToSystemSpacingAfter: cardForm.trailingAnchor, multiplier: 4),
            cardForm.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            cardForm.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: view.safeAreaLayoutGuide.topAnchor, multiplier: 1),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: cardForm.bottomAnchor, multiplier: 1),
            cardForm.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done))
    }

    @objc func done() {
        dismiss(animated: true, completion: nil)
    }
}
