//
//  STPAPIClient+CardImageVerification.swift
//  StripeCardScan
//
//  Created by Jaime Park on 9/15/21.
//

import Foundation
@_spi(STP) import StripeCore

extension STPAPIClient {
    /// Request used in the beginning of the scan flow to gather CIV details and update the UI with last4 and issuer
    func fetchCardImageVerificationDetails(
        cardImageVerificationSecret: String,
        cardImageVerificationId: String
    ) -> Promise<CardImageVerificationDetailsResponse> {
        let parameters: [String: Any] = ["client_secret": cardImageVerificationSecret]
        let endpoint = APIEndpoints.fetchCardImageVerificationDetails(id: cardImageVerificationId)
        return self.post(resource: endpoint, parameters: parameters)
    }

    func submitVerificationFrames(
        cardImageVerificationId: String,
        verifyFrames: VerifyFrames
    ) -> Promise<EmptyResponse> {
        let endpoint = APIEndpoints.submitVerificationFrames(id: cardImageVerificationId)
        return self.post(resource: endpoint, object: verifyFrames)
    }
}

private struct APIEndpoints {
    static func fetchCardImageVerificationDetails(id: String) -> String {
        return  "card_image_verifications/\(id)/initialize_client"
    }

    static func submitVerificationFrames(id: String) -> String {
        return "card_image_verifications/\(id)/verify_frames"
    }
}
