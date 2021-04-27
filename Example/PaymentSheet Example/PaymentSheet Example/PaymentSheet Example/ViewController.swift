//
//  ViewController.swift
//  PaymentSheet Example
//
//  Created by Yuki Tokuhiro on 12/4/20.
//  Copyright © 2020 stripe-ios. All rights reserved.
//

import Foundation
import SwiftUI
import UIKit

class ViewController: UIViewController {
    @IBAction func myUnwindAction(unwindSegue: UIStoryboardSegue) {

    }

    @IBSegueAction func showSwiftUIExample(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: ExampleSwiftUIPaymentSheet())
    }

    @IBSegueAction func showSwiftUICustomExample(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: ExampleSwiftUICustomPaymentFlow())
    }

}
