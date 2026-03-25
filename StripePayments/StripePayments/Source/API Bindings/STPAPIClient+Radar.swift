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
private let APIEndpointSavedPaymentMethodRadarSession = "radar/saved_payment_method_session"

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

    /// Creates a Radar Session.
    ///
    /// - Note: See https://stripe.com/docs/radar/radar-session
    /// - Note: `StripeAPI.advancedFraudSignalsEnabled` must be `true` to use this method.
    /// - Note: See `STPRadarSession`
    ///
    /// - Returns: A `STPRadarSession` instance.
    public func createRadarSession() async throws -> STPRadarSession {
        return try await withCheckedThrowingContinuation { continuation in
            createRadarSession { radarSession, error in
                guard let radarSession else {
                    continuation.resume(throwing: error ?? NSError.stp_genericErrorOccurredError())
                    return
                }
                continuation.resume(returning: radarSession)
            }
        }
    }

    /// Creates a Radar Session for a saved payment method.
    ///
    /// - Note: See https://stripe.com/docs/radar/radar-session
    /// - Note: `StripeAPI.advancedFraudSignalsEnabled` must be `true` to use this method.
    /// - Note: See `STPRadarSession`
    ///
    /// - Parameters:
    ///    - paymentMethodId: The ID of the payment method to create a radar session for.
    ///    - completion: The callback to run with the returned `STPRadarSession` (and any errors that may have occurred).
    @_spi(STP) public func createSavedPaymentMethodRadarSession(
        paymentMethodId: String,
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
                    "payment_method": paymentMethodId,
                ]
                APIRequest<STPRadarSession>.post(
                    with: self,
                    endpoint: APIEndpointSavedPaymentMethodRadarSession,
                    parameters: parameters
                ) { (radarSession, _, error) in
                    completion(radarSession, error)
                }
            }
        }
    }
}
