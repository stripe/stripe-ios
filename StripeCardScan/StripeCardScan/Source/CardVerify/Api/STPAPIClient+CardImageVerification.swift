//
//  VerificationAPI.swift
//  CardVerify
//
//  Created by Jaime Park on 9/15/21.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {
    func getCardImageVerificationDetails(
        cardImageVerificationSecret: String,
        cardImageVerificationId: String
    ) -> Promise<CardImageVerificationDetailsResponse> {
        let parameters: [String: Any] = ["client_secret": cardImageVerificationSecret]
        let endpoint = "card_image_verifications/\(cardImageVerificationId)/initialize_client"
        return self.get(resource: endpoint, parameters: parameters)
    }
}
