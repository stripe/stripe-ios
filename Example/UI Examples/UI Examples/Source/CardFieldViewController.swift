//
//  CardFieldViewController.swift
//  UI Examples
//
//  Created by Ben Guo on 7/19/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Stripe
@_spi(STP) import StripePaymentsUI
import UIKit

class CardFieldViewController: UIViewController {

    let cardField = STPPaymentCardTextField()

    var alwaysEnableCBC = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Card Field"
        view.backgroundColor = UIColor.white
        view.addSubview(cardField)
        edgesForExtendedLayout = []
        cardField.borderWidth = 1.0
        cardField.postalCodeEntryEnabled = true
        if alwaysEnableCBC {
            cardField.cbcEnabledOverride = true
        }
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done, target: self, action: #selector(done))
    }

    @objc func done() {
        dismiss(animated: true, completion: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cardField.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let padding: CGFloat = 15
        cardField.frame = CGRect(
            x: padding,
            y: padding,
            width: view.bounds.width - (padding * 2),
            height: 50)
    }

}
