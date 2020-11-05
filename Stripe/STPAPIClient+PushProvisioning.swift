//
//  STPAPIClient+PushProvisioning.swift
//  Stripe
//
//  Created by Jack Flintermann on 9/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

typealias STPPushProvisioningDetailsCompletionBlock = (STPPushProvisioningDetails?, Error?) -> Void
extension STPAPIClient {
  @objc(retrievePushProvisioningDetailsWithParams:ephemeralKey:completion:)
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
      ]
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
}
