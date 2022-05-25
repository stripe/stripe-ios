//
//  STPLinkSettings.swift
//  StripeiOS
//
//  Created by Ramon Torres on 4/20/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// For internal SDK use only
@objc(STP_Internal_LinkSettings)
final class LinkSettings: NSObject, STPAPIResponseDecodable {

    let bankOnboardingEnabled: Bool

    let allResponseFields: [AnyHashable : Any]

    internal init(
        bankOnboardingEnabled: Bool,
        allResponseFields: [AnyHashable : Any]
    ) {
        self.bankOnboardingEnabled = bankOnboardingEnabled
        self.allResponseFields = allResponseFields
    }

    static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
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
