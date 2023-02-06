//
//  VerificationPageStaticContentCountryNotListedPage.swift
//  StripeIdentity
//
//  Created by Chen Cen on 2/1/23.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageStaticContentCountryNotListedPage: Decodable, Equatable {
        let title: String
        let body: String
        let cancelButtonText: String
        let idFromOtherCountryTextButtonText: String
        let addressFromOtherCountryTextButtonText: String
    }
}
