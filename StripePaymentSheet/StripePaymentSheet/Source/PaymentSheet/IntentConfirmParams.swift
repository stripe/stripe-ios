//
//  IntentConfirmParams.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 3/28/23.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

/// An internal type representing both `STPPaymentIntentConfirmParams` and `STPSetupIntentConfirmParams`
/// - Note: Assumes you're confirming with a new payment method, unless a payment method ID is provided
final class IntentConfirmParams {
    /// An enum for the three possible states of the e.g. "Save this card for future payments" checkbox
    enum SaveForFutureUseCheckboxState {
        /// The checkbox wasn't displayed
        case hidden
        /// The checkbox was displayed and selected
        case selected
        /// The checkbox was displayed and deselected
        case deselected
    }

    let paymentMethodParams: STPPaymentMethodParams
    let paymentMethodType: PaymentSheet.PaymentMethodType
    /// ⚠️ Usage of this is *not compatible* with server-side confirmation!
    let confirmPaymentMethodOptions: STPConfirmPaymentMethodOptions

    /// True if the customer opts to save their payment method for future payments.
    var saveForFutureUseCheckboxState: SaveForFutureUseCheckboxState = .hidden
    /// If `true`, a mandate (e.g. "By continuing you authorize Foo Corp to use your payment details for recurring payments...") was displayed to the customer.
    var didDisplayMandate: Bool = false

    var financialConnectionsLinkedBank: FinancialConnectionsLinkedBank?
    var instantDebitsLinkedBank: InstantDebitsLinkedBank?

    var paymentSheetLabel: String {
        if let last4 = (financialConnectionsLinkedBank?.last4 ?? instantDebitsLinkedBank?.last4) {
            return "••••\(last4)"
        } else {
            return paymentMethodParams.paymentSheetLabel
        }
    }

    var expandedPaymentSheetLabel: String {
        switch paymentMethodType {
        case .stripe(let stpPaymentMethodType):
            switch stpPaymentMethodType {
            case .card:
                let brand = STPCardValidator.brand(for: paymentMethodParams.card)
                return STPCardBrandUtilities.stringFrom(brand) ?? STPPaymentMethodType.card.displayName
            case .USBankAccount:
                // Use linked bank name if available, otherwise fallback to generic display name for bank
                return financialConnectionsLinkedBank?.displayName ?? STPPaymentMethodType.USBankAccount.displayName
            default:
                // For all other payment method types just use the default label
                return paymentSheetLabel
            }
        case .external:
            return paymentSheetLabel
        case .instantDebits:
            return STPPaymentMethodType.link.displayName
        case .linkCardBrand:
            return STPPaymentMethodType.link.displayName
        }
    }

    var paymentSheetSublabel: String? {
        switch paymentMethodType {
        case .stripe(let stpPaymentMethodType):
            switch stpPaymentMethodType {
            case .card:
                return paymentSheetLabel
            case .USBankAccount:
                return paymentSheetLabel
            default:
                return nil
            }
        case .external:
            return nil
        case .instantDebits, .linkCardBrand:
            if let linkedBank = instantDebitsLinkedBank {
                let last4 = "••••\(linkedBank.last4 ?? "")"
                return "\(linkedBank.bankName ?? String.Localized.bank) \(last4)"
            }
            return nil
        }
    }

    /// True if the customer opts to save their payment method as their default payment method.
    var setAsDefaultPM: Bool?

    func makeIcon(forDarkBackground: Bool, currency: String?, iconStyle: PaymentSheet.Appearance.IconStyle) -> UIImage {
        if let bankName = (financialConnectionsLinkedBank?.bankName ?? instantDebitsLinkedBank?.bankName) {
            return PaymentSheetImageLibrary.bankIcon(for: PaymentSheetImageLibrary.bankIconCode(for: bankName), iconStyle: iconStyle)
        } else {
            return paymentMethodParams.makeIcon(forDarkBackground: forDarkBackground, currency: currency, iconStyle: iconStyle, updateHandler: nil)
        }
    }

