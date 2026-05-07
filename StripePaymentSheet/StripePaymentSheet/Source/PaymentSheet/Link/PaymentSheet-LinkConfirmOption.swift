//
//  PaymentSheet-LinkConfirmOption.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 7/19/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension PaymentSheet {

    enum LinkConfirmOption {
        /// Present the Link wallet.
        case wallet(brand: LinkBrand)

        /// Signup for Link then pay.
        case signUp(
            brand: LinkBrand,
            account: PaymentSheetLinkAccount,
            phoneNumber: PhoneNumber?,
            consentAction: PaymentSheetLinkAccount.ConsentAction,
            legalName: String?,
            intentConfirmParams: IntentConfirmParams
        )

        /// Confirm with Payment Method. (Web fallback)
        case withPaymentMethod(
            brand: LinkBrand,
            paymentMethod: STPPaymentMethod
        )

        /// Confirm intent with paymentDetails.
        case withPaymentDetails(
            brand: LinkBrand,
            account: PaymentSheetLinkAccount,
            paymentDetails: ConsumerPaymentDetails,
            confirmationExtras: LinkConfirmationExtras?,
            shippingAddress: ShippingAddressesResponse.ShippingAddress?
        )
    }

}

// MARK: - Helpers

extension PaymentSheet.LinkConfirmOption {
    func paymentSheetSubLabel(brand: LinkBrand) -> String? {
        guard let sublabel = paymentSheetSubLabel else {
            return nil
        }

        switch sublabel {
        // Suppress the redundant sublabel both for the resolved brand name and for
        // the legacy "Link" fallback that some lower-level paths can still return.
        case brand.displayName, STPPaymentMethodType.link.displayName:
            return nil
        default:
            return sublabel
        }
    }

    func displayPaymentSheetSubLabel() -> String? {
        guard let sublabel = paymentSheetSubLabel else {
            return nil
        }
        // Suppress the redundant sublabel both for the resolved brand name and for
        // the legacy Link label that some lower-level paths can still return.
        guard sublabel != brand.displayName, sublabel != LinkBrand.link.displayName else {
            return nil
        }
        return sublabel
    }

    var account: PaymentSheetLinkAccount? {
        switch self {
        case .wallet:
            return nil
        case .signUp(_, let account, _, _, _, _):
            return account
        case .withPaymentMethod:
            return nil
        case .withPaymentDetails(_, let account, _, _, _):
            return account
        }
    }

    var paymentSheetSubLabel: String? {
        switch self {
        case .wallet:
            return nil
        case .signUp(_, _, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.paymentSheetLabel
        case .withPaymentMethod(_, let paymentMethod):
            return paymentMethod.linkPaymentDetailsFormattedString
        case .withPaymentDetails(_, _, let paymentDetails, _, _):
            return paymentDetails.linkPaymentDetailsFormattedString
        }
    }

    var paymentMethodType: String {
        switch self {
        case .signUp(_, _, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.type.identifier
        case .wallet, .withPaymentMethod, .withPaymentDetails:
            return STPPaymentMethodType.link.identifier
        }
    }

    var shippingAddress: AddressViewController.Configuration.DefaultAddressDetails? {
        switch self {
        case let .withPaymentDetails(_, linkAccount, _, _, shippingAddress):
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
        case .signUp(_, _, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentMethodParams.billingDetails
        case .withPaymentMethod(_, let paymentMethod):
            return paymentMethod.billingDetails
        case .withPaymentDetails(_, _, let paymentDetails, _, _):
            return STPPaymentMethodBillingDetails(billingAddress: paymentDetails.billingAddress, email: paymentDetails.billingEmailAddress)
        }
    }

    var signupConfirmParams: IntentConfirmParams? {
        switch self {
        case .signUp(_, _, _, _, _, let intentConfirmParams):
            return intentConfirmParams
        case .wallet, .withPaymentDetails, .withPaymentMethod:
            return nil
        }
    }

    var signupAction: LinkInlineSignupViewModel.Action? {
        switch self {
        case .signUp(_, let account, let phoneNumber, _, let legalName, _):
            return .signupAndPay(account: account, phoneNumber: phoneNumber, legalName: legalName)
        case .wallet, .withPaymentDetails, .withPaymentMethod:
            return nil
        }
    }

    func paymentSheetLabel(brand: LinkBrand) -> String {
        switch self {
        case .wallet, .withPaymentDetails:
            return brand.displayName
        case .signUp(_, _, _, _, let intentConfirmParams):
            return intentConfirmParams.paymentSheetLabel(brand: brand)
        case .withPaymentMethod(let paymentMethod):
            return paymentMethod.paymentSheetLabel(brand: brand)
        }
    }
}
