//
//  CardFieldViewController.swift
//  UI Examples
//
//  Created by Ben Guo on 7/19/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import UIKit
import Stripe

class CardFieldViewController: UIViewController {

    let cardField = STPPaymentCardTextField()
    var theme = STPTheme.default()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Card Field"
        view.backgroundColor = UIColor.white
        view.addSubview(cardField)
        edgesForExtendedLayout = []
        view.backgroundColor = theme.primaryBackgroundColor
        cardField.backgroundColor = theme.secondaryBackgroundColor
        cardField.textColor = theme.primaryForegroundColor
        cardField.placeholderColor = theme.secondaryForegroundColor
        cardField.borderColor = theme.accentColor
        cardField.borderWidth = 1.0
        cardField.textErrorColor = theme.errorColor
        cardField.postalCodeEntryEnabled = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationController?.navigationBar.stp_theme = theme
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
        cardField.frame = CGRect(x: padding,
                                 y: padding,
                                 width: view.bounds.width - (padding * 2),
                                 height: 50)
    }

}
