//
//  PaymentSheet+PaymentMethodAvailability.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 9/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

extension PaymentSheet {
    
    /// An unordered list of paymentMethod types that can be used with PaymentSheet
    /// - Note: This is a var so that we can enable experimental payment methods in PaymentSheetTestPlayground.
    /// Modifying this property in a production app can lead to unexpected behavior.
    ///
    /// :nodoc:
    @_spi(STP) public static var supportedPaymentMethods: [STPPaymentMethodType] = [.card, .iDEAL]

    /// Returns whether or not PaymentSheet, with the given `PaymentMethodRequirementProvider`s, should make the given `paymentMethod` available to add.
    /// Note: This doesn't affect the availability of saved PMs.
    /// - Parameters:
    ///   - paymentMethod: the `STPPaymentMethodType` in question
    ///   - requirementProviders: a list of [PaymentMethodRequirementProvider] who satisfy payment requirements
    ///   - supportedPaymentMethods: the current list of supported payment methods in PaymentSheet
    /// - Returns: true if `paymentMethod` should be available in the PaymentSheet, false otherwise
    static func supportsAdding(
        paymentMethod: STPPaymentMethodType,
        with requirementProviders: [PaymentMethodRequirementProvider],
        supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
    ) -> Bool {
        guard supportedPaymentMethods.contains(paymentMethod) else {
            return false
        }
        
        let fulfilledRequirements = requirementProviders.reduce(Set<STPPaymentMethodType.PaymentMethodTypeRequirement>()) {accumulator, element in
            return accumulator.union(element.fufilledRequirements)
        }
        return Set(paymentMethod.requirements).isSubset(of: fulfilledRequirements)
    }
    
    /// Returns whether or not PaymentSheet should make the given `paymentMethod` available to save / set up / reuse for future use.
    /// i.e. available for a PaymentIntent with setupFutureUsage or SetupIntent
    static func supportsReusing(paymentMethod: STPPaymentMethodType) -> Bool {
        // Only allow the saving/setup/reuse of cards. SEPA-family PMs are disallowed until we can reuse them for PI+sfu and SI.
        return [.card].contains(paymentMethod)
    }
}

// MARK: - PaymentMethodRequirementProvider

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
            // Shipping address
            if let shippingInfo = paymentIntent.shipping {
                if shippingInfo.name != nil,
                   shippingInfo.address?.line1 != nil,
                   shippingInfo.address?.city != nil,
                   shippingInfo.address?.state != nil,
                   shippingInfo.address?.country != nil,
                   shippingInfo.address?.postalCode != nil {
                    reqs.insert(.shippingAddress)
                }
            }
            
            // Not setting up
            if paymentIntent.setupFutureUsage == .none {
                reqs.insert(.notSettingUp)
            }
            return reqs
        case .setupIntent:
            return Set<STPPaymentMethodType.PaymentMethodTypeRequirement>()
        }
    }
}
