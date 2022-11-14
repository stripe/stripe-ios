//
//  PaymentMethodType.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

extension PaymentSheet {
    public enum PaymentMethodType: Equatable, Hashable {

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
        case UPI
        static var analyticLogForIcon: Set<PaymentMethodType> = []
        static let analyticLogForIconSemaphore = DispatchSemaphore(value: 1)

        public init(from str: String) {
            switch(str) {
            case STPPaymentMethod.string(from: .card):
                self = .card
            case STPPaymentMethod.string(from: .USBankAccount):
                self = .USBankAccount
            case STPPaymentMethod.string(from: .link):
                self = .link
            case STPPaymentMethod.string(from: .UPI):
                self  = .UPI
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
            case .UPI:
                return STPPaymentMethod.string(from: .UPI)
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

        var paymentSheetLabel: String {
            assertionFailure()
            return "Unknown"
        }

        static func shouldLogAnalytic(paymentMethod: PaymentSheet.PaymentMethodType) -> Bool {
            analyticLogForIconSemaphore.wait()
            defer { analyticLogForIconSemaphore.signal() }
            guard !analyticLogForIcon.contains(paymentMethod) else { return false }
            analyticLogForIcon.insert(paymentMethod)
            return true
        }

        /// makeImage will immediately return an UImage that is either the image or a placeholder.
        /// If the image is immediately available, the updateHandler will not be called.
        /// If the image is not immediately available, the updateHandler will be called if we are able
        /// to download the image.
        func makeImage(forDarkBackground: Bool = false, updateHandler: DownloadManager.UpdateImageHandler?) -> UIImage {
            if case .dynamic(let name) = self,
               let spec = FormSpecProvider.shared.formSpec(for: name),
               let selectorIcon = spec.selectorIcon,
               var imageUrl = URL(string: selectorIcon.lightThemePng) {
                if forDarkBackground,
                   let darkImageString = selectorIcon.darkThemePng,
                   let darkImageUrl = URL(string: darkImageString) {
                    imageUrl = darkImageUrl
                }
                if PaymentSheet.PaymentMethodType.shouldLogAnalytic(paymentMethod: self) {
                    STPAnalyticsClient.sharedClient.logImageSelectorIconDownloadedIfNeeded(paymentMethod: self)
                }
                return DownloadManager.sharedManager.downloadImage(url: imageUrl, updateHandler: updateHandler)
            }
            if let stpPaymentMethodType = stpPaymentMethodType {
                if PaymentSheet.PaymentMethodType.shouldLogAnalytic(paymentMethod: self) {
                    STPAnalyticsClient.sharedClient.logImageSelectorIconFromBundleIfNeeded(paymentMethod: self)
                }
                return stpPaymentMethodType.makeImage(forDarkBackground: forDarkBackground)
            }
            if PaymentSheet.PaymentMethodType.shouldLogAnalytic(paymentMethod: self) {
                STPAnalyticsClient.sharedClient.logImageSelectorIconNotFoundIfNeeded(paymentMethod: self)
            }
            return DownloadManager.sharedManager.imagePlaceHolder()
        }

        var iconRequiresTinting: Bool {
            if let stpPaymentMethodType = stpPaymentMethodType {
                return stpPaymentMethodType.iconRequiresTinting
            }
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
        
        /// Extracts all the recommended `PaymentMethodType`s from the given `intent`.
        /// - Parameter intent: The `intent` to extract `PaymentMethodType`s from.
        /// - Returns: An ordered list of all the `PaymentMethodType`s for this `intent`.
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
        
        /// Extracts the recommended `PaymentMethodType`s from the given `intent` and filters out the ones that aren't supported by the given `configuration`.
        /// - Parameters:
        ///   - intent: An `intent` to extract `PaymentMethodType`s from.
        ///   - configuration: A `PaymentSheet` configuration.
        /// - Returns: An ordered list of `PaymentMethodType`s, including only the ones supported by this configuration.
        static func filteredPaymentMethodTypes(from intent: Intent, configuration: Configuration) -> [PaymentMethodType] {
            var recommendedPaymentMethodTypes = Self.recommendedPaymentMethodTypes(from: intent)
            if configuration.linkPaymentMethodsOnly {
                // If we're in the Link modal, manually add instant debit
                // as an option and let the support calls decide if it's allowed
                recommendedPaymentMethodTypes.append(.linkInstantDebit)
            }

            let paymentTypes = recommendedPaymentMethodTypes.filter {
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: $0,
                    configuration: configuration,
                    intent: intent,
                    supportedPaymentMethods: configuration.linkPaymentMethodsOnly ?
                        PaymentSheet.supportedLinkPaymentMethods : PaymentSheet.supportedPaymentMethods
                )
            }

            let serverFilteredPaymentMethods = Self.recommendedPaymentMethodTypes(
                from: intent
            ).filter({$0 != .USBankAccount && $0 != .link})
            let paymentTypesFiltered = paymentTypes.filter({$0 != .USBankAccount && $0 != .link})
            if serverFilteredPaymentMethods != paymentTypesFiltered {
                let result = serverFilteredPaymentMethods.symmetricDifference(paymentTypes)
                STPAnalyticsClient.sharedClient.logClientFilteredPaymentMethods(clientFilteredPaymentMethods: result.stringList())
            } else {
                STPAnalyticsClient.sharedClient.logClientFilteredPaymentMethodsNone()
            }
            return paymentTypes
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
                let dict = allResponseFields.stp_dictionaryByRemovingNulls()
                let paymentMethodType = dict.stp_string(forKey: "type") ?? ""
                return .dynamic(paymentMethodType)
            }
        }
    }
}
extension STPPaymentMethodParams {
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
            } else if let rawTypeString = rawTypeString {
                return .dynamic(rawTypeString)
            } else {
                assert(false, "Decoding error for STPPaymentMethodParams")
                return .dynamic("unknown")
            }
        }
    }
    var paymentSheetLabel: String {
        switch type {
        case .card:
            return "••••\(card?.last4 ?? "")"
        default:
            if self.type == .unknown, let rawTypeString = rawTypeString {
                let paymentMethodType = PaymentSheet.PaymentMethodType(from: rawTypeString)
                return paymentMethodType.paymentSheetLabel
            } else {
                return label
            }
        }
    }
}

extension Array where Element == PaymentSheet.PaymentMethodType {
    func stringList() -> String {
        var stringList: [String] = []
        for paymentType in self {
            let type = PaymentSheet.PaymentMethodType.string(from: paymentType) ?? "unknown"
            stringList.append(type)
        }
        guard let data = try? JSONSerialization.data(withJSONObject: stringList, options: []) else {
            return "[]"
        }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
    func symmetricDifference(_ other: Array) -> Array where Element == PaymentSheet.PaymentMethodType {
        let set1 = Set(self)
        let set2 = Set(other)
        return Array(set1.symmetricDifference(set2))
    }
}
