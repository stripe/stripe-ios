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
    ) -> Promise<CardImageVerificationDetailsResponse?> {
        let parameters: [String: Any] = ["client_secret": cardImageVerificationSecret]
        let endpoint = APIEndpoints.fetchCardImageVerificationDetails(id: cardImageVerificationId)
        return self.post(resource: endpoint, parameters: parameters)
    }

    /// Request used to complete the verification flow by submitting the verification frames
    func submitVerificationFrames(
        cardImageVerificationId: String,
        verifyFrames: VerifyFrames
    ) -> Promise<EmptyResponse> {
        let endpoint = APIEndpoints.submitVerificationFrames(id: cardImageVerificationId)
        return self.post(resource: endpoint, object: verifyFrames)
    }

    func submitVerificationFrames(
        cardImageVerificationId: String,
        cardImageVerificationSecret: String,
        verificationFramesData: [VerificationFramesData]
    ) -> Promise<EmptyResponse> {
        do {
            /// TODO: Replace this with writing the JSON to a string instead of a data
            /// Encode the array of verification frames data into JSON
            let jsonEncoder = JSONEncoder()
            jsonEncoder.keyEncodingStrategy = .convertToSnakeCase
            let jsonVerificationFramesData = try jsonEncoder.encode(verificationFramesData)

            /// Turn the JSON data into a string
            let verificationFramesDataString = String(data: jsonVerificationFramesData, encoding: .utf8) ?? ""

            /// Create a `VerifyFrames` object
            let verifyFrames = VerifyFrames(
                clientSecret: cardImageVerificationSecret,
                verificationFramesData: verificationFramesDataString
            )

            return self.submitVerificationFrames(cardImageVerificationId: cardImageVerificationId, verifyFrames: verifyFrames)
        } catch(let error) {
            let promise = Promise<EmptyResponse>()
            promise.reject(with: error)
            return promise
        }
    }

    /// Request used to upload analytics of a card scanning session
    /// This will be a fire-and-forget request
    @discardableResult
    func uploadScanStats(
        cardImageVerificationId: String,
        cardImageVerificationSecret: String,
        scanAnalyticsPayload: ScanAnalyticsPayload
    ) -> Promise<EmptyResponse> {
        /// Create URL with endpoint
        let endpoint = APIEndpoints.uploadScanStats(id: cardImageVerificationId)
        /// Create scan stats payload with secret key
        let payload = ScanStatsPayload(
            clientSecret: cardImageVerificationSecret,
            payload: scanAnalyticsPayload
        )
        return self.post(resource: endpoint, object: payload)
    }
}

private struct APIEndpoints {
    static func fetchCardImageVerificationDetails(id: String) -> String {
        return  "card_image_verifications/\(id)/initialize_client"
    }

    static func submitVerificationFrames(id: String) -> String {
        return "card_image_verifications/\(id)/verify_frames"
    }

    static func uploadScanStats(id: String) -> String {
        return "card_image_verifications/\(id)/scan_stats"
    }
}
