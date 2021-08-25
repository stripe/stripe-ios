//
//  PaymentRequirementProvider.swift
//  StripeiOS
//
//  Created by Nick Porter on 8/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

/// Defines an instance type who provides a set of `PaymentMethodTypeRequirement` it satisfies
protocol PaymentMethodRequirementProvider {
    
    /// The set of payment requirements provided by this instance
    var fufilledRequirements: Set<STPPaymentMethodType.PaymentMethodTypeRequirement> { get }
}


extension PaymentSheet.Configuration: PaymentMethodRequirementProvider {
    var fufilledRequirements: Set<STPPaymentMethodType.PaymentMethodTypeRequirement> {
        var reqs = Set<STPPaymentMethodType.PaymentMethodTypeRequirement>()
        if returnURL != nil { reqs.insert(.returnURL) }
        return reqs
    }
}

extension Intent: PaymentMethodRequirementProvider {
    var fufilledRequirements: Set<STPPaymentMethodType.PaymentMethodTypeRequirement> {
        switch self {
        case let .paymentIntent(paymentIntent):
            var reqs = Set<STPPaymentMethodType.PaymentMethodTypeRequirement>()
            guard let shippingInfo = paymentIntent.shipping else { return reqs }
            
            if shippingInfo.name != nil,
               shippingInfo.address?.line1 != nil,
               shippingInfo.address?.city != nil,
               shippingInfo.address?.state != nil,
               shippingInfo.address?.country != nil,
               shippingInfo.address?.postalCode != nil {
                reqs.insert(.shippingAddress)
            }
            return reqs
        case .setupIntent:
            return Set<STPPaymentMethodType.PaymentMethodTypeRequirement>()
        }
    }
}
