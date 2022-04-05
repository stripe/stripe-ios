//
//  ViewController.swift
//  CocoapodsTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import Stripe
import StripeIdentity
import StripeConnections
import StripeCardScan
import StripeApplePay
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        StripeAPI.defaultPublishableKey = "test"

        if #available(iOS 14.3, *) {
            let _ = IdentityVerificationSheet(verificationSessionClientSecret: "test")
        }

        if #available(iOS 12.0, *) {
            let _ = ConnectionsSheet(linkAccountSessionClientSecret: "")
        }

        if #available(iOS 11.2, *) {
            let _ = CardImageVerificationSheet(
                cardImageVerificationIntentId: "foo",
                cardImageVerificationIntentSecret: "foo"
            )
        }
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
