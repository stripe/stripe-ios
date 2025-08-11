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

        /// The mandate text to show.
        var mandate: NSMutableAttributedString? {
            switch selectedPaymentMethod?.details {
            case .card:
                guard context.intent.isSetupFutureUsageSet(for: context.elementsSession.linkPassthroughModeEnabled ? .card : .link) else { return nil }
                let string = String(format: .Localized.by_providing_your_card_information_text, context.configuration.merchantDisplayName)
                return NSMutableAttributedString(string: string)
            case .bankAccount:
                // Instant debit mandate should be shown when paying with bank account.
                let string = String.Localized.bank_continue_mandate_text
                return STPStringUtils.applyLinksToString(
                    template: string,
                    links: ["terms": URL(string: "https://link.com/terms/ach-authorization")!]
                )
            default:
                return nil
            }
        }

        /// Whether or not the view should show the mandate text.
        var shouldShowMandate: Bool {
            mandate != nil
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

        var cancelButtonConfiguration: Button.Configuration? {
            context.shouldShowSecondaryCta ? .linkPlain() : nil
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
            isPaymentMethodSupported(paymentMethod: selectedPaymentMethod)
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
                    let previouslySelectedPaymentMethod = self.selectedPaymentMethod
                    paymentMethods.remove(at: index)

                    var defaultPaymentMethodIndex: Int {
                        Self.determineInitiallySelectedPaymentMethod(
                            context: context,
                            paymentMethods: paymentMethods)
                    }

                    var updatedPaymentMethodIndex: Int? {
                        paymentMethods.firstIndex(where: {
                            $0.stripeID == previouslySelectedPaymentMethod?.stripeID
                        })
                    }

                    selectedPaymentMethodIndex = updatedPaymentMethodIndex ?? defaultPaymentMethodIndex
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

        // Updates the list of payment methods, and selects the newly added payment method, if supported.
        func updatePaymentMethods(_ paymentMethods: [ConsumerPaymentDetails]) {
            let existingIDs = Set(self.paymentMethods.map { $0.stripeID })
            let newPaymentMethod = paymentMethods.first { !existingIDs.contains($0.stripeID) }

            self.paymentMethods = paymentMethods

            if let newPaymentMethod, isPaymentMethodSupported(paymentMethod: newPaymentMethod),
               let newIndex = paymentMethods.firstIndex(where: { $0.stripeID == newPaymentMethod.stripeID }) {
                selectedPaymentMethodIndex = newIndex
            }

            delegate?.viewModelDidChange(self)
        }

        func updatePaymentMethod(_ paymentMethod: ConsumerPaymentDetails) {
            guard let index = paymentMethods.firstIndex(where: { $0.stripeID == paymentMethod.stripeID }) else {
                return
            }

            if paymentMethod.isDefault {
                paymentMethods.forEach({ $0.isDefault = false })
            }

            paymentMethods[index] = paymentMethod

            if isPaymentMethodSupported(paymentMethod: paymentMethod) {
                selectedPaymentMethodIndex = index
            }

            delegate?.viewModelDidChange(self)
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

        func isPaymentMethodSupported(paymentMethod: ConsumerPaymentDetails?) -> Bool {
            paymentMethod?.isSupported(linkAccount: linkAccount, elementsSession: context.elementsSession, cardBrandFilter: context.configuration.cardBrandFilter) ?? false
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

        var indexOfPreviouslySelectedPaymentMethod: Int? {
            guard let previouslySelectedID = context.initiallySelectedPaymentDetailsID else {
                return nil
            }

            return paymentMethods.firstIndex(where: { $0.stripeID == previouslySelectedID })
        }

        return indexOfLastAddedPaymentMethod ?? indexOfPreviouslySelectedPaymentMethod ?? indexOfDefaultPaymentMethod ?? 0
    }
}
