//
//  MockSTPPaymentAuthVCDelegate.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/28/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Stripe

class MockSTPPaymentAuthVCDelegate: NSObject, STPPaymentAuthorizationViewControllerDelegate {

    var onDidCancel: (() -> ())?
    var onDidFailWithError: (NSError -> ())?
    var onDidCreatePaymentResult: ((STPPaymentResult, STPErrorBlock) -> ())?

    @objc func paymentAuthorizationViewControllerDidCancel(paymentAuthorizationViewController: STPPaymentAuthorizationViewController) {
        onDidCancel?()
    }

    @objc func paymentAuthorizationViewController(paymentAuthorizationViewController: STPPaymentAuthorizationViewController, didFailWithError error: NSError) {
        onDidFailWithError?(error)
    }

    @objc func paymentAuthorizationViewController(paymentAuthorizationViewController: STPPaymentAuthorizationViewController, didCreatePaymentResult result: STPPaymentResult, completion: STPErrorBlock) {
        onDidCreatePaymentResult?(result, completion)
    }
}
