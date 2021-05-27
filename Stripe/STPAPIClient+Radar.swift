//
//  STPAPIClient+Radar.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

private let APIEndpointRadarSession = "radar/session"

extension STPAPIClient {

    /**
     Creates a Radar Session.

     - Note: See https://stripe.com/docs/radar/radar-session
     - Note: This API and the guide linked above require special permissions to use. Contact support@stripe.com.
     - Note: `StripeAPI.advancedFraudSignalsEnabled` must be `true` to use this method.
     - Note: See `STPRadarSession`

     - Parameters:
        - completion: The callback to run with the returned `STPRadarSession` (and any errors that may have occurred).
     */
    @objc public func createRadarSession(
        completion: @escaping STPRadarSessionCompletionBlock
    ) {
        STPTelemetryClient.shared.updateFraudDetectionIfNecessary() { result in
            switch result {
            case .failure(let error):
                completion(nil, error)
                return
            case .success(let fraudDetectionDataData):
                let paymentUserAgent = "stripe-ios/\(STPAPIClient.STPSDKVersion)"
                let parameters = [
                    "muid": fraudDetectionDataData.muid ?? "",
                    "sid": fraudDetectionDataData.sid ?? "",
                    "guid": fraudDetectionDataData.guid ?? "",
                    "payment_user_agent": paymentUserAgent
                ]
                APIRequest<STPRadarSession>.post(
                    with: self,
                    endpoint: APIEndpointRadarSession,
                    parameters: parameters) { (radarSession, _, error) in
                    completion(radarSession, error)
                }
            }
        }
    }
}
