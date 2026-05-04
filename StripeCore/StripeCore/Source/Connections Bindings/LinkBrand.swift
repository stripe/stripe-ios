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
}
