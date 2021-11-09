//
//  CardImageVerificationDetailsResponse.swift
//  CardVerify
//
//  Created by Jaime Park on 9/16/21.
//

import Foundation

struct CardImageVerificationExpectedCard: Decodable {
    let last4: String
    let issuer: String
}

struct CardImageVerificationDetailsResponse: Decodable {
    let expectedCard: CardImageVerificationExpectedCard

    enum CodingKeys: String, CodingKey {
        case expectedCard = "expected_card"
    }
}
