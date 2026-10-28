//
//  STPLocalizedString.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/11/21.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore

@inline(__always) func STPLocalizedString(_ key: String, _ comment: String?) -> String {
    return STPLocalizationUtils.localizedStripeString(
        forKey: key,
        bundleLocator: StripeFinancialConnectionsBundleLocator.self
    )
}
