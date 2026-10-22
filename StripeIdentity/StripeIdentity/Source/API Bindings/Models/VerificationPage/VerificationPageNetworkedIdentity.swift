//
//  VerificationPageNetworkedIdentity.swift
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

        let saveEnabled: Bool?
        /// Reuse may be tried with Link sign-in, even when no saved document is known.
        let reuseEnabled: Bool?
        /// A saved document that fits this session was found; it only adds emphasis to the reuse offer.
        let reuseAvailable: Bool?
        let lookupEmail: String?
        /// Prefills Link sign-up only; never used to look up or select a Link account.
        let phoneNumberAutofillHint: String?
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
            if reuseEnabled == true {
                return .reuse
            }
            if saveEnabled == true {
                return .save
            }
            return .none
        }
    }
}

extension StripeAPI.VerificationPage {
    var networkedIdentityRoute: NetworkedIdentityRoute {
        networkedIdentity?.route ?? .none
    }
}
