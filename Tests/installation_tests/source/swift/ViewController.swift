//
//  ViewController.swift
//  CarthageTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import Stripe

class ViewController: UIViewController {

    let pushButton = UIButton(type: .System)
    let presentButton = UIButton(type: .System)
    var paymentContext: STPPaymentContext? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        let config = STPPaymentConfiguration.sharedConfiguration()
        config.publishableKey = "test"
        let theme = STPTheme()
        theme.accentColor = UIColor.purpleColor()
        let paymentContext = STPPaymentContext(APIAdapter: MyAPIClient(),
                                               configuration: config,
                                               theme: theme)
        paymentContext.hostViewController = self
        self.paymentContext = paymentContext
        self.pushButton.setTitle("Push", forState: .Normal)
        self.pushButton.sizeToFit()
        self.pushButton.addTarget(self, action: #selector(push), forControlEvents: .TouchUpInside)
        self.presentButton.setTitle("Present", forState: .Normal)
        self.presentButton.sizeToFit()
        self.presentButton.addTarget(self, action: #selector(present), forControlEvents: .TouchUpInside)
        self.view.addSubview(self.pushButton)
        self.view.addSubview(self.presentButton)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.pushButton.center = CGPointMake(self.view.bounds.midX, self.view.bounds.midY/2.0)
        self.presentButton.center = CGPointMake(self.view.bounds.midX, self.view.bounds.midY*3.0/4.0)
    }

    func push() {
        self.paymentContext?.pushPaymentMethodsViewController()
    }

    func present() {
        self.paymentContext?.presentPaymentMethodsViewController()
    }
    
}
