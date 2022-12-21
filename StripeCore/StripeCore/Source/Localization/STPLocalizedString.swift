//
//  STPLocalizedString.swift
//  StripeCore
//
//  Created by Mel Ludowise on 7/6/20.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(
        forKey: key,
        bundleLocator: StripeCoreBundleLocator.self
    )
}
