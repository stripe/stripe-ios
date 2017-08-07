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
    method_exchangeImplementations(originalMethod, swizzledMethod)
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
    func apiClient() -> STPAPIClient? {
        return nil
    }

    func swizzled_apiClient() -> STPAPIClient? {
        return MockAPIClient()
    }
}

class MockAPIClient: STPAPIClient {

    override func createToken(withCard card: STPCardParams, completion: STPTokenCompletionBlock? = nil) {
        guard let completion = completion else { return }

        // Generate a mock card model using the given card params
        var cardJSON: [String: Any] = [:]
        cardJSON["id"] = "\(card.hashValue)"
        cardJSON["exp_month"] = "\(card.expMonth)"
        cardJSON["exp_year"] = "\(card.expYear)"
        cardJSON["name"] = card.name
        cardJSON["address_line1"] = card.address.line1
        cardJSON["address_line2"] = card.address.line2
        cardJSON["address_state"] = card.address.state
        cardJSON["address_zip"] = card.address.postalCode
        cardJSON["address_country"] = card.address.country
        cardJSON["last4"] = card.last4()
        if let number = card.number {
            let brand = STPCardValidator.brand(forNumber: number)
            cardJSON["brand"] = STPCard.string(from: brand)
        }
        cardJSON["fingerprint"] = "\(card.hashValue)"
        cardJSON["country"] = "US"
        let tokenJSON: [String: Any] = [
            "id": "\(card.hashValue)",
            "object": "token",
            "livemode": false,
            "created": NSDate().timeIntervalSince1970,
            "used": false,
            "card": cardJSON,
        ]
        let token = STPToken.decodedObject(fromAPIResponse: tokenJSON)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            completion(token, nil)
        }
    }
}
