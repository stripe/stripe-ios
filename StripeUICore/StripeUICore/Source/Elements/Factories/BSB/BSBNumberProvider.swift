//
//  BSBNumberProvider.swift
//  StripeUICore
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

@_spi(STP) public class BSBNumberProvider {
    enum Error: Swift.Error {
        case bsbLoadFailure
    }

    private let bsbDataFilename = "au_becs_bsb"

    @_spi(STP) public static var shared: BSBNumberProvider = BSBNumberProvider()
    var bsbNumberToNameMapping: [String: String] = [:]
    private let bsbNumberUpdateQueue = DispatchQueue(label: "com.stripe.BSB.BSBNumberProvider", qos: .userInitiated)

    public func loadBSBData(completion: (() -> Void)? = nil) {
        bsbNumberUpdateQueue.async {
            // Early exit if we have already loaded the BSBNumber mapping
            guard self.bsbNumberToNameMapping.isEmpty else {
                completion?()
                return
            }

            let bundle = StripeUICoreBundleLocator.resourcesBundle
            guard let url = bundle.url(forResource: self.bsbDataFilename, withExtension: ".json") else {
                let errorAnalytic = ErrorAnalytic(event: .unexpectedStripeUICoreBSBNumberProvider,
                                                  error: Error.bsbLoadFailure)
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                completion?()
                return
            }

            do {
                let data = try Data(contentsOf: url)
                let decodedBSBs = try JSONDecoder().decode([String: String].self, from: data)
                #if DEBUG
                var accumulator: [String: String] = ["00": "Stripe Test Bank"]
                decodedBSBs.forEach { (key, value) in
                    accumulator[key] = value
                }
                self.bsbNumberToNameMapping = accumulator
                #else
                self.bsbNumberToNameMapping = decodedBSBs
                #endif
                completion?()
            } catch {
                let errorAnalytic = ErrorAnalytic(event: .unexpectedStripeUICoreBSBNumberProvider,
                                                  error: error)
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                completion?()
            }
        }
    }

    func bsbName(for bsbNumber: String) -> String {
        for i in (2...3).reversed() {
            let bsbPrefix = String(bsbNumber.prefix(i))
            if let resolvedBSBName = bsbNumberToNameMapping[bsbPrefix] {
                return resolvedBSBName
            }
        }
        return ""
    }
}
