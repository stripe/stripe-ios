//
//  AutoCompleteConstants.swift
//  StripeiOS
//
//  Created by Nick Porter on 6/23/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

final class AutoCompleteConstants {
    
    /// A list of countries that is supported by auto complete
    /// Inspired by https://git.corp.stripe.com/stripe-internal/stripe-js-v3/blob/master/src/elements/inner/shipping_address/components/NewAddressForm.tsx#L36
    static var supportedCountries: Set<String> = Set(arrayLiteral:
                                              "AU",
                                              "BE",
                                              "BR",
                                              "CA",
                                              "CH",
                                              "DE",
                                              "ES",
                                              "FR",
                                              "GB",
                                              "IE",
                                              "IT",
                                              "MX",
                                              "NO",
                                              "NL",
                                              "PL",
                                              "RU",
                                              "SE",
                                              "TR",
                                              "US",
                                              "ZA"
    )
}
