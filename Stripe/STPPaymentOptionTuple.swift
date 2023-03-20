//
//  STPPaymentOptionTuple.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import Foundation

class STPPaymentOptionTuple: NSObject {
    @objc
    public convenience init(
        paymentOptions: [STPPaymentOption],
        selectedPaymentOption: STPPaymentOption?
    ) {
        self.init()
        self.paymentOptions = paymentOptions
        self.selectedPaymentOption = selectedPaymentOption
    }

    @objc
    public convenience init(
        paymentOptions: [STPPaymentOption],
        selectedPaymentOption: STPPaymentOption?,
        addApplePayOption applePayEnabled: Bool,
        addFPXOption fpxEnabled: Bool
    ) {
        var mutablePaymentOptions = paymentOptions
        weak var selected = selectedPaymentOption

        if applePayEnabled {
            let applePay = STPApplePayPaymentOption()
            mutablePaymentOptions.append(applePay)

            if selected == nil {
                selected = applePay
            }
        }

        if fpxEnabled {
            let fpx = STPPaymentMethodFPXParams()
            let fpxPaymentOption = STPPaymentMethodParams(
                fpx: fpx, billingDetails: nil, metadata: nil)
            mutablePaymentOptions.append(fpxPaymentOption)
        }

        self.init(
            paymentOptions: mutablePaymentOptions,
            selectedPaymentOption: selected)
    }

    /// Returns a tuple for the given array of STPPaymentMethod, filtered to only include the
    /// the types supported by STPPaymentContext/STPPaymentOptionsViewController and adding
    /// Apple Pay as a method if appropriate.
    /// - Returns: A new tuple ready to be used by the SDK's UI elements
    @objc(tupleFilteredForUIWithPaymentMethods:selectedPaymentMethod:configuration:)
    public convenience init(
        filteredForUIWith paymentMethods: [STPPaymentMethod],
        selectedPaymentMethod selectedPaymentMethodID: String?,
        configuration: STPPaymentConfiguration
    ) {
        var paymentOptions: [STPPaymentOption] = []
        var selectedPaymentMethod: STPPaymentMethod?
        for paymentMethod in paymentMethods {
            if paymentMethod.type == .card {
                paymentOptions.append(paymentMethod)
                if paymentMethod.stripeId == selectedPaymentMethodID {
                    selectedPaymentMethod = paymentMethod
                }
            }
        }

        self.init(
            paymentOptions: paymentOptions,
            selectedPaymentOption: selectedPaymentMethod,
            addApplePayOption: configuration.applePayEnabled,
            addFPXOption: configuration.fpxEnabled)
    }

    private(set) weak var selectedPaymentOption: STPPaymentOption?
    private(set) var paymentOptions: [STPPaymentOption] = []
}
