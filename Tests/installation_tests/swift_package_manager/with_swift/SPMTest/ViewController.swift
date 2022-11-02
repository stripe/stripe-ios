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
import StripeFinancialConnections
import StripeCardScan
import StripeApplePay
import StripePaymentSheet

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        StripeAPI.defaultPublishableKey = "foo"

        if #available(iOS 14.3, *) {
            let _ = IdentityVerificationSheet(verificationSessionClientSecret: "test")
        }

        if #available(iOS 12.0, *) {
            let _ = FinancialConnectionsSheet(financialConnectionsSessionClientSecret: "", returnURL: nil)
        }

        // Initialize a card field to make sure we can load image resources
        let cardField = STPPaymentCardTextField()
        cardField.frame = CGRect(x: 0, y: 0, width: 300, height: 100)
        self.view.addSubview(cardField)
        let _ = CardImageVerificationSheet(
            cardImageVerificationIntentId: "foo",
            cardImageVerificationIntentSecret: "foo"
        )
        
        let _ = PaymentSheet(setupIntentClientSecret: "", configuration: PaymentSheet.Configuration())
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
