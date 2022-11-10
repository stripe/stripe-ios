//
//  ViewController.swift
//  SPMTest
//
//  Created by Mel Ludowise on 8/3/21.
//  Copyright © 2021 Stripe. All rights reserved.
//

import Stripe
import StripeApplePay
import StripeCardScan
import StripeFinancialConnections
import StripeIdentity
import StripePaymentSheet
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        StripeAPI.defaultPublishableKey = "foo"

        if #available(iOS 14.3, *) {
            let _ = IdentityVerificationSheet(verificationSessionClientSecret: "test")
        }

        if #available(iOS 12.0, *) {
            let _ = FinancialConnectionsSheet(
                financialConnectionsSessionClientSecret: "",
                returnURL: nil
            )
        }

        // Initialize a card field to make sure we can load image resources
        let cardField = STPPaymentCardTextField()
        cardField.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        self.view.addSubview(cardField)
        let _ = CardImageVerificationSheet(
            cardImageVerificationIntentId: "foo",
            cardImageVerificationIntentSecret: "foo"
        )

        let _ = PaymentSheet(
            setupIntentClientSecret: "",
            configuration: PaymentSheet.Configuration()
        )
        // Do any additional setup after loading the view.

    }
}
