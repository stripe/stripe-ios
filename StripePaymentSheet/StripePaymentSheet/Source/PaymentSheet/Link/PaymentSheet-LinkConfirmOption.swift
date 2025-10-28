//
//  PaymentSheet-LinkConfirmOption.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 7/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheet {

    enum LinkConfirmOption {
        /// Present the Link wallet.
        case wallet

        /// Signup for Link then pay.
        case signUp(
            account: PaymentSheetLinkAccount,
            phoneNumber: PhoneNumber?,
            consentAction: PaymentSheetLinkAccount.ConsentAction,
            legalName: String?,
            intentConfirmParams: IntentConfirmParams
        )

        /// Confirm with Payment Method. (Web fallback)
        case withPaymentMethod(
            paymentMethod: STPPaymentMethod
        )

        /// Confirm intent with paymentDetails.
        case withPaymentDetails(
            account: PaymentSheetLinkAccount,
            paymentDetails: ConsumerPaymentDetails,
            confirmationExtras: LinkConfirmationExtras?,
            shippingAddress: ShippingAddressesResponse.ShippingAddress?
        )
    }

}

// MARK: - Helpers

extension PaymentSheet.LinkConfirmOption {

    var account: PaymentSheetLinkAccount? {
        switch self {
        case .wallet:
            return nil
        case .signUp(let account, _, _, _, _):
            return account
        case .withPaymentMethod:
            return nil
        case .withPaymentDetails(let account, _, _, _):
            return account
        }
    }

    var paymentSheetLabel: String {
        switch self {
        case .wallet, .withPaymentDetails:
            return STPPaymentMethodType.link.displayName
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.paymentSheetLabel
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.paymentSheetLabel
        }
    }

    var paymentSheetSubLabel: String? {
        switch self {
        case .wallet:
            return nil
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.paymentSheetLabel
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.linkPaymentDetailsFormattedString
        case .withPaymentDetails(_, let paymentDetails, _, _):
            return paymentDetails.linkPaymentDetailsFormattedString
        }
    }

    var paymentMethodType: String {
        switch self {
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.type.identifier
        case .wallet, .withPaymentMethod, .withPaymentDetails:
            return STPPaymentMethodType.link.identifier
        }
    }

    var shippingAddress: AddressViewController.Configuration.DefaultAddressDetails? {
        switch self {
        case let .withPaymentDetails(linkAccount, _, _, shippingAddress):
            guard let shippingAddress else { return nil }
            return .init(
                address: shippingAddress.toPaymentSheetAddress(),
                name: shippingAddress.address.name,
                phone: linkAccount.currentSession?.unredactedPhoneNumberWithPrefix
            )
        case .wallet, .withPaymentMethod, .signUp:
            return nil
        }
    }

    var billingDetails: STPPaymentMethodBillingDetails? {
        switch self {
        case .wallet:
            return nil
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.billingDetails
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.billingDetails
        case .withPaymentDetails(_, let paymentDetails, _, _):
            return STPPaymentMethodBillingDetails(billingAddress: paymentDetails.billingAddress, email: paymentDetails.billingEmailAddress)
        }
    }

    var signupConfirmParams: IntentConfirmParams? {
        switch self {
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams
        case .wallet, .withPaymentDetails, .withPaymentMethod:
            return nil
        }
    }

    var signupAction: LinkInlineSignupViewModel.Action? {
        switch self {
        case .signUp(let account, let phoneNumber, _, let legalName, _):
            return .signupAndPay(account: account, phoneNumber: phoneNumber, legalName: legalName)
        case .wallet, .withPaymentDetails, .withPaymentMethod:
            return nil
        }
    }
}
