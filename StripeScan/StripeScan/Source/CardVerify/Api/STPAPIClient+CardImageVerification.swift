//
//  VerificationAPI.swift
//  CardVerify
//
//  Created by Jaime Park on 9/15/21.
//

import Foundation

extension STPAPIClient {
    // NOTE: There exists another struct in this codebase called `Result`. Therefore we must qualify it with `Swift.`
    func getCardImageVerificationDetails(
        cardImageVerificationSecret: String,
        cardImageVerificationId: String,
        completion: @escaping (Swift.Result<CardImageVerificationDetailsResponse, Error>) -> Void
    ) {
        var parameters: [String: Any] = [:]
        parameters["client_secret"] = cardImageVerificationSecret

        let endpoint = "card_image_verifications/\(cardImageVerificationId)/initialize_client"

        APIRequest<CardImageVerificationDetailsResponse>.getWith(
            self,
            endpoint: endpoint,
            parameters: parameters
        ) { imageVerificationDetails, _ , error in

            guard let imageVerificationDetails = imageVerificationDetails else {
                completion(.failure(error ?? NSError.stp_genericFailedToParseResponseError()))
                return
            }

            completion(.success(imageVerificationDetails))
        }
    }
}
