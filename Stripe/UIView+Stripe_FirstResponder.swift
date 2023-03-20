//
//  UIView+Stripe_FirstResponder.swift
//  Stripe
//
//  Created by Jack Flintermann on 4/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

extension UIView {
    @objc func stp_findFirstResponder() -> UIView? {
        if isFirstResponder {
            return self
        }
        for subView in subviews {
            let responder = subView.stp_findFirstResponder()
            if let responder = responder {
                return responder
            }
        }
        return nil
    }
}
