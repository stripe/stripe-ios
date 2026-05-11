//
//  LinkBrand.swift
//  StripeCore
//
//  Created by Sophia Horng on 4/24/26.
//

import Foundation

@_spi(STP) @frozen public enum LinkBrand: String, SafeEnumCodable, Equatable {
    case link = "link"
    // Keep the backend-facing raw value unchanged until the rollout is ready.
    case onelink = "notlink"
    case unparsable

    /// Brand names are proper nouns, so keep the source-of-truth user-facing value here.
    @_spi(STP) public var displayName: String {
        switch self {
        case .link, .unparsable:
            return "Link"
        case .onelink:
            return "Onelink"
        }
    }
}
