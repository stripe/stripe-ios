//
//  AddressSpecProvider.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 7/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

// This file was adapted from stripe-js-v3's checkoutSupportedCountries.js
let addressDataFilename = "localized_address_data"

@_spi(STP) public class AddressSpecProvider {
    @_spi(STP) public static var shared: AddressSpecProvider = AddressSpecProvider()
    var addressSpecs: [String: AddressSpec] = [:]
    var countries: [String] {
        return addressSpecs.map { $0.key }
    }
    private lazy var addressSpecsUpdateQueue: DispatchQueue = {
        DispatchQueue(label: addressDataFilename, qos: .userInitiated)
    }()
    
    public func loadAddressSpecs(completion: (() -> Void)? = nil) {
        addressSpecsUpdateQueue.async {
            let bundle = StripeUICoreBundleLocator.resourcesBundle
            guard
                self.addressSpecs.isEmpty,
                let url = bundle.url(forResource: addressDataFilename, withExtension: ".json"),
                let data = try? Data(contentsOf: url),
                let addressSpecs = try? JSONDecoder().decode([String: AddressSpec].self, from: data)
            else {
                completion?()
                return
            }
            self.addressSpecs = addressSpecs
            completion?()
        }
    }
    
    func addressSpec(for country: String) -> AddressSpec {
        guard let spec = addressSpecs[country] else {
            return AddressSpec.default
        }
        return spec
    }
}
