//
//  LinkSettings.swift
//  StripePayments
//
//  Created by Ramon Torres on 4/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// For internal SDK use only
@objc(STP_Internal_LinkSettings)
@_spi(STP) public final class LinkSettings: NSObject, STPAPIResponseDecodable {

    @_spi(STP) public let bankOnboardingEnabled: Bool

    @_spi(STP) public let allResponseFields: [AnyHashable: Any]

    @_spi(STP) public init(
        bankOnboardingEnabled: Bool,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.bankOnboardingEnabled = bankOnboardingEnabled
        self.allResponseFields = allResponseFields
    }

    @_spi(STP) public static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard
            let response = response,
            let bankOnboardingEnabled = response["link_bank_onboarding_enabled"] as? Bool
        else {
            return nil
        }

        return LinkSettings(
            bankOnboardingEnabled: bankOnboardingEnabled,
            allResponseFields: response
        ) as? Self
    }

}
