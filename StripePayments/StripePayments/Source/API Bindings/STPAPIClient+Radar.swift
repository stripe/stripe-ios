//
//  STPAPIClient+Radar.swift
//  StripePayments
//
//  Created by Yuki Tokuhiro on 5/20/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

private let APIEndpointRadarSession = "radar/session"

extension STPAPIClient {

    /// Creates a Radar Session.
    ///
    /// - Note: See https://stripe.com/docs/radar/radar-session
    /// - Note: `StripeAPI.advancedFraudSignalsEnabled` must be `true` to use this method.
    /// - Note: See `STPRadarSession`
    ///
    /// - Parameters:
    ///    - completion: The callback to run with the returned `STPRadarSession` (and any errors that may have occurred).
    @objc(createRadarSessionWithCompletion:)
    public func createRadarSession(
        completion: @escaping STPRadarSessionCompletionBlock
    ) {
        STPTelemetryClient.shared.updateFraudDetectionIfNecessary { result in
            switch result {
            case .failure(let error):
                completion(nil, error)
                return
            case .success(let fraudDetectionDataData):
                let paymentUserAgent = PaymentsSDKVariant.paymentUserAgent
                let parameters = [
                    "muid": fraudDetectionDataData.muid ?? "",
                    "sid": fraudDetectionDataData.sid ?? "",
                    "guid": fraudDetectionDataData.guid ?? "",
                    "payment_user_agent": paymentUserAgent,
                ]
                APIRequest<STPRadarSession>.post(
                    with: self,
                    endpoint: APIEndpointRadarSession,
                    parameters: parameters
                ) { (radarSession, _, error) in
                    completion(radarSession, error)
                }
            }
        }
    }
}
