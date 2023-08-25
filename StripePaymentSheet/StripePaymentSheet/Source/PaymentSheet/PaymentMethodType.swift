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
    enum PaymentMethodType: Equatable, Hashable {

        func supportsAddingRequirements() -> [PaymentMethodTypeRequirement] {
            switch self {
            case .dynamic("revolut_pay"):
                return [.returnURL]
            case .dynamic("amazon_pay"):
                return [.returnURL]
            case .dynamic("mobilepay"):
                return [.returnURL]
            case .dynamic("zip"):
                return [.returnURL]
            default:
                return [.unsupported]
            }
        }

        func supportsSaveAndReuseRequirements() -> [PaymentMethodTypeRequirement] {
            switch self {
            default:
                return [.unsupportedForSetup]
            }
        }

        case card
        case USBankAccount
        case linkInstantDebit
        case link
        case dynamic(String)
        case UPI
        case cashApp
        case externalPayPal // TODO(yuki): Replace this when we support more EPMs
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
            case "external_paypal":
                self = .externalPayPal
            default:
                self = .dynamic(str)
            }
        }

        // I think this returns the Stripe PaymentMethod object type name i.e. a value in https://stripe.com/docs/api/payment_methods/object#payment_method_object-type
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
            case .externalPayPal:
                return nil
            }
        }
        var displayName: String {
            if let stpPaymentMethodType = stpPaymentMethodType {
                return stpPaymentMethodType.displayName
            } else if case .dynamic("revolut_pay") = self {
                return "Revolut Pay"
            } else if case .dynamic("mobilepay") = self {
                return "MobilePay"
            } else if case .dynamic("zip") = self {
                return "Zip"
            } else if case .dynamic("amazon_pay") = self {
                return "Amazon Pay"
            } else if case .dynamic(let name) = self {
                // TODO: We should introduce a display name in our model rather than presenting the payment method type
                return name
            } else if case .externalPayPal = self {
               return STPLocalizedString("PayPal", "Payment Method type brand name")
            }
            assertionFailure()
            return ""
        }

        /// The identifier for the payment method type as it is represented on an intent
        var identifier: String { // this should be renamed to analyticsIdentifier
            if let stpPaymentMethodType {
                return stpPaymentMethodType.identifier
            } else if case .dynamic(let name) = self {
                return name
            } else if case .externalPayPal = self {
                return "external_paypal"
            }

            assertionFailure()
            return ""
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
            if case .externalPayPal = self {
                return STPPaymentMethodType.payPal.makeImage(forDarkBackground: forDarkBackground)
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
            // We look at the raw `allResponseFields` because some strings may have been parsed into STPPaymentMethodType.unknown
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
            case .deferredIntent(let elementsSession, _):
                let paymentMethodPrefs = elementsSession.allResponseFields["payment_method_preference"] as? [AnyHashable: Any]
                let paymentTypesString =
                paymentMethodPrefs?["ordered_payment_method_types"] as? [String]
                    ?? []
                return paymentTypesString.map { PaymentMethodType(from: $0) }
            }
        }

        /// Extracts the recommended `PaymentMethodType`s from the given `intent` and filters out the ones that aren't supported by the given `configuration`.
        /// - Parameters:
        ///   - intent: An `intent` to extract `PaymentMethodType`s from.
        ///   - configuration: A `PaymentSheet` configuration.
        /// - Returns: An ordered list of `PaymentMethodType`s, including only the ones supported by this configuration.
        static func filteredPaymentMethodTypes(from intent: Intent, configuration: Configuration, logAvailability: Bool = false) -> [PaymentMethodType]
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

            return recommendedPaymentMethodTypes.filter { paymentMethodType in
                let availabilityStatus = PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: paymentMethodType,
                    configuration: configuration,
                    intent: intent,
                    supportedPaymentMethods: configuration.linkPaymentMethodsOnly
                        ? PaymentSheet.supportedLinkPaymentMethods : PaymentSheet.supportedPaymentMethods
                )

                if logAvailability && availabilityStatus != .supported {
                    // This payment method is being filtered out, log the reason/s why
                    #if DEBUG
                    print("[Stripe SDK]: PaymentSheet could not offer \(paymentMethodType.displayName):\n\t* \(availabilityStatus.debugDescription)")
                    #endif
                }

                return availabilityStatus == .supported
            }
        }

        /// Returns whether or not PaymentSheet should display the given `paymentMethod` as an option to the customer.
        /// Note: This doesn't affect the availability of saved PMs.
        /// - Parameters:
        ///   - paymentMethod: the `STPPaymentMethodType` in question
        ///   - requirementProviders: a list of [PaymentMethodRequirementProvider] who satisfy payment requirements
        ///   - intent: a intent object
        ///   - supportedPaymentMethods: the payment methods that PaymentSheet can display UI for
        /// - Returns: a `PaymentMethodAvailabilityStatus` detailing why or why not this payment method can be added
        static func supportsAdding(
            paymentMethod: PaymentMethodType,
            configuration: PaymentSheet.Configuration,
            intent: Intent,
            supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
        ) -> PaymentMethodAvailabilityStatus {
            guard let stpPaymentMethodType = paymentMethod.stpPaymentMethodType else {
                // if the payment method cannot be represented as a `STPPaymentMethodType` attempt to read it
                // as a dynamic payment method
                if case .dynamic = paymentMethod {
                    let requirements =
                        intent.isSettingUp
                        ? paymentMethod.supportsSaveAndReuseRequirements() : paymentMethod.supportsAddingRequirements()
                    return configurationSatisfiesRequirements(
                        requirements: requirements,
                        configuration: configuration,
                        intent: intent
                    )
                }

                return .notSupported
            }

            let requirements: [PaymentMethodTypeRequirement]

            // We have different requirements depending on whether or not the intent is setting up the payment method for future use
            if intent.isSettingUp {
                requirements = {
                    switch stpPaymentMethodType {
                    case .card:
                        return []
                    case .alipay, .payPal:
                        return [.returnURL]
                    case .USBankAccount:
                        return [.userSupportsDelayedPaymentMethods]
                    case .sofort, .iDEAL, .bancontact:
                        // n.b. While sofort, iDEAL and bancontact are themselves not delayed, they turn into SEPA upon save, which IS delayed.
                        return [.returnURL, .userSupportsDelayedPaymentMethods]
                        // n.b. While iDEAL and bancontact are themselves not delayed, they turn into SEPA upon save, which IS delayed.
                    case .SEPADebit:
                        return [.userSupportsDelayedPaymentMethods]
                    case .bacsDebit:
                        return [.returnURL, .userSupportsDelayedPaymentMethods]
                    case .AUBECSDebit, .cardPresent, .blik, .weChatPay, .grabPay, .FPX, .giropay, .przelewy24, .EPS,
                        .netBanking, .OXXO, .afterpayClearpay, .UPI, .boleto, .klarna, .link, .linkInstantDebit,
                        .affirm, .cashApp, .unknown:
                        return [.unsupportedForSetup]
                    @unknown default:
                        return [.unsupportedForSetup]
                    }
                }()
            } else {
                requirements = {
                    switch stpPaymentMethodType {
                    case .blik, .card, .cardPresent, .UPI, .weChatPay:
                        return []
                    case .alipay, .EPS, .FPX, .giropay, .grabPay, .netBanking, .payPal, .przelewy24, .klarna,
                            .linkInstantDebit, .bancontact, .iDEAL, .cashApp, .affirm:
                        return [.returnURL]
                    case .USBankAccount:
                        return [
                            .userSupportsDelayedPaymentMethods, .financialConnectionsSDK,
                            .validUSBankVerificationMethod,
                        ]
                    case .OXXO, .boleto, .AUBECSDebit, .SEPADebit:
                        return [.userSupportsDelayedPaymentMethods]
                    case .bacsDebit, .sofort:
                        return [.returnURL, .userSupportsDelayedPaymentMethods]
                    case .afterpayClearpay:
                        return [.returnURL, .shippingAddress]
                    case .link, .unknown:
                        return [.unsupported]
                    @unknown default:
                        return [.unsupported]
                    }
                }()
            }

            return configurationSupports(
                paymentMethod: stpPaymentMethodType,
                requirements: requirements,
                configuration: configuration,
                intent: intent,
                supportedPaymentMethods: supportedPaymentMethods
            )
            // TODO: We need a way to model this information in our common model
        }

        /// Returns whether or not we can show a "☑️ Save for future use" checkbox to the customer
        func supportsSaveForFutureUseCheckbox() -> Bool {
            guard let stpPaymentMethodType = stpPaymentMethodType else {
                // At the time of writing, we only support cards and us bank accounts.
                // These should both have an `stpPaymentMethodType`, so I'm avoiding handling this guard condition
                return false
            }
            // This payment method and its requirements are hardcoded on the client
            switch stpPaymentMethodType {
            case .card, .USBankAccount:
                return true
            default:
                return false
            }
        }

        /// Returns whether or not saved PaymentMethods of this type should be displayed as an option to customers
        /// This should only return true if saved PMs of this type can be successfully used to `/confirm` the given `intent`
        /// - Warning: This doesn't quite work as advertised. We've hardcoded `PaymentSheet+API.swift` to only fetch saved cards and us bank accounts.
        func supportsSavedPaymentMethod(configuration: Configuration, intent: Intent) -> Bool {
            guard let stpPaymentMethodType = stpPaymentMethodType else {
                // At the time of writing, we only support cards and us bank accounts.
                // These should both have an `stpPaymentMethodType`, so I'm avoiding handling this guard condition
                return false
            }
            let requirements: [PaymentMethodTypeRequirement] = {
                switch stpPaymentMethodType {
                case .card:
                    return []
                case .USBankAccount:
                    return [.userSupportsDelayedPaymentMethods]
                default:
                    return [.unsupportedForReuse]
                }
            }()
            return Self.configurationSupports(
                paymentMethod: stpPaymentMethodType,
                requirements: requirements,
                configuration: configuration,
                intent: intent,
                supportedPaymentMethods: PaymentSheet.supportedPaymentMethods
            ) == .supported
        }

        /// Returns true if the passed configuration satsifies the passed in `requirements`
        /// This function is to be used with dynamic payment method types that do not have bindings support and cannot be represented as a `STPPaymentMethodType`.
        /// It's required for the client to specfiy dynamic payment method type requirements (rather than being server driven) because dynamically delivering new LPMS to clients that don't know about them is no longer/currently a priority.
        /// - Note: Use this function over `configurationSupports` when the payment method does not have bindings support e.g. cannot be represented as
        /// a `STPPaymentMethodType`.
        /// - Parameters:
        ///   - requirements: a list of requirements to be satisfied
        ///   - configuration: a configuration to satisfy requirements
        ///   - intent: an intent object
        /// - Returns: a `PaymentMethodAvailabilityStatus` detailing why or why not this payment method can be added
        static func configurationSatisfiesRequirements(
            requirements: [PaymentMethodTypeRequirement],
            configuration: PaymentSheet.Configuration,
            intent: Intent
        ) -> PaymentMethodAvailabilityStatus {
            let fulfilledRequirements = [configuration, intent].reduce([]) {
                (accumulator: [PaymentMethodTypeRequirement], element: PaymentMethodRequirementProvider) in
                return accumulator + element.fulfilledRequirements
            }
            let supports = Set(requirements).isSubset(of: fulfilledRequirements)
            if !supports {
                let missingRequirements = Set(requirements).subtracting(fulfilledRequirements)
                return .missingRequirements(missingRequirements)
            }

            return .supported
        }

        /// Returns true if the passed configuration satisfies the passed in `requirements` and this payment method is in the list of supported payment methods
        /// This function is to be used with payment method types thar have bindings support and can be represented as a `STPPaymentMethodType`
        /// Use this function over `configurationSatisfiesRequirements` when the payment method in quesiton can be represented as a `STPPaymentMethodType`
        /// - Parameters:
        ///   - paymentMethod: the payment method type in question
        ///   - requirements: a list of requirements to be satisfied
        ///   - configuration: a configuration to satisfy requirements
        ///   - intent: an intent object
        ///   - supportedPaymentMethods: a list of supported payment method types
        /// - Returns: a `PaymentMethodAvailabilityStatus` detailing why or why not this payment method is supported
        static func configurationSupports(
            paymentMethod: STPPaymentMethodType,
            requirements: [PaymentMethodTypeRequirement],
            configuration: PaymentSheet.Configuration,
            intent: Intent,
            supportedPaymentMethods: [STPPaymentMethodType]
        ) -> PaymentMethodAvailabilityStatus {
            guard supportedPaymentMethods.contains(paymentMethod) else {
                return .notSupported
            }

            // Hide a payment method type if we are in live mode and it is unactivated
            if !configuration.apiClient.isTestmode && intent.unactivatedPaymentMethodTypes.contains(paymentMethod) {
                return .unactivated
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

            if !supports {
                let missingRequirements = Set(requirements).subtracting(fulfilledRequirements)
                return .missingRequirements(missingRequirements)
            }

            return .supported
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
                return paymentMethodType.displayName
            } else {
                return label
            }
        }
    }
}
