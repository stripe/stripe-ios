//
//  PayWithLinkViewController-WalletViewModel.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 3/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

protocol PayWithLinkWalletViewModelDelegate: AnyObject {
    func viewModelDidChange(_ viewModel: PayWithLinkViewController.WalletViewModel)
}

extension PayWithLinkViewController {

    final class WalletViewModel {
        let context: Context
        let linkAccount: PaymentSheetLinkAccount
        private(set) var paymentMethods: [ConsumerPaymentDetails]

        weak var delegate: PayWithLinkWalletViewModelDelegate?

        /// Index of currently selected payment method.
        var selectedPaymentMethodIndex: Int {
            didSet {
                if oldValue != selectedPaymentMethodIndex {
                    delegate?.viewModelDidChange(self)
                }
            }
        }

        var supportedPaymentMethodTypes: Set<ConsumerPaymentDetails.DetailsType> {
            return linkAccount.supportedPaymentDetailsTypes(for: context.elementsSession)
        }

        var cvc: String? {
            didSet {
                if oldValue != cvc {
                    delegate?.viewModelDidChange(self)
                }
            }
        }

        var expiryDate: CardExpiryDate? {
            didSet {
                if oldValue != expiryDate {
                    delegate?.viewModelDidChange(self)
                }
            }
        }

        /// Currently selected payment method.
        var selectedPaymentMethod: ConsumerPaymentDetails? {
            guard paymentMethods.indices.contains(selectedPaymentMethodIndex) else {
                return nil
            }

            return paymentMethods[selectedPaymentMethodIndex]
        }

        /// Whether or not the view should show the instant debit mandate text.
        var shouldShowInstantDebitMandate: Bool {
            switch selectedPaymentMethod?.details {
            case .bankAccount:
                // Instant debit mandate should be shown when paying with bank account.
                return true
            default:
                return false
            }
        }

        var noticeText: String? {
            if shouldRecollectCardExpiryDate {
                return STPLocalizedString(
                    "This card has expired. Update your card info or choose a different payment method.",
                    "A text notice shown when the user selects an expired card."
                )
            }

            if shouldRecollectCardCVC {
                return STPLocalizedString(
                    "For security, please re-enter your card’s security code.",
                    """
                    A text notice shown when the user selects a card that requires
                    re-entering the security code (CVV/CVC).
                    """
                )
            }

            return nil
        }

        var shouldShowNotice: Bool {
            return noticeText != nil
        }

        var shouldShowRecollectionSection: Bool {
            return (
                shouldRecollectCardCVC ||
                shouldRecollectCardExpiryDate
            )
        }

        var shouldShowApplePayButton: Bool {
            return context.shouldOfferApplePay
        }

        var shouldUseCompactConfirmButton: Bool {
            // We should use a compact confirm button whenever we display the Apple Pay button.
            return shouldShowApplePayButton
        }

        var cancelButtonConfiguration: Button.Configuration {
            return shouldShowApplePayButton ? .linkPlain() : .linkSecondary()
        }

        /// Whether or not we must re-collect the card CVC.
        var shouldRecollectCardCVC: Bool {
            switch selectedPaymentMethod?.details {
            case .card(let card):
                return card.shouldRecollectCardCVC || card.hasExpired
            default:
                // Only cards have CVC.
                return false
            }
        }

        var shouldRecollectCardExpiryDate: Bool {
            switch selectedPaymentMethod?.details {
            case .card(let card):
                return card.hasExpired
            case .bankAccount, .unparsable, .none:
                // Only cards have expiry date.
                return false
            }
        }

        /// CTA
        var confirmButtonCallToAction: ConfirmButton.CallToActionType {
            context.callToAction
        }

        var confirmButtonStatus: ConfirmButton.Status {
            if selectedPaymentMethod == nil {
                return .disabled
            }

            if !selectedPaymentMethodIsSupported {
                // Selected payment method not supported
                return .disabled
            }

            if shouldRecollectCardCVC && cvc == nil {
                return .disabled
            }

            if shouldRecollectCardExpiryDate && expiryDate == nil {
                return .disabled
            }

            return .enabled
        }

        var cardBrand: STPCardBrand? {
            switch selectedPaymentMethod?.details {
            case .card(let card):
                return card.stpBrand
            default:
                return nil
            }
        }

