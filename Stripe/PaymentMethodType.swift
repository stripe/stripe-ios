//
//  PaymentSheetPaymentMethodType.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
extension PaymentSheet {
    public enum PaymentMethodType: Equatable {

        func supportsAddingRequirements() -> [PaymentMethodTypeRequirement] {
            switch(self) {
            default:
                return [.unavailable]
            }
        }

        func supportsSaveAndReuseRequirements() -> [PaymentMethodTypeRequirement] {
            switch(self) {
            default:
                return [.unavailable]
            }
        }

        case card
        case USBankAccount
        case linkInstantDebit
        case link
        case dynamic(String)

        public init(from str: String) {
            switch(str) {
            case STPPaymentMethod.string(from: .card):
                self = .card
            case STPPaymentMethod.string(from: .USBankAccount):
                self = .USBankAccount
            case STPPaymentMethod.string(from: .link):
                self = .link
            default:
                self = .dynamic(str)
            }
        }

        static func string(from type: PaymentMethodType) -> String? {
            switch(type) {
            case .card:
                return STPPaymentMethod.string(from: .card)
            case .USBankAccount:
                return STPPaymentMethod.string(from: .USBankAccount)
            case .link:
                return STPPaymentMethod.string(from: .link)
            case .linkInstantDebit:
                return nil
            case .dynamic(let str):
                return str
            }
        }
        var displayName: String {
            if let stpPaymentMethodType = stpPaymentMethodType {
                return stpPaymentMethodType.displayName
            } else if case .dynamic(let name) = self {
                //TODO: We should introduce a display name in our model rather than presenting the payment method type
                return name
            }
            assertionFailure()
            return ""
        }

        func makeImage(forDarkBackground: Bool = false) -> UIImage {
            if let stpPaymentMethodType = stpPaymentMethodType {
                return stpPaymentMethodType.makeImage(forDarkBackground: forDarkBackground)
            }
            // TODO: We need a way to model this information in our common model, but can default as a bank now
            return STPPaymentMethodType.USBankAccount.makeImage(forDarkBackground: forDarkBackground)
        }

        var iconRequiresTinting: Bool {
            if let stpPaymentMethodType = stpPaymentMethodType {
                return stpPaymentMethodType.iconRequiresTinting
            }
            // TODO: We need a way to model this information in our common model
            return false
        }

        var stpPaymentMethodType: STPPaymentMethodType? {
            guard self != .linkInstantDebit else {
                return .linkInstantDebit
            }
            guard let stringForm = PaymentMethodType.string(from: self) else {
                return nil
            }
            let paymentMethodType = STPPaymentMethod.type(from: stringForm)
            guard paymentMethodType != .unknown else {
                return nil
            }
            return paymentMethodType
        }

        static func recommendedPaymentMethodTypes(from intent: Intent) -> [PaymentMethodType] {
            switch(intent) {
            case .paymentIntent(let paymentIntent):
                guard let paymentMethodTypeStrings = paymentIntent.allResponseFields["payment_method_types"] as? [String] else {
                    return []
                }
                let paymentTypesString = paymentIntent.allResponseFields["ordered_payment_method_types"] as? [String] ?? paymentMethodTypeStrings
                return paymentTypesString.map{ PaymentMethodType(from: $0) }
            case .setupIntent(let setupIntent):
                guard let paymentMethodTypeStrings = setupIntent.allResponseFields["payment_method_types"] as? [String] else {
                    return []
                }
                let paymentTypesString = setupIntent.allResponseFields["ordered_payment_method_types"] as? [String] ?? paymentMethodTypeStrings
                return paymentTypesString.map{ PaymentMethodType(from: $0) }
            }
        }

        static func supportsAdding(
            paymentMethod: PaymentMethodType,
            configuration: PaymentSheet.Configuration,
            intent: Intent,
            supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
        ) -> Bool {
            if let stpPaymentMethodType = paymentMethod.stpPaymentMethodType {
                return PaymentSheet.supportsAdding(paymentMethod: stpPaymentMethodType,
                                                   configuration: configuration,
                                                   intent: intent,
                                                   supportedPaymentMethods: supportedPaymentMethods)
            } else if case .dynamic = paymentMethod {
                return supports(requirements: paymentMethod.supportsAddingRequirements(),
                                configuration: configuration,
                                intent: intent)
            }
            // TODO: We need a way to model this information in our common model
            return false
        }

        static func supportsSaveAndReuse(
            paymentMethod: PaymentMethodType,
            configuration: PaymentSheet.Configuration,
            intent: Intent,
            supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
        ) -> Bool {
            if let stpPaymentMethodType = paymentMethod.stpPaymentMethodType {
                return PaymentSheet.supportsSaveAndReuse(paymentMethod: stpPaymentMethodType,
                                                         configuration: configuration,
                                                         intent: intent,
                                                         supportedPaymentMethods: supportedPaymentMethods)
            } else if case .dynamic = paymentMethod {
                return supports(requirements: paymentMethod.supportsSaveAndReuseRequirements(),
                                configuration: configuration,
                                intent: intent)
            }
            // TODO: We need a way to model this information in our common model
            return false
        }

        static func supports(requirements: [PaymentMethodTypeRequirement],
                             configuration: PaymentSheet.Configuration,
                             intent: Intent) -> Bool {
            let fulfilledRequirements = [configuration, intent].reduce([]) {
                (accumulator: [PaymentMethodTypeRequirement], element: PaymentMethodRequirementProvider) in
                return accumulator + element.fulfilledRequirements
            }
            let supports = Set(requirements).isSubset(of: fulfilledRequirements)
            return supports
        }
    }
}
extension STPPaymentMethod {
    func paymentSheetPaymentMethodType() -> PaymentSheet.PaymentMethodType {
        switch(self.type) {
        case .card:
            return .card
        case .USBankAccount:
            return .USBankAccount
        case .link:
            return .link
        case .linkInstantDebit:
            return .linkInstantDebit
        default:
            if let str = STPPaymentMethod.string(from: self.type) {
                return .dynamic(str)
            } else {
                let dict = (allResponseFields as NSDictionary).stp_dictionaryByRemovingNulls() as NSDictionary
                let paymentMethodType = dict.stp_string(forKey: "type") ?? ""
                return .dynamic(paymentMethodType)
            }
        }
    }
}
