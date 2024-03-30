//
//  ConsumerSession+LookupResponse.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 11/2/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

extension ConsumerSession {
    final class LookupResponse: Decodable {
        enum ResponseType {
            case found(consumerSession: SessionWithPublishableKey)

            // errorMessage can be used internally to differentiate between
            // a not found because of an unrecognized email or a not found
            // due to an invalid cookie
            case notFound(errorMessage: String)

            /// Lookup call was not provided an email and no cookies stored
            case noAvailableLookupParams

            var analyticValue: String {
                switch self {
                case .found:
                    return "found"
                case .notFound:
                    return "notFound"
                case .noAvailableLookupParams:
                    return "noAvailableLookupParams"

                }
            }
        }

        let responseType: ResponseType

        init(_ responseType: ResponseType) {
            self.responseType = responseType
        }

        private enum CodingKeys: String, CodingKey {
            case exists
            case errorMessage
        }

        convenience init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let exists = try container.decode(Bool.self, forKey: .exists)
            let responseType: ResponseType

            if exists {
                let session = try decoder.singleValueContainer().decode(SessionWithPublishableKey.self)
                responseType = .found(consumerSession: session)
            } else {
                let errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage) ?? NSError.stp_unexpectedErrorMessage()
                responseType = .notFound(errorMessage: errorMessage)
            }
            self.init(responseType)
        }
    }
}
