//
//  VerificationPageDataUpdate.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/2/21.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    struct VerificationPageDataUpdate: Encodable, Equatable {

        let clearData: VerificationPageClearData?
        let collectedData: VerificationPageCollectedData?
    }

    // TODO(mludowise|IDPROD-4030): Remove v1 API models when selfie is production ready
    /// API model compatible with V1 Identity endpoints that won't encode a `face` property
    struct VerificationPageDataUpdateV1: Encodable, Equatable {

        let clearData: VerificationPageClearDataV1?
        let collectedData: VerificationPageCollectedDataV1?
    }

}
