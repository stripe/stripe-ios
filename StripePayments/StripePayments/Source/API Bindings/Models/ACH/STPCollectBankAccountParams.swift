//
//  STPCollectBankAccountParams.swift
//  StripePayments
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

/// Parameters to use with `STPBankAccountCollector` to collect bank account details for payments.
/// @see `STPBankAccountCollector`
public class STPCollectBankAccountParams: NSObject {
    internal let paymentMethodParams: STPPaymentMethodParams

    internal init(
        paymentMethodParams: STPPaymentMethodParams
    ) {
        self.paymentMethodParams = paymentMethodParams
    }

    /// Configures and returns an instance of `STPCollectBankAccountParams` for US Bank Accounts
    /// - Parameters:
    ///     - name: The customer's full name. _required_
    ///     - email: The customer's email. If included, can be used to notify the customer of pending micro-deposit verification.
    @objc(collectUSBankAccountParamsWithName:email:)
    public class func collectUSBankAccountParams(
        with name: String,
        email: String?
    ) -> STPCollectBankAccountParams {
        return makeCollectUSBankAccountParams(with: name, email: email, address: nil)
    }

    /// Configures and returns an instance of `STPCollectBankAccountParams` for US Bank Accounts
    /// - Parameters:
    ///     - name: The customer's full name. _required_
    ///     - email: The customer's email. If included, can be used to notify the customer of pending micro-deposit verification.
    ///     - address: The customer's billing address.
    @objc(collectUSBankAccountParamsWithName:email:address:)
    public class func collectUSBankAccountParams(
        with name: String,
        email: String?,
        address: STPPaymentMethodAddress
    ) -> STPCollectBankAccountParams {
        return makeCollectUSBankAccountParams(with: name, email: email, address: address)
    }

    private class func makeCollectUSBankAccountParams(
        with name: String,
        email: String?,
        address: STPPaymentMethodAddress?
    ) -> STPCollectBankAccountParams {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.name = name
        billingDetails.email = email
        billingDetails.address = address

        let paymentMethodParams = STPPaymentMethodParams()
        paymentMethodParams.billingDetails = billingDetails
        paymentMethodParams.type = .USBankAccount
        return STPCollectBankAccountParams(paymentMethodParams: paymentMethodParams)
    }

    /// Configures and returns an instance of `STPCollectBankAccountParams` for Instant Debits
    /// - Parameters:
    ///     - email: The customer's email.
    @objc(collectInstantDebitsParamsWithEmail:)
    @_spi(STP) public class func collectInstantDebitsParams(
        email: String?
    ) -> STPCollectBankAccountParams {
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.email = email

        let paymentMethodParams = STPPaymentMethodParams()
        paymentMethodParams.billingDetails = billingDetails
        paymentMethodParams.type = .link
        return STPCollectBankAccountParams(paymentMethodParams: paymentMethodParams)
    }
}
