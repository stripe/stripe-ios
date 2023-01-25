//
//  PaymentMethodType.swift
//  StripePaymentSheet
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension PaymentSheet {
    public enum PaymentMethodType: Equatable, Hashable {

        func supportsAddingRequirements() -> [PaymentMethodTypeRequirement] {
            switch self {
            case .dynamic("revolut_pay"):
                return [.returnURL]
            case .dynamic("mobilepay"):
                return [.returnURL]
            default:
                return [.unavailable]
            }
        }

        func supportsSaveAndReuseRequirements() -> [PaymentMethodTypeRequirement] {
            switch self {
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
        case cashApp
        static var analyticLogForIcon: Set<PaymentMethodType> = []
        static let analyticLogForIconSemaphore = DispatchSemaphore(value: 1)

        public init(from str: String) {
            switch str {
            case STPPaymentMethod.string(from: .card):
                self = .card
            case STPPaymentMethod.string(from: .USBankAccount):
                self = .USBankAccount
            case STPPaymentMethod.string(from: .link):
                self = .link
            case STPPaymentMethod.string(from: .UPI):
                self = .UPI
            case STPPaymentMethod.string(from: .cashApp):
                self = .cashApp
            default:
                self = .dynamic(str)
            }
        }

        static func string(from type: PaymentMethodType) -> String? {
            switch type {
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
            case .cashApp:
                return STPPaymentMethod.string(from: .cashApp)
            case .dynamic(let str):
                return str
            }
        }
        var displayName: String {
            if let stpPaymentMethodType = stpPaymentMethodType {
                return stpPaymentMethodType.displayName
            } else if case .dynamic("revolut_pay") = self {
                return "Revolut Pay"
            } else if case .dynamic("mobilepay") = self {
                return "MobilePay"
            } else if case .dynamic(let name) = self {
                // TODO: We should introduce a display name in our model rather than presenting the payment method type
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
                var imageUrl = URL(string: selectorIcon.lightThemePng)
            {
                if forDarkBackground,
                    let darkImageString = selectorIcon.darkThemePng,
                    let darkImageUrl = URL(string: darkImageString)
                {
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
            switch intent {
            case .paymentIntent(let paymentIntent):
                guard
                    let paymentMethodTypeStrings = paymentIntent.allResponseFields["payment_method_types"] as? [String]
                else {
                    return []
                }
                let paymentTypesString =
                    paymentIntent.allResponseFields["ordered_payment_method_types"] as? [String]
                    ?? paymentMethodTypeStrings
                return paymentTypesString.map { PaymentMethodType(from: $0) }
            case .setupIntent(let setupIntent):
                guard let paymentMethodTypeStrings = setupIntent.allResponseFields["payment_method_types"] as? [String]
                else {
                    return []
                }
                let paymentTypesString =
                    setupIntent.allResponseFields["ordered_payment_method_types"] as? [String]
                    ?? paymentMethodTypeStrings
                return paymentTypesString.map { PaymentMethodType(from: $0) }
            }
        }

        /// Extracts the recommended `PaymentMethodType`s from the given `intent` and filters out the ones that aren't supported by the given `configuration`.
        /// - Parameters:
        ///   - intent: An `intent` to extract `PaymentMethodType`s from.
        ///   - configuration: A `PaymentSheet` configuration.
        /// - Returns: An ordered list of `PaymentMethodType`s, including only the ones supported by this configuration.
        static func filteredPaymentMethodTypes(from intent: Intent, configuration: Configuration) -> [PaymentMethodType]
        {
            var recommendedPaymentMethodTypes = Self.recommendedPaymentMethodTypes(from: intent)
            if configuration.linkPaymentMethodsOnly {
                // If we're in the Link modal, manually add Link payment methods
                // and let the support calls decide if they're allowed
                let allLinkPaymentMethods: [PaymentMethodType] = [.card, .linkInstantDebit]
                for method in allLinkPaymentMethods where !recommendedPaymentMethodTypes.contains(method) {
                    recommendedPaymentMethodTypes.append(method)
                }
            }

            let paymentTypes = recommendedPaymentMethodTypes.filter {
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: $0,
                    configuration: configuration,
                    intent: intent,
                    supportedPaymentMethods: configuration.linkPaymentMethodsOnly
                        ? PaymentSheet.supportedLinkPaymentMethods : PaymentSheet.supportedPaymentMethods
                )
            }

            let serverFilteredPaymentMethods = Self.recommendedPaymentMethodTypes(
                from: intent
            ).filter({ $0 != .USBankAccount && $0 != .link })
            let paymentTypesFiltered = paymentTypes.filter({ $0 != .USBankAccount && $0 != .link })
            if serverFilteredPaymentMethods != paymentTypesFiltered {
                let result = serverFilteredPaymentMethods.symmetricDifference(paymentTypes)
                STPAnalyticsClient.sharedClient.logClientFilteredPaymentMethods(
                    clientFilteredPaymentMethods: result.stringList()
                )
            } else {
                STPAnalyticsClient.sharedClient.logClientFilteredPaymentMethodsNone()
            }
            return paymentTypes
        }

        /// Returns whether or not PaymentSheet, with the given `PaymentMethodRequirementProvider`s, should make the given `paymentMethod` available to add.
        /// Note: This doesn't affect the availability of saved PMs.
        /// - Parameters:
        ///   - paymentMethod: the `STPPaymentMethodType` in question
        ///   - requirementProviders: a list of [PaymentMethodRequirementProvider] who satisfy payment requirements
        ///   - intent: a intent object
        ///   - supportedPaymentMethods: the payment methods that PaymentSheet can display UI for
        /// - Returns: true if `paymentMethod` should be available in the PaymentSheet, false otherwise
        static func supportsAdding(
            paymentMethod: PaymentMethodType,
            configuration: PaymentSheet.Configuration,
            intent: Intent,
            supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
        ) -> Bool {
            guard let stpPaymentMethodType = paymentMethod.stpPaymentMethodType else {
                if case .dynamic = paymentMethod {
                    return supports(
                        requirements: paymentMethod.supportsAddingRequirements(),
                        configuration: configuration,
                        intent: intent
                    )
                }

                return false
            }

            switch intent {
            case .paymentIntent(let paymentIntent):
                if paymentIntent.setupFutureUsage != .none {
                    fallthrough
                }
            case .setupIntent:
                return supportsSaveAndReuse(
                    paymentMethod: paymentMethod,
                    configuration: configuration,
                    intent: intent
                )
            }

            let requirements: [PaymentMethodTypeRequirement] = {
                switch stpPaymentMethodType {
                case .blik, .card, .cardPresent, .UPI, .weChatPay:
                    return []
                case .alipay, .EPS, .FPX, .giropay, .grabPay, .netBanking, .payPal, .przelewy24, .klarna,
                    .linkInstantDebit, .bancontact, .iDEAL, .cashApp:
                    return [.returnURL]
                case .USBankAccount:
                    return [
                        .userSupportsDelayedPaymentMethods, .financialConnectionsSDK, .validUSBankVerificationMethod,
                    ]
                case .OXXO, .boleto, .AUBECSDebit, .SEPADebit:
                    return [.userSupportsDelayedPaymentMethods]
                case .bacsDebit, .sofort:
                    return [.returnURL, .userSupportsDelayedPaymentMethods]
                case .afterpayClearpay, .affirm:
                    return [.returnURL, .shippingAddress]
                case .link, .unknown:
                    return [.unavailable]
                @unknown default:
                    return [.unavailable]
                }
            }()

            return supports(
                paymentMethod: stpPaymentMethodType,
                requirements: requirements,
                configuration: configuration,
                intent: intent,
                supportedPaymentMethods: supportedPaymentMethods
            )
            // TODO: We need a way to model this information in our common model
        }

        /// Returns whether or not PaymentSheet should make the given `paymentMethod` available to save for future use, set up, and reuse
        /// i.e. available for a PaymentIntent with setupFutureUsage or SetupIntent or saved payment method
        /// - Parameters:
        ///   - paymentMethod: the `STPPaymentMethodType` in question
        ///   - requirementProviders: a list of [PaymentMethodRequirementProvider] who satisfy payment requirements
        ///   - intent: a intent object
        ///   - supportedPaymentMethods: the payment methods that PaymentSheet can display UI for
        /// - Returns: true if `paymentMethod` should be available in the PaymentSheet, false otherwise
        static func supportsSaveAndReuse(
            paymentMethod: PaymentMethodType,
            configuration: PaymentSheet.Configuration,
            intent: Intent,
            supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
        ) -> Bool {
            guard let stpPaymentMethodType = paymentMethod.stpPaymentMethodType else {
                if case .dynamic = paymentMethod {
                    return supports(
                        requirements: paymentMethod.supportsSaveAndReuseRequirements(),
                        configuration: configuration,
                        intent: intent
                    )
                }

                return false
            }

            let requirements: [PaymentMethodTypeRequirement] = {
                switch stpPaymentMethodType {
                case .card:
                    return []
                case .alipay:
                    return [.returnURL]
                case .USBankAccount:
                    return [.userSupportsDelayedPaymentMethods]
                case .iDEAL, .bancontact, .sofort:
                    // SEPA-family PMs are disallowed until we can reuse them for PI+sfu and SI.
                    // n.b. While iDEAL and bancontact are themselves not delayed, they turn into SEPA upon save, which IS delayed.
                    return [.returnURL, .userSupportsDelayedPaymentMethods, .unavailable]
                case .SEPADebit:
                    // SEPA-family PMs are disallowed until we can reuse them for PI+sfu and SI.
                    return [.userSupportsDelayedPaymentMethods, .unavailable]
                case .bacsDebit:
                    return [.returnURL, .userSupportsDelayedPaymentMethods]
                case .AUBECSDebit, .cardPresent, .blik, .weChatPay, .grabPay, .FPX, .giropay, .przelewy24, .EPS,
                    .netBanking, .OXXO, .afterpayClearpay, .payPal, .UPI, .boleto, .klarna, .link, .linkInstantDebit,
                    .affirm, .cashApp, .unknown:
                    return [.unavailable]
                @unknown default:
                    return [.unavailable]
                }
            }()

            return supports(
                paymentMethod: stpPaymentMethodType,
                requirements: requirements,
                configuration: configuration,
                intent: intent,
                supportedPaymentMethods: supportedPaymentMethods
            )

            // TODO: We need a way to model this information in our common model
        }

        static func supports(
            requirements: [PaymentMethodTypeRequirement],
            configuration: PaymentSheet.Configuration,
            intent: Intent
        ) -> Bool {
            let fulfilledRequirements = [configuration, intent].reduce([]) {
                (accumulator: [PaymentMethodTypeRequirement], element: PaymentMethodRequirementProvider) in
                return accumulator + element.fulfilledRequirements
            }
            let supports = Set(requirements).isSubset(of: fulfilledRequirements)
            return supports
        }

        /// DRY helper method
        static func supports(
            paymentMethod: STPPaymentMethodType,
            requirements: [PaymentMethodTypeRequirement],
            configuration: PaymentSheet.Configuration,
            intent: Intent,
            supportedPaymentMethods: [STPPaymentMethodType]
        ) -> Bool {
            guard supportedPaymentMethods.contains(paymentMethod) else {
                return false
            }

            // Hide a payment method type if we are in live mode and it is unactivated
            if !configuration.apiClient.isTestmode && intent.unactivatedPaymentMethodTypes.contains(paymentMethod) {
                return false
            }

            let fulfilledRequirements = [configuration, intent].reduce([]) {
                (accumulator: [PaymentMethodTypeRequirement], element: PaymentMethodRequirementProvider) in
                return accumulator + element.fulfilledRequirements
            }

            let supports = Set(requirements).isSubset(of: fulfilledRequirements)
            if paymentMethod == .USBankAccount {
                if !fulfilledRequirements.contains(.financialConnectionsSDK) {
                    print(
                        "[Stripe SDK] Warning: us_bank_account requires the StripeConnections SDK. See https://stripe.com/docs/payments/ach-debit/accept-a-payment?platform=ios"
                    )
                }
            }

            return supports
        }
    }
}
extension STPPaymentMethod {
    func paymentSheetPaymentMethodType() -> PaymentSheet.PaymentMethodType {
        switch self.type {
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
        switch self.type {
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