    convenience init(type: PaymentSheet.PaymentMethodType) {
        switch type {
        case .stripe(let paymentMethodType):
            let params = STPPaymentMethodParams(type: paymentMethodType)
            self.init(params: params, type: type)
        case .external(let externalPaymentMethod):
            // Consider refactoring `type` to be `STPPaymentMethodType`. EPMs don't really belong in IntentConfirmParams - there is no intent to confirm!
            // Using `IntentConfirmParams` for EPMs is a ~hack to let us:
            // 1. Get billing details from the form if the merchant configured billing detail collection.
            // 2. Reuse existing form state restoration code in PaymentSheetFlowController, which depends on the previous state being encoded in an IntentConfirmParams.
            let params = STPPaymentMethodParams(type: .unknown)
            params.rawTypeString = externalPaymentMethod.type
            self.init(params: params, type: type)
        case .instantDebits:
            let params = STPPaymentMethodParams(type: .link)
            self.init(params: params, type: type)
        case .linkCardBrand:
            let params = STPPaymentMethodParams(type: .card)
            self.init(params: params, type: type)
        }
    }

    init(params: STPPaymentMethodParams, type: PaymentSheet.PaymentMethodType) {
        self.paymentMethodType = type
        self.paymentMethodParams = params
        self.confirmPaymentMethodOptions = STPConfirmPaymentMethodOptions()
    }

    /// Applies the values of `Configuration.defaultBillingDetails` to this IntentConfirmParams if `attachDefaultsToPaymentMethod` is true.
    /// - Note: This overwrites `paymentMethodParams.billingDetails`.
    func setDefaultBillingDetailsIfNecessary(for configuration: PaymentElementConfiguration) {
        setDefaultBillingDetailsIfNecessary(defaultBillingDetails: configuration.defaultBillingDetails, billingDetailsCollectionConfiguration: configuration.billingDetailsCollectionConfiguration)
    }

    /// Applies the values of `Configuration.defaultBillingDetails` to this IntentConfirmParams if `attachDefaultsToPaymentMethod` is true.
    /// - Note: This overwrites `paymentMethodParams.billingDetails`.
    func setDefaultBillingDetailsIfNecessary(for configuration: CustomerSheet.Configuration) {
        setDefaultBillingDetailsIfNecessary(defaultBillingDetails: configuration.defaultBillingDetails, billingDetailsCollectionConfiguration: configuration.billingDetailsCollectionConfiguration)
    }

    private func setDefaultBillingDetailsIfNecessary(defaultBillingDetails: PaymentSheet.BillingDetails, billingDetailsCollectionConfiguration: PaymentSheet.BillingDetailsCollectionConfiguration) {
        guard billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod else {
            return
        }
        if let name = defaultBillingDetails.name {
            paymentMethodParams.nonnil_billingDetails.name = name
        }
        if let phone = defaultBillingDetails.phone {
            paymentMethodParams.nonnil_billingDetails.phone = phone
        }
        if let email = defaultBillingDetails.email {
            paymentMethodParams.nonnil_billingDetails.email = email
        }
        if defaultBillingDetails.address != .init() {
            paymentMethodParams.nonnil_billingDetails.address = STPPaymentMethodAddress(address: defaultBillingDetails.address)
        }
    }
    func setAllowRedisplay(mobilePaymentElementFeatures: MobilePaymentElementComponentFeature?,
                           isSettingUp: Bool) {
        guard let mobilePaymentElementFeatures else {
            // Legacy Ephemeral Key
            paymentMethodParams.allowRedisplay = .unspecified
            return
        }
        let paymentMethodSave = mobilePaymentElementFeatures.paymentMethodSave
        let allowRedisplayOverride = mobilePaymentElementFeatures.paymentMethodSaveAllowRedisplayOverride

        // Customer Session is enabled
        if paymentMethodSave {
            if isSettingUp {
                if saveForFutureUseCheckboxState == .selected {
                    paymentMethodParams.allowRedisplay = .always
                } else if saveForFutureUseCheckboxState == .deselected {
                    paymentMethodParams.allowRedisplay = .limited
                }
            } else {
                if saveForFutureUseCheckboxState == .selected {
                    paymentMethodParams.allowRedisplay = .always
                } else if saveForFutureUseCheckboxState == .deselected {
                    paymentMethodParams.allowRedisplay = .unspecified
                }
            }
        } else {
            stpAssert(saveForFutureUseCheckboxState == .hidden, "Checkbox should be hidden")
            if isSettingUp {
                paymentMethodParams.allowRedisplay = allowRedisplayOverride ?? .limited
            } else {
                // PaymentMethod won't be attached to customer
                paymentMethodParams.allowRedisplay = .unspecified
            }
        }
    }

