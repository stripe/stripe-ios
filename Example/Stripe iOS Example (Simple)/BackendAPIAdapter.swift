//
//  BackendAPIAdapter.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe

class BackendAPIAdapter: NSObject, STPBackendAPIAdapter {
    @objc var sources: [STPSource]? = []
    @objc var selectedSource: STPSource?
    @objc var shippingAddress: STPAddress?

    @objc func retrieveSources(completion: STPSourceCompletionBlock) {
        completion(self.selectedSource, self.sources, nil)
    }

    @objc func addSource(source: STPSource, completion: STPSourceCompletionBlock) {
        self.sources?.append(source)
        self.selectSource(source, completion: completion)
    }

    @objc func selectSource(source: STPSource, completion: STPSourceCompletionBlock) {
        self.selectedSource = source
        completion(source, self.sources, nil)
    }

    @objc func retrieveCustomerShippingAddress(completion: STPAddressCompletionBlock) {
        completion(self.shippingAddress, nil)
    }

    @objc func updateCustomerShippingAddress(shippingAddress: STPAddress, completion: STPAddressCompletionBlock) {
        self.shippingAddress = shippingAddress
        completion(self.shippingAddress, nil)
    }

}
