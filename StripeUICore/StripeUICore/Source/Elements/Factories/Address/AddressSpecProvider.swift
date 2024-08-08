//
//  AddressSpecProvider.swift
//  StripeUICore
//
//  Created by Yuki Tokuhiro on 7/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// This file was adapted from https://git.corp.stripe.com/stripe-internal/stripe-js-v3/blob/bdc2eeed/src/elements/inner/shared/address/addressData.ts
let addressDataFilename = "localized_address_data"

@_spi(STP) public class AddressSpecProvider {
    enum Error: Swift.Error {
        case loadSpecsFailure
    }

    @_spi(STP) nonisolated(unsafe) public static var shared: AddressSpecProvider = AddressSpecProvider()
    var addressSpecs: [String: AddressSpec] = [:]
    public var countries: [String] {
        return addressSpecs.map { $0.key }
    }

    public func loadAddressSpecs() async {
        let bundle = StripeUICoreBundleLocator.resourcesBundle
        // Early exit if we have already loaded the specs
        guard self.addressSpecs.isEmpty else {
            return
        }

        guard let url = bundle.url(forResource: addressDataFilename, withExtension: ".json") else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedStripeUICoreAddressSpecProvider,
                                              error: Error.loadSpecsFailure)
            await STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let addressSpecs = try JSONDecoder().decode([String: AddressSpec].self, from: data)
            self.addressSpecs = addressSpecs
        } catch {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedStripeUICoreAddressSpecProvider,
                                              error: error)
            await STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
        }
    }

    func addressSpec(for country: String) -> AddressSpec {
        guard let spec = addressSpecs[country] else {
            return AddressSpec.default
        }
        return spec
    }
}
