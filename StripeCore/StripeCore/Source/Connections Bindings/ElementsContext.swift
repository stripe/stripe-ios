//
//  ElementsContext.swift
//  StripeCore
//
//  Created by Mat Schmid on 2024-09-20.
//

import Foundation

@_spi(STP) public struct ElementsContext {
    @_spi(STP) public enum HostedSurface: String {
        case paymentsSheet = "payment_element"
        case customerSheet = "customer_sheet"
    }

    // The presentation surface for the Financial Connections sheet.
    @_spi(STP) public let hostedSurface: HostedSurface?

    // Parses arbitrary `additionalParamters` into `ElementsContext`.
    @_spi(STP) public init(from additionalParameters: [String: Any]) {
        let hostedSurface: HostedSurface? = {
            guard let hostedSurface = additionalParameters["hosted_surface"] as? String else {
                return nil
            }
            return HostedSurface(rawValue: hostedSurface)
        }()

        self.hostedSurface = hostedSurface
    }
}
