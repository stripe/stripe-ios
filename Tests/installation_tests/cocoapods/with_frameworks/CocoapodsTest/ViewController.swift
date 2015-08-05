//
//  ViewController.swift
//  CocoapodsTest
//
//  Created by Jack Flintermann on 8/4/15.
//  Copyright (c) 2015 jflinter. All rights reserved.
//

import UIKit
import Stripe

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        Stripe.setDefaultPublishableKey("test")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