        var selectedPaymentMethodIsSupported: Bool {
            guard let selectedPaymentMethod = selectedPaymentMethod else {
                return false
            }

            return supportedPaymentMethodTypes.contains(selectedPaymentMethod.type)
        }

        init(
            linkAccount: PaymentSheetLinkAccount,
            context: Context,
            paymentMethods: [ConsumerPaymentDetails]
        ) {
            self.linkAccount = linkAccount
            self.context = context
            self.paymentMethods = paymentMethods
            self.selectedPaymentMethodIndex = Self.determineInitiallySelectedPaymentMethod(
                context: context,
                paymentMethods: paymentMethods
            )
        }

        func deletePaymentMethod(at index: Int, completion: @escaping (Result<Void, Error>) -> Void) {
            let paymentMethod = paymentMethods[index]

            linkAccount.deletePaymentDetails(id: paymentMethod.stripeID) { [self] result in
                switch result {
                case .success:
                    paymentMethods.remove(at: index)
                    delegate?.viewModelDidChange(self)
                case .failure:
                    break
                }

                completion(result)
            }
        }

        func setDefaultPaymentMethod(
            at index: Int,
            completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
        ) {
            let paymentMethod = paymentMethods[index]

            linkAccount.updatePaymentDetails(
                id: paymentMethod.stripeID,
                updateParams: UpdatePaymentDetailsParams(isDefault: true, details: nil)
            ) { [self] result in
                if case let .success(updatedPaymentDetails) = result {
                    paymentMethods.forEach({ $0.isDefault = false })
                    paymentMethods[index] = updatedPaymentDetails
                }

                completion(result)
            }
        }

        /// Updates the billing details of the provided `paymentMethod`.
        func updateBillingDetails(
            paymentMethodID: String,
            billingAddress: BillingAddress?,
            billingEmailAddress: String?,
            completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void
        ) {
            guard let index = paymentMethods.firstIndex(where: { $0.stripeID == paymentMethodID }) else {
                return
            }

            let billingDetails = STPPaymentMethodBillingDetails(
                billingAddress: billingAddress,
                email: billingEmailAddress
            )

            let updateParams = UpdatePaymentDetailsParams(
                details: .card(billingDetails: billingDetails)
            )

            linkAccount.updatePaymentDetails(
                id: paymentMethodID,
                updateParams: updateParams
            ) { [self] result in
                if case let .success(updatedPaymentDetails) = result {
                    paymentMethods[index] = updatedPaymentDetails
                }

                completion(result)
            }
        }

        func updatePaymentMethod(_ paymentMethod: ConsumerPaymentDetails) -> Int? {
            guard let index = paymentMethods.firstIndex(where: { $0.stripeID == paymentMethod.stripeID }) else {
                return nil
            }

            if paymentMethod.isDefault {
                paymentMethods.forEach({ $0.isDefault = false })
            }

            paymentMethods[index] = paymentMethod

            delegate?.viewModelDidChange(self)

            return index
        }

        func updateExpiryDate(completion: @escaping (Result<ConsumerPaymentDetails, Error>) -> Void) {
            guard
                let id = selectedPaymentMethod?.stripeID,
                let expiryDate = self.expiryDate
            else {
                stpAssertionFailure("Called with no selected payment method or expiry date provided.")
                return
            }

            linkAccount.updatePaymentDetails(
                id: id,
                updateParams: UpdatePaymentDetailsParams(details: .card(expiryDate: expiryDate)),
                completion: completion
            )
        }
    }

}

private extension PayWithLinkViewController.WalletViewModel {

    static func determineInitiallySelectedPaymentMethod(
        context: PayWithLinkViewController.Context,
        paymentMethods: [ConsumerPaymentDetails]
    ) -> Int {
        var indexOfLastAddedPaymentMethod: Int? {
            guard let lastAddedID = context.lastAddedPaymentDetails?.stripeID else {
                return nil
            }

            return paymentMethods.firstIndex(where: { $0.stripeID == lastAddedID })
        }

        var indexOfDefaultPaymentMethod: Int? {
            return paymentMethods.firstIndex(where: { $0.isDefault })
        }

        return indexOfLastAddedPaymentMethod ?? indexOfDefaultPaymentMethod ?? 0
    }
}
