//
//  MockAPIClient.swift
//  UI Examples
//
//  Created by Ben Guo on 7/18/17.
//  Copyright © 2017 Stripe. All rights reserved.
//

import Foundation
import Stripe

private let swizzle: (AnyClass, Selector, Selector) -> () = { forClass, originalSelector, swizzledSelector in
    let originalMethod = class_getInstanceMethod(forClass, originalSelector)
    let swizzledMethod = class_getInstanceMethod(forClass, swizzledSelector)
    method_exchangeImplementations(originalMethod!, swizzledMethod!)
}


extension STPAddCardViewController {

    // We can't swizzle in initialize because it's been deprecated in Swift 3.1.
    // Instead, we have to call this method before STPAddCardViewController appears.
    static func startMockingAPIClient() {
        let originalSelector = #selector(apiClient)
        let swizzledSelector = #selector(swizzled_apiClient)
        swizzle(self, originalSelector, swizzledSelector)
    }

    // Expose the private `apiClient` property as a method
    @objc func apiClient() -> STPAPIClient? {
        return nil
    }

    @objc func swizzled_apiClient() -> STPAPIClient? {
        return MockAPIClient()
    }
}

class MockAPIClient: STPAPIClient {
    override func createPaymentMethod(with paymentMethodParams: STPPaymentMethodParams, completion: @escaping STPPaymentMethodCompletionBlock) {
        guard let card = paymentMethodParams.card, let billingDetails = paymentMethodParams.billingDetails else { return }
        
        // Generate a mock card model using the given card params
        var cardJSON: [String: Any] = [:]
        var billingDetailsJSON: [String: Any] = [:]
        cardJSON["id"] = "\(card.hashValue)"
        cardJSON["exp_month"] = "\(card.expMonth ?? 0)"
        cardJSON["exp_year"] = "\(card.expYear ?? 0)"
        cardJSON["last4"] = card.number?.suffix(4)
        billingDetailsJSON["name"] = billingDetails.name
        billingDetailsJSON["line1"] = billingDetails.address?.line1
        billingDetailsJSON["line2"] = billingDetails.address?.line2
        billingDetailsJSON["state"] = billingDetails.address?.state
        billingDetailsJSON["postal_code"] = billingDetails.address?.postalCode
        billingDetailsJSON["country"] = billingDetails.address?.country
        cardJSON["country"] = billingDetails.address?.country
        if let number = card.number {
            let brand = STPCardValidator.brand(forNumber: number)
            cardJSON["brand"] = STPCard.string(from: brand)
        }
        cardJSON["fingerprint"] = "\(card.hashValue)"
        cardJSON["country"] = "US"
        let paymentMethodJSON: [String: Any] = [
            "id": "\(card.hashValue)",
            "object": "payment_method",
            "type": "card",
            "livemode": false,
            "created": NSDate().timeIntervalSince1970,
            "used": false,
            "card": cardJSON,
            "billing_details": billingDetailsJSON,
        ]
        let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodJSON)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            completion(paymentMethod, nil)
        }
    }
}
