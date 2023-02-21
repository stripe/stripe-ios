//
//  Intent.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 6/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//
//  This file contains types that abstract over PaymentIntent and SetupIntent for convenience.
//

import Foundation
import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI

// MARK: - Intent

/// An internal type representing either a PaymentIntent, SetupIntent, or a "deferred Intent"
enum Intent {
    case paymentIntent(STPPaymentIntent)
    case setupIntent(STPSetupIntent)
    case deferredIntent(elementsSession: STPElementsSession, intentConfig: PaymentSheet.IntentConfiguration)

    var clientSecret: String {
        switch self {
        case .paymentIntent(let pi):
            return pi.clientSecret
        case .setupIntent(let si):
            return si.clientSecret
        case .deferredIntent:
            fatalError("TODO(DeferredIntent): Handle when we add confirm")
        }
    }

    var unactivatedPaymentMethodTypes: [STPPaymentMethodType] {
        switch self {
        case .paymentIntent(let pi):
            return pi.unactivatedPaymentMethodTypes
        case .setupIntent(let si):
            return si.unactivatedPaymentMethodTypes
        case .deferredIntent(let elementsSession, _):
            return elementsSession.unactivatedPaymentMethodTypes
        }
    }

    /// A sorted list of payment method types supported by the Intent and PaymentSheet, ordered from most recommended to least recommended.
    var recommendedPaymentMethodTypes: [STPPaymentMethodType] {
        switch self {
        case .paymentIntent(let pi):
            return pi.orderedPaymentMethodTypes
        case .setupIntent(let si):
            return si.orderedPaymentMethodTypes
        case .deferredIntent(let elementsSession, _):
            return elementsSession.orderedPaymentMethodTypes
        }
    }

    var isPaymentIntent: Bool {
        switch self {
        case .paymentIntent:
            return true
        case .setupIntent:
            return false
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment:
                return true
            case .setup:
                return false
            }
        }
    }

    var currency: String? {
        switch self {
        case .paymentIntent(let pi):
            return pi.currency
        case .setupIntent:
            return nil
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment(_, let currency, _):
                return currency
            case .setup(let currency, _):
                return currency
            }
        }
    }

    /// True if this ia PaymentIntent with sfu not equal to none or a SetupIntent
    var isSettingUp: Bool {
        switch self {
        case .paymentIntent(let paymentIntent):
            return paymentIntent.setupFutureUsage != .none
        case .setupIntent:
            return true
        case .deferredIntent(_, let intentConfig):
            switch intentConfig.mode {
            case .payment(_, _, let setupFutureUsage):
                return setupFutureUsage != nil
            case .setup:
                return true
            }
        }
    }
}

// MARK: - IntentConfirmParams

/// An internal type representing both `STPPaymentIntentParams` and `STPSetupIntentParams`
/// - Note: Assumes you're confirming with a new payment method
class IntentConfirmParams {

    let paymentMethodParams: STPPaymentMethodParams
    let paymentMethodType: PaymentSheet.PaymentMethodType

    /// True if the customer opts to save their payment method for future payments.
    /// - Note: PaymentIntent-only
    var shouldSavePaymentMethod: Bool = false
    /// - Note: PaymentIntent-only
    var paymentMethodOptions: STPConfirmPaymentMethodOptions?

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
        if let paymentType = type.stpPaymentMethodType {
            let params = STPPaymentMethodParams(type: paymentType)
            self.init(params: params, type: type)
        } else {
            let params = STPPaymentMethodParams(type: .unknown)
            params.rawTypeString = PaymentSheet.PaymentMethodType.string(from: type)
            self.init(params: params, type: type)
        }
    }

    init(params: STPPaymentMethodParams, type: PaymentSheet.PaymentMethodType) {
        self.paymentMethodType = type
        self.paymentMethodParams = params
    }

    func makeParams(
        paymentIntentClientSecret: String,
        configuration: PaymentSheet.Configuration
    ) -> STPPaymentIntentParams {
        let params = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        params.paymentMethodParams = paymentMethodParams
        let options = paymentMethodOptions ?? STPConfirmPaymentMethodOptions()
        options.setSetupFutureUsageIfNecessary(
            shouldSavePaymentMethod,
            paymentMethodType: paymentMethodType,
            customer: configuration.customer
        )
        params.paymentMethodOptions = options

        return params
    }

    func makeParams(setupIntentClientSecret: String) -> STPSetupIntentConfirmParams {
        let params = STPSetupIntentConfirmParams(clientSecret: setupIntentClientSecret)
        params.paymentMethodParams = paymentMethodParams
        return params
    }

    func makeDashboardParams(
        paymentIntentClientSecret: String,
        paymentMethodID: String,
        configuration: PaymentSheet.Configuration
    ) -> STPPaymentIntentParams {
        let params = STPPaymentIntentParams(clientSecret: paymentIntentClientSecret)
        params.paymentMethodId = paymentMethodID

        // Dashboard only supports a specific payment flow today
        assert(paymentMethodOptions == nil)

        let options = STPConfirmPaymentMethodOptions()
        options.setSetupFutureUsageIfNecessary(
            shouldSavePaymentMethod,
            paymentMethodType: paymentMethodType,
            customer: configuration.customer
        )
        params.paymentMethodOptions = options

        options.setMoto()

        return params
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
    func setSetupFutureUsageIfNecessary(
        _ shouldSave: Bool,
        paymentMethodType: PaymentSheet.PaymentMethodType,
        customer: PaymentSheet.CustomerConfiguration?
    ) {
        if let bridgePaymentMethodType = paymentMethodType.stpPaymentMethodType {
            setSetupFutureUsageIfNecessary(
                shouldSave,
                paymentMethodType: bridgePaymentMethodType,
                customer: customer
            )
        }
    }
}
