//
//  UserDefaults+PaymentsCore.swift
//  StripeCore
//
//  Created by David Estes on 11/16/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension UserDefaults {
    /// Canonical list of all UserDefaults keys the SDK uses.
    enum StripePaymentsCoreKeys: String {
        /// The key for a dictionary FraudDetectionData dictionary.
        case fraudDetectionData = "com.stripe.lib:FraudDetectionDataKey"
    }

    var fraudDetectionData: FraudDetectionData? {
        get {
            let key = StripePaymentsCoreKeys.fraudDetectionData.rawValue
            guard let data = data(forKey: key) else {
                return nil
            }
            do {
                return try JSONDecoder().decode(FraudDetectionData.self, from: data)
            } catch let e {
                assertionFailure("\(e)")
                return nil
            }
        }
        set {
            let key = StripePaymentsCoreKeys.fraudDetectionData.rawValue
            do {
                let data = try JSONEncoder().encode(newValue)
                setValue(data, forKey: key)
            } catch let e {
                assertionFailure("\(e)")
                return
            }
        }
    }
}
