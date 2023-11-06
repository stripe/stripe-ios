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

/// An internal type representing both `STPPaymentIntentParams` and `STPSetupIntentParams`
/// - Note: Assumes you're confirming with a new payment method, unless a payment method ID is provided
class IntentConfirmParams {
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
    let confirmPaymentMethodOptions: STPConfirmPaymentMethodOptions

    /// True if the customer opts to save their payment method for future payments.
    var saveForFutureUseCheckboxState: SaveForFutureUseCheckboxState = .hidden
    /// If `true`, a mandate (e.g. "By continuing you authorize Foo Corp to use your payment details for recurring payments...") was displayed to the customer.
    var didDisplayMandate: Bool = false

    var linkedBank: LinkedBank?

    var paymentSheetLabel: String {
        if let linkedBank = linkedBank,
            let last4 = linkedBank.last4
        {
            return "••••\(last4)"
        } else {
            return paymentMethodParams.paymentSheetLabel
        }
    }

    func makeIcon(updateImageHandler: DownloadManager.UpdateImageHandler?) -> UIImage {
        if let linkedBank = linkedBank,
            let bankName = linkedBank.bankName
        {
            return PaymentSheetImageLibrary.bankIcon(for: PaymentSheetImageLibrary.bankIconCode(for: bankName))
        } else {
            return paymentMethodParams.makeIcon(updateHandler: updateImageHandler)
        }
    }

    convenience init(type: PaymentSheet.PaymentMethodType) {
        switch type {
        case .stripe(let paymentMethodType):
            let params = STPPaymentMethodParams(type: paymentMethodType)
            self.init(params: params, type: type)
        case .externalPayPal:
            let params = STPPaymentMethodParams(type: .unknown)
            params.rawTypeString = "external_paypal"
            self.init(params: params, type: type)
        }
    }

    init(params: STPPaymentMethodParams, type: PaymentSheet.PaymentMethodType) {
        self.paymentMethodType = type
        self.paymentMethodParams = params
        self.confirmPaymentMethodOptions = STPConfirmPaymentMethodOptions()
    }

    static func makeDashboardParams(
        paymentIntentClientSecret: String,
        paymentMethodID: String,
        shouldSave: Bool,
        paymentMethodType: STPPaymentMethodType,
        customer: PaymentSheet.CustomerConfiguration?
    ) -> STPPaymentIntentParams {
        let params = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        params.paymentMethodId = paymentMethodID

        // Dashboard only supports a specific payment flow today
        let options = STPConfirmPaymentMethodOptions()
        options.setSetupFutureUsageIfNecessary(
            shouldSave,
            paymentMethodType: paymentMethodType,
            customer: customer
        )
        params.paymentMethodOptions = options

        options.setMoto()

        return params
    }

    /// Applies the values of `Configuration.defaultBillingDetails` to this IntentConfirmParams if `attachDefaultsToPaymentMethod` is true.
    /// - Note: This overwrites `paymentMethodParams.billingDetails`.
    func setDefaultBillingDetailsIfNecessary(for configuration: PaymentSheet.Configuration) {
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
        paymentMethodType: STPPaymentMethodType,
        customer: PaymentSheet.CustomerConfiguration?
    ) {
        // Something went wrong if we're trying to save and there's no Customer!
        assert(!(shouldSave && customer == nil))

        guard customer != nil && paymentMethodType == .card || paymentMethodType == .USBankAccount else {
            return
        }
        // Note: The API officially only allows the values "off_session", "on_session", and "none".
        // Passing "none" *overrides* the top-level setup_future_usage and is not what we want, b/c this code is called even when we don't display the "save" checkbox (e.g. when the PI top-level setup_future_usage is already set).
        // Instead, we pass an empty string to 'unset' this value. This makes the PaymentIntent *inherit* the top-level setup_future_usage.
        let sfuValue = shouldSave ? "off_session" : ""
        switch paymentMethodType {
        case .card:
            cardOptions = cardOptions ?? STPConfirmCardOptions()
            cardOptions?.additionalAPIParameters["setup_future_usage"] = sfuValue
        case .USBankAccount:
            // Note: the SFU value passed in the STPConfirmUSBankAccountOptions init will be overwritten by `additionalAPIParameters`. See https://jira.corp.stripe.com/browse/RUN_MOBILESDK-1737
            usBankAccountOptions = usBankAccountOptions ?? STPConfirmUSBankAccountOptions(setupFutureUsage: .none)
            usBankAccountOptions?.additionalAPIParameters["setup_future_usage"] = sfuValue
        default:
            return
        }
    }
}
