//
//  ElementsContext.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-20.
//

import Foundation

@_spi(STP) public struct ElementsContext {
    @_spi(STP) public enum LinkMode: String {
        case linkPaymentMethod = "LINK_PAYMENT_METHOD"
        case passthrough = "PASSTHROUGH"
        case linkCardBrand = "LINK_CARD_BRAND"
        
        @_spi(STP) public var isPantherPayment: Bool {
            self == .linkCardBrand
        }
    }

    @_spi(STP) public let linkMode: LinkMode?

    /// Parses arbitrary `additionalParamters` into `ElementsContext`.
    @_spi(STP) public init(from additionalParameters: [String: Any]) {
        let linkMode: LinkMode? = {
            guard let linkMode = additionalParameters["link_mode"] as? String else {
                return nil
            }
            return LinkMode(rawValue: linkMode)
        }()

        self.linkMode = linkMode
    }
}
