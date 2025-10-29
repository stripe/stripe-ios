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
            return context.getSupportedPaymentDetailsTypes(linkAccount: linkAccount)
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
        var mandate: NSAttributedString? {
            let isSettingUp = context.intent.isSetupFutureUsageSet(for: context.elementsSession.linkPassthroughModeEnabled ? .card : .link)

            switch selectedPaymentMethod?.details {
            case .card:
                if context.elementsSession.forceSaveFutureUseBehaviorAndNewMandateText {
                    // Use the updated mandate text that can mention both payment method reuse and Link signup.
                    // Since the user is already signed up for Link, we don't need to save to Link.
                    return PaymentSheetFormFactory.makeMandateText(
                        variant: .updated(shouldSignUpToLink: false),
                        merchantName: context.configuration.merchantDisplayName
                    )
                } else if isSettingUp {
                    let string = String(format: .Localized.by_providing_your_card_information_text, context.configuration.merchantDisplayName)
                    return NSMutableAttributedString(string: string)
                } else {
                    return nil
                }
            case .bankAccount:
                // Instant debit mandate should be shown when paying with bank account.
                return PaymentSheetFormFactory.makeBankMandateText(
                    isSettingUp: isSettingUp || context.elementsSession.forceSaveFutureUseBehaviorAndNewMandateText,
                    merchantName: context.configuration.merchantDisplayName,
                    sellerName: context.intent.sellerDetails?.businessName
                )
            default:
                return nil
            }
        }

        /// Whether or not the view should show the mandate text.
        var shouldShowMandate: Bool {
            mandate != nil
        }

        /// Client attribution metadata for analytics
        var clientAttributionMetadata: STPClientAttributionMetadata? {
            STPClientAttributionMetadata.makeClientAttributionMetadataIfNecessary(analyticsHelper: context.analyticsHelper, intent: context.intent, elementsSession: context.elementsSession)
        }

        /// Returns a hint message, if it is supported.
        /// - The `link_show_prefer_debit_card_hint` flag must be enabled.
        /// - A non-empty hint message must exist in the `LinkConfiguration`.
        /// - Cards are a supported payment types.
        func debitCardHintIfSupported(for linkAccount: PaymentSheetLinkAccount) -> String? {
            let flagEnabled = context.elementsSession.shouldShowPreferDebitCardHint
            let hintMessage = context.linkConfiguration?.hintMessage
            let hasHintMessage = hintMessage?.isEmpty == false
            let supportedPaymentDetailTypes = context.getSupportedPaymentDetailsTypes(linkAccount: linkAccount)
            let supportsCards = supportedPaymentDetailTypes.contains(.card)

            if flagEnabled && hasHintMessage && supportsCards {
                return hintMessage
            } else {
                return nil
            }
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

        var linkAppearance: LinkAppearance? {
            return context.linkAppearance
        }

        var cancelButtonConfiguration: Button.Configuration? {
            context.shouldShowSecondaryCta ? .linkPlain(foregroundColor: linkAppearance?.colors?.primary ?? .linkTextBrand) : nil
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
                updateParams: UpdatePaymentDetailsParams(isDefault: true, details: nil),
                clientAttributionMetadata: clientAttributionMetadata
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
                clientAttributionMetadata: clientAttributionMetadata,
                completion: completion
            )
        }

        func isPaymentMethodSupported(paymentMethod: ConsumerPaymentDetails?) -> Bool {
            paymentMethod?.isSupported(linkAccount: linkAccount, elementsSession: context.elementsSession, configuration: context.configuration, cardBrandFilter: context.configuration.cardBrandFilter) ?? false
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
