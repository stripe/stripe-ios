//
//  STPLocalizedString.swift
//  StripeUICore
//
//  Created by Mel Ludowise on 9/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(forKey: key, bundleLocator: StripeUICoreBundleLocator.self)
}
