//
//  ElementsContext.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-23.
//

import Foundation

@_spi(STP) public struct ElementsContext {
    @_spi(STP) public let linkMode: LinkMode?

    @_spi(STP) public init(linkMode: LinkMode?) {
        self.linkMode = linkMode
    }
}
