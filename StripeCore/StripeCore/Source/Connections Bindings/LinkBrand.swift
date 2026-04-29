//
//  LinkBrand.swift
//  StripeCore
//
//  Created by Sophia Horng on 4/24/26.
//

import Foundation

@_spi(STP) @frozen public enum LinkBrand: String, SafeEnumCodable, Equatable {
    case link = "link"
    case notlink = "notlink"
    case unparsable
}
