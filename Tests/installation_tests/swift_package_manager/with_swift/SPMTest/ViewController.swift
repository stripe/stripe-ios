//
//  ViewController.swift
//  SPMTest
//
//  Created by Mel Ludowise on 8/3/21.
//  Copyright © 2021 Stripe. All rights reserved.
//

import UIKit
import Stripe
import StripeIdentity

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        StripeAPI.defaultPublishableKey = "foo"
        let _ = IdentityVerificationSheet(verificationSessionClientSecret: "test")
        // Do any additional setup after loading the view.

    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
