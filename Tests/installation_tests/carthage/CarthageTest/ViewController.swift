//
//  ViewController.swift
//  CarthageTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import Stripe
import StripeIdentity
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        StripeAPI.defaultPublishableKey = "test"
        StripeAPI.paymentRequest(withMerchantIdentifier: "test", country: "US", currency: "USD")
        let _ = IdentityVerificationSheet(verificationSessionClientSecret: "test")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
