//
//  CardFormScannerViewController.swift
//  UI Examples
//
//  Copyright © 2024 Stripe. All rights reserved.
//

import Stripe
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class CardFormScannerViewController: UIViewController {
    var alwaysEnableCBC: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Card Form Scanner"
        view.backgroundColor = .systemBackground

        let handler: (Error?) -> () = { [weak self] error in
            guard let error else { return }
            let alertController = UIAlertController(
                title: error.localizedDescription,
                message: (error as NSError).localizedFailureReason,
                preferredStyle: .alert
            )
            alertController.addAction(
                UIAlertAction(
                    title: String.Localized.ok,
                    style: .cancel,
                    handler: nil
                )
            )
            self?.present(alertController, animated: true)
        }

        let cardForm = STPCardFormScannerView(style: .standard, handleError: handler)
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
