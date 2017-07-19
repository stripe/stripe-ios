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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Card Field"
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.cardField)
        self.edgesForExtendedLayout = []
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.cardField.becomeFirstResponder()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let padding: CGFloat = 15
        self.cardField.frame = CGRect(x: padding,
                                      y: padding,
                                      width: self.view.bounds.width - (padding * 2),
                                      height: 50)
    }

}