    func setAllowRedisplayForCustomerSheet(_ savePaymentMethodConsentBehavior: PaymentSheetFormFactory.SavePaymentMethodConsentBehavior) {
        if savePaymentMethodConsentBehavior == .legacy {
            paymentMethodParams.allowRedisplay = .unspecified
        } else if savePaymentMethodConsentBehavior == .customerSheetWithCustomerSession {
            paymentMethodParams.allowRedisplay = .always
        }
    }
}

extension STPConfirmPaymentMethodOptions {
    func setMoto() {
        let cardOptions = self.cardOptions ?? STPConfirmCardOptions()
        cardOptions.additionalAPIParameters["moto"] = true
        self.cardOptions = cardOptions
    }

    /**
     Sets `payment_method_options[x][setup_future_usage]` where x is either "card" or "us_bank_account"

     `setup_future_usage` controls whether or not the payment method should be saved to the Customer and is only set if:
        1. We're displaying a "Save this pm for future payments" checkbox
        2. The PM type is card or US bank

     - Parameter paymentMethodType: This method no-ops unless the type is either `.card` or `.USBankAccount`
     - Note: PaymentSheet uses this `setup_future_usage` (SFU) value very differently from the top-level one:
        We read the top-level SFU to know the merchant’s desired save behavior
        We write payment method options SFU to set the customer’s desired save behavior

     */
    func setSetupFutureUsageIfNecessary(
        _ shouldSave: Bool,
        currentSetupFutureUsage: String? = nil,
        paymentMethodType: STPPaymentMethodType,
        customer: PaymentSheet.CustomerConfiguration?
    ) {
        // Something went wrong if we're trying to save and there's no Customer!
        assert(!(shouldSave && customer == nil))

        var allowedPaymentMethodTypes: [STPPaymentMethodType] = [.card, .USBankAccount]

        if let customer, case .customerSession = customer.customerAccessProvider {
            allowedPaymentMethodTypes.append(.link)
        }

        guard customer != nil && allowedPaymentMethodTypes.contains(paymentMethodType) else {
            return
        }

        let sfuValue = shouldSave ? "off_session" : currentSetupFutureUsage ?? ""
        switch paymentMethodType {
        case .card:
            cardOptions = cardOptions ?? STPConfirmCardOptions()
            cardOptions?.additionalAPIParameters["setup_future_usage"] = sfuValue
        case .USBankAccount:
            // Note: the SFU value passed in the STPConfirmUSBankAccountOptions init will be overwritten by `additionalAPIParameters`. See https://jira.corp.stripe.com/browse/RUN_MOBILESDK-1737
            usBankAccountOptions = usBankAccountOptions ?? STPConfirmUSBankAccountOptions(setupFutureUsage: .none)
            usBankAccountOptions?.additionalAPIParameters["setup_future_usage"] = sfuValue
        case .link:
            linkOptions = linkOptions ?? STPConfirmLinkOptions()
            linkOptions?.additionalAPIParameters["setup_future_usage"] = sfuValue
        default:
            return
        }
    }
}
