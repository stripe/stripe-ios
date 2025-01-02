//
//  ViewController.swift
//  CarthageTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import Stripe
import StripeApplePay
import StripeCardScan
@_spi(PrivateBetaConnect) import StripeConnect
import StripeFinancialConnections
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        StripeAPI.defaultPublishableKey = "test"
        StripeAPI.paymentRequest(withMerchantIdentifier: "test", country: "US", currency: "USD")

        let _ = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: "",
            returnURL: nil
        )

        let _ = CardImageVerificationSheet(
            cardImageVerificationIntentId: "foo",
            cardImageVerificationIntentSecret: "foo"
        )

        if #available(iOS 15.0, *) {
            let _ = EmbeddedComponentManager {
                return nil
            }
        }
    }
}
