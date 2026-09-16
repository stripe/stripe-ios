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
    case resumeReuse
    case resumeSave
}

extension StripeAPI {
    // #TODO - Networked Identity: Confirm the v8 bootstrap contract before enabling production routing.
    struct VerificationPageNetworkedIdentity: Decodable, Equatable {
        struct State: Decodable, Equatable {
            enum Direction: String, SafeEnumDecodable, Equatable {
                case consumerToMerchant = "consumer_to_merchant"
                case merchantToConsumer = "merchant_to_consumer"
                case unparsable
            }

            let consented: Bool?
            let skipped: Bool?
            let direction: Direction?
        }

        let saveAvailable: Bool?
        let reuseAvailable: Bool?
        let email: String?
        let phoneNumber: String?
        let state: State?

        var route: NetworkedIdentityRoute {
            guard let state, state.skipped == false, let consented = state.consented else {
                return .none
            }
            if consented {
                switch state.direction {
                case .consumerToMerchant:
                    return .resumeReuse
                case .merchantToConsumer:
                    return .resumeSave
                case .unparsable, nil:
                    return .none
                }
            }
            // An unrecognized or inconsistent direction must not restart a consent flow.
            guard state.direction == nil else {
                return .none
            }
            if reuseAvailable == true {
                return .reuse
            }
            if saveAvailable == true {
                return .save
            }
            return .none
        }
    }

    // Kept for decoding older responses only; v8 routing uses networked_identity instead.
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
    }
}

extension StripeAPI.VerificationPage {
    var networkedIdentityRoute: NetworkedIdentityRoute {
        networkedIdentity?.route ?? .none
    }
}
