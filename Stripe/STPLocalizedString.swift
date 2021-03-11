//
//  STPLocalizedString.swift
//  StripeiOS
//
//  Created by David Estes on 10/19/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(forKey: key)
}
