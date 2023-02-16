//
//  VerificationPageStaticContentIndividualPage.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/27/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {

    struct VerificationPageStaticContentIndividualPage: Decodable, Equatable {
        let addressCountries: [String: String]
        let buttonText: String
        let title: String
        let idNumberCountries: [String: String]
        let idNumberCountryNotListedTextButtonText: String
        let addressCountryNotListedTextButtonText: String
    }
}
