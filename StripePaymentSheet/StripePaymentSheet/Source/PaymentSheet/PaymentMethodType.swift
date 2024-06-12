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
        case stripe(STPPaymentMethodType)
        case external(ExternalPaymentMethod)
        static var analyticLogForIcon: Set<PaymentMethodType> = []
        static let analyticLogForIconSemaphore = DispatchSemaphore(value: 1)

        var displayName: String {
            switch self {
            case .stripe(let paymentMethodType):
                return paymentMethodType.displayName
            case .external(let externalPaymentMethod):
                return externalPaymentMethod.label
            }
        }

        /// Returns the Stripe API value for the payment method type e.g. as it is represented on an Intent
        /// - Note: `STPPaymentMethodType.unknown` returns "unknown".
        var identifier: String {
            switch self {
            case .stripe(let paymentMethodType):
                return paymentMethodType.identifier
            case .external(let externalPaymentMethod):
                return externalPaymentMethod.type
            }
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
            // TODO(RUN_MOBILESDK-3167): Make this return a dynamic UIImage
            // TODO: Refactor this out of PaymentMethodType. Users shouldn't have to convert STPPaymentMethodType to PaymentMethodType in order to get its image.
            switch self {
            case .external(let paymentMethod):
                let url = forDarkBackground ? paymentMethod.darkImageUrl : paymentMethod.lightImageUrl
                return DownloadManager.sharedManager.downloadImage(
                    url: url ?? paymentMethod.lightImageUrl,
                    placeholder: nil,
                    updateHandler: updateHandler
                )
            case .stripe(let paymentMethodType):
                // Get the client-side asset first
                let localImage = paymentMethodType.makeImage(forDarkBackground: forDarkBackground)
                // Next, try to download the image from the spec if possible
                if
                    FormSpecProvider.shared.isLoaded,
                    let spec = FormSpecProvider.shared.formSpec(for: identifier),
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
                    // If there's a form spec, download the spec's image, using the local image as a placeholder until it loads
                    return DownloadManager.sharedManager.downloadImage(url: imageUrl, placeholder: localImage, updateHandler: updateHandler)
                } else if let localImage {
                    if PaymentSheet.PaymentMethodType.shouldLogAnalytic(paymentMethod: self) {
                        STPAnalyticsClient.sharedClient.logImageSelectorIconFromBundleIfNeeded(paymentMethod: self)
                    }
                    // If there's no form spec, return the local image if it exists
                    return localImage
                } else {
                    // If the local image doesn't exist and there's no form spec, fire an analytic and return an empty image
                    assertionFailure()
                    if PaymentSheet.PaymentMethodType.shouldLogAnalytic(paymentMethod: self) {
                        STPAnalyticsClient.sharedClient.logImageSelectorIconNotFoundIfNeeded(paymentMethod: self)
                    }
                    return DownloadManager.sharedManager.imagePlaceHolder()
                }
            }
        }

        var iconRequiresTinting: Bool {
            switch self {
            case .stripe(let stpPaymentMethodType):
                return stpPaymentMethodType.iconRequiresTinting
            case .external:
                return false
            }
        }

        /// Returns an ordered list of `PaymentMethodType`s to display to the customer in PaymentSheet.
        /// - Parameters:
        ///   - intent: An `intent` to extract `PaymentMethodType`s from.
        ///   - configuration: A `PaymentSheet` configuration.
        static func filteredPaymentMethodTypes(from intent: Intent, configuration: Configuration, logAvailability: Bool = false) -> [PaymentMethodType]
        {
            var recommendedStripePaymentMethodTypes = intent.recommendedPaymentMethodTypes

            if
                recommendedStripePaymentMethodTypes.contains(.link),
                !recommendedStripePaymentMethodTypes.contains(.USBankAccount),
                !intent.isDeferredIntent,
                intent.linkFundingSources?.contains(.bankAccount) == true
            {
                // we must add this BEFORE we do filtering via
                // `PaymentSheet.PaymentMethodType.supportsAdding`
                // because we want to filter out instant debits
                // IF the user has not linked Financial Connections
                recommendedStripePaymentMethodTypes.append(.instantDebits)
            }

            recommendedStripePaymentMethodTypes = recommendedStripePaymentMethodTypes.filter { paymentMethodType in
                let availabilityStatus = PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: paymentMethodType,
                    configuration: configuration,
                    intent: intent,
                    supportedPaymentMethods: PaymentSheet.supportedPaymentMethods
                )

                if logAvailability && availabilityStatus != .supported {
                    // This payment method is being filtered out, log the reason/s why
                    #if DEBUG
                    print("[Stripe SDK]: PaymentSheet could not offer \(paymentMethodType.displayName):\n\t* \(availabilityStatus.debugDescription)")
                    #endif
                }

                return availabilityStatus == .supported
            }

            // Log a warning if elements session doesn't contain all the merchant's desired external payment methods
            let missingExternalPaymentMethods = Set(configuration.externalPaymentMethodConfiguration?.externalPaymentMethods.map { $0.lowercased() } ?? [])
                .subtracting(Set(intent.elementsSession.externalPaymentMethods.map { $0.type }))
            if logAvailability && !missingExternalPaymentMethods.isEmpty {
                print("[Stripe SDK]: PaymentSheet could not offer these external payment methods: \(missingExternalPaymentMethods). See https://stripe.com/docs/payments/external-payment-methods#available-external-payment-methods")
            }

            // The full ordered list of recommended payment method types:
            var recommendedPaymentMethodTypes: [PaymentMethodType] =
                // Stripe PaymentMethod types
                recommendedStripePaymentMethodTypes.map { PaymentMethodType.stripe($0) }
                // External Payment Methods
                + intent.elementsSession.externalPaymentMethods.map { PaymentMethodType.external($0) }

            if let merchantPaymentMethodOrder = configuration.paymentMethodOrder?.map({ $0.lowercased() }) {
                // Order the payment methods according to the merchant's `paymentMethodOrder` configuration:
                var reorderedPaymentMethodTypes = [PaymentMethodType]()

                // 1. Add each PM in paymentMethodOrder first
                for pmIdentifier in merchantPaymentMethodOrder {
                    guard
                        // Ignore the PM if it's not in allPaymentMethodTypes
                        let index = recommendedPaymentMethodTypes.firstIndex(where: { $0.identifier == pmIdentifier }),
                        let paymentMethod = recommendedPaymentMethodTypes.stp_boundSafeObject(at: index),
                        // Ignore duplicate PMs
                        !reorderedPaymentMethodTypes.contains(paymentMethod)
                    else {
                        continue
                    }
                    // 2. Remove each PM we add from recommendedPaymentMethodTypes
                    recommendedPaymentMethodTypes.remove(at: index)
                    reorderedPaymentMethodTypes.append(paymentMethod)
                }
                // 3. Append the remaining PMs in recommendedPaymentMethodTypes
                reorderedPaymentMethodTypes.append(contentsOf: recommendedPaymentMethodTypes)
                return reorderedPaymentMethodTypes
            } else {
                return recommendedPaymentMethodTypes
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
            paymentMethod: STPPaymentMethodType,
            configuration: PaymentSheet.Configuration,
            intent: Intent,
            supportedPaymentMethods: [STPPaymentMethodType] = PaymentSheet.supportedPaymentMethods
        ) -> PaymentMethodAvailabilityStatus {
            let requirements: [PaymentMethodTypeRequirement]

            // We have different requirements depending on whether or not the intent is setting up the payment method for future use
            if intent.isSettingUp {
                requirements = {
                    switch paymentMethod {
                    case .card:
                        return []
                    case .payPal, .cashApp, .revolutPay, .amazonPay, .klarna:
                        return [.returnURL]
                    case .USBankAccount, .boleto:
                        return [.userSupportsDelayedPaymentMethods]
                    case .instantDebits:
                        return [.financialConnectionsSDK]
                    case .sofort, .iDEAL, .bancontact:
                        // n.b. While sofort, iDEAL, and bancontact are themselves not delayed, they turn into SEPA upon save, which IS delayed.
                        return [.returnURL, .userSupportsDelayedPaymentMethods]
                    case .SEPADebit, .AUBECSDebit:
                        return [.userSupportsDelayedPaymentMethods]
                    case .bacsDebit:
                        return [.returnURL, .userSupportsDelayedPaymentMethods]
                    case .cardPresent, .blik, .weChatPay, .grabPay, .FPX, .giropay, .przelewy24, .EPS,
                        .netBanking, .OXXO, .afterpayClearpay, .UPI, .link, .affirm, .paynow, .zip, .alma, .mobilePay, .unknown, .alipay, .konbini, .promptPay, .swish, .twint, .multibanco:
                        return [.unsupportedForSetup]
                    @unknown default:
                        return [.unsupportedForSetup]
                    }
                }()
            } else {
                requirements = {
                    switch paymentMethod {
                    case .blik, .card, .cardPresent, .UPI, .weChatPay, .paynow, .promptPay:
                        return []
                    case .alipay, .EPS, .FPX, .giropay, .grabPay, .netBanking, .payPal, .przelewy24, .klarna,
                            .bancontact, .iDEAL, .cashApp, .affirm, .zip, .revolutPay, .amazonPay, .alma, .mobilePay, .swish, .twint:
                        return [.returnURL]
                    case .USBankAccount:
                        return [
                            .userSupportsDelayedPaymentMethods, .financialConnectionsSDK,
                            .validUSBankVerificationMethod,
                        ]
                    case .instantDebits:
                        return [.financialConnectionsSDK]
                    case .OXXO, .boleto, .AUBECSDebit, .SEPADebit, .konbini, .multibanco:
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
                paymentMethod: paymentMethod,
                requirements: requirements,
                configuration: configuration,
                intent: intent,
                supportedPaymentMethods: supportedPaymentMethods
            )
        }

        /// Returns whether or not we can show a "☑️ Save for future use" checkbox to the customer
        func supportsSaveForFutureUseCheckbox() -> Bool {
            guard case let .stripe(paymentMethodType) = self else {
                // At the time of writing, we only support cards and us bank accounts.
                // These should both have an `stpPaymentMethodType`, so I'm avoiding handling this guard condition
                return false
            }
            // This payment method and its requirements are hardcoded on the client
            switch paymentMethodType {
            case .card, .USBankAccount:
                return true
            default:
                return false
            }
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
    /// Returns whether or not saved PaymentMethods of this type should be displayed as an option to customers
    /// This should only return true if saved PMs of this type can be successfully used to `/confirm` the given `intent`
    /// - Warning: This doesn't quite work as advertised. We've hardcoded `PaymentSheet+API.swift` to only fetch saved cards and us bank accounts.
    func supportsSavedPaymentMethod(configuration: PaymentSheet.Configuration, intent: Intent) -> Bool {
        let requirements: [PaymentMethodTypeRequirement] = {
            switch type {
            case .card:
                return []
            case .USBankAccount, .SEPADebit:
                return [.userSupportsDelayedPaymentMethods]
            default:
                return [.unsupportedForReuse]
            }
        }()
        return PaymentSheet.PaymentMethodType.configurationSupports(
            paymentMethod: type,
            requirements: requirements,
            configuration: configuration,
            intent: intent,
            supportedPaymentMethods: PaymentSheet.supportedPaymentMethods
        ) == .supported
    }
}

extension STPPaymentMethodParams {
    var paymentSheetLabel: String {
        switch type {
        case .unknown:
            assertionFailure()
            return rawTypeString ?? ""
        case .card:
            return "••••\(card?.last4 ?? "")"
        default:
            return label
        }
    }
}
