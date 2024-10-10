//
//  STPAPIClient+PushProvisioning.swift
//  StripeiOS
//
//  Created by Jack Flintermann on 9/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

typealias STPPushProvisioningDetailsCompletionBlock = (STPPushProvisioningDetails?, Error?) -> Void
extension STPAPIClient {
    func retrievePushProvisioningDetails(
        with params: STPPushProvisioningDetailsParams,
        ephemeralKey: STPEphemeralKey,
        completion: @escaping STPPushProvisioningDetailsCompletionBlock
    ) {

        let endpoint = "issuing/cards/\(params.cardId)/push_provisioning_details"
        let parameters = [
            "ios": [
                "certificates": params.certificatesBase64,
                "nonce": params.nonceHex,
                "nonce_signature": params.nonceSignatureHex,
            ] as [String: Any],
        ]

        APIRequest<STPPushProvisioningDetails>.getWith(
            self,
            endpoint: endpoint,
            additionalHeaders: authorizationHeader(using: ephemeralKey),
            parameters: parameters
        ) { details, _, error in
            completion(details, error)
        }
    }
    // MARK: Helpers

    /// A helper method that returns the Authorization header to use for API requests. If ephemeralKey is nil, uses self.publishableKey instead.
    func authorizationHeader(using ephemeralKey: STPEphemeralKey? = nil) -> [String: String] {
        return authorizationHeader(using: ephemeralKey?.secret)
    }
}
