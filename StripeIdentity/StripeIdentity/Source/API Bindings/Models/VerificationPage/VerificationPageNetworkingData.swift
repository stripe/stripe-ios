//
//  VerificationPageNetworkingData.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore

enum NetworkedIdentityRoute: Equatable {
    case none
    case reuse
    case save
}

extension StripeAPI {
    struct VerificationPageNetworkingData: Decodable, Equatable {
        let features: VerificationPageNetworkingFeatures?
    }

    struct VerificationPageNetworkingFeatures: Decodable, Equatable {
        let viCompatible: Bool?
        let viMerchantEligible: Bool?
        let viMerchantEnabled: Bool?
        let consumerSaveEnabled: Bool?
        let consumerReuseEnabled: Bool?
        let consumerReusePossible: Bool?

        var route: NetworkedIdentityRoute {
            guard viCompatible == true,
                  viMerchantEligible == true,
                  viMerchantEnabled == true else {
                return .none
            }
            if consumerReuseEnabled == true, consumerReusePossible == true {
                return .reuse
            }
            if consumerSaveEnabled == true {
                return .save
            }
            return .none
        }
    }
}

extension StripeAPI.VerificationPage {
    var networkedIdentityRoute: NetworkedIdentityRoute {
        networkingData?.features?.route ?? .none
    }
}
