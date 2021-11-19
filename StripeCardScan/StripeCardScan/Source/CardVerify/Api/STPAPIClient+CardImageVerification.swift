//
//  STPAPIClient+CardImageVerification.swift
//  StripeCardScan
//
//  Created by Jaime Park on 9/15/21.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {
    func fetchCardImageVerificationDetails(
        cardImageVerificationSecret: String,
        cardImageVerificationId: String
    ) -> Promise<CardImageVerificationDetailsResponse> {
        let parameters: [String: Any] = ["client_secret": cardImageVerificationSecret]
        let endpoint = "card_image_verifications/\(cardImageVerificationId)/initialize_client"
        return self.post(resource: endpoint, parameters: parameters)
    }
}
