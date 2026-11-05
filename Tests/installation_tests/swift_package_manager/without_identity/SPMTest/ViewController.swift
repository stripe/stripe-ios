//
//  ViewController.swift
//  SPMTest
//
//  Created by Ben Guo on 3/20/18.
//  Copyright © 2018 Stripe. All rights reserved.
//

import Stripe
import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        StripeAPI.defaultPublishableKey = "foo"
    }
}
