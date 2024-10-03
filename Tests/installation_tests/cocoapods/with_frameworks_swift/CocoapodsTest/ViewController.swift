//
//  ViewController.swift
//  CocoapodsTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import Stripe
import StripeApplePay
import StripeCardScan
@_spi(PrivateBetaConnect) import StripeConnect
import StripeFinancialConnections
import StripeIdentity
import StripePaymentSheet
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        StripeAPI.defaultPublishableKey = "test"

        if #available(iOS 14.3, *) {
            let _ = IdentityVerificationSheet(verificationSessionClientSecret: "test")
        }

        let _ = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: "",
            returnURL: nil
        )

        let _ = CardImageVerificationSheet(
            cardImageVerificationIntentId: "foo",
            cardImageVerificationIntentSecret: "foo"
        )

        let _ = PaymentSheet(
            paymentIntentClientSecret: "",
            configuration: PaymentSheet.Configuration()
        )

        if #available(iOS 15.0, *) {
            let _ = EmbeddedComponentManager {
                nil
            }
        }
    }
}
