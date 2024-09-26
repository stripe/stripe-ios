//
//  ElementsSessionContext.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-25.
//

import Foundation

/// Contains elements session context useful for the Financial Connections SDK.
@_spi(STP) public struct ElementsSessionContext {
    @_spi(STP) public let linkMode: LinkMode?

    @_spi(STP) public init(linkMode: LinkMode?) {
        self.linkMode = linkMode
    }
}
