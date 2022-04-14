//
//  CardImageVerificationDetailsResponse.swift
//  StripeCardScan
//
//  Created by Jaime Park on 9/16/21.
//

import Foundation
@_spi(STP) import StripeCore

struct CardImageVerificationExpectedCard: Decodable {
    let last4: String
    let issuer: String
}

struct CardImageVerificationDetailsResponse: Decodable {
    let expectedCard: CardImageVerificationExpectedCard?
}
