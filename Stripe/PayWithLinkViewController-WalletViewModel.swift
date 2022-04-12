//
//  PayWithLinkViewController-WalletViewModel.swift
//  StripeiOS
//
//  Created by Ramon Torres on 3/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
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

        var cvc: String? {
            didSet {
                if oldValue != cvc {
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
            case .bankAccount(_):
                // Instant debit mandate should be shown when paying with bank account.
                return true
            default:
                return false
            }
        }

        var shouldShowApplePayButton: Bool {
            return (
                context.shouldOfferApplePay &&
                context.configuration.isApplePayEnabled
            )
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
                return card.shouldRecollectCardCVC
            default:
                // Only cards have CVC.
                return false
            }
        }

        /// CTA
        var confirmButtonCallToAction: ConfirmButton.CallToActionType {
            if context.selectionOnly {
                guard let selectedPaymentMethod = selectedPaymentMethod?.paymentMethodType else {
                    return .add(paymentMethodType: .link)
                }

                return .add(paymentMethodType: selectedPaymentMethod)
            } else {
                return context.intent.callToAction
            }
        }

        var confirmButtonStatus: ConfirmButton.Status {
            if selectedPaymentMethod == nil {
                return .disabled
            }

            if shouldRecollectCardCVC && cvc == nil {
                return .disabled
            }

            return .enabled
        }

        var cardBrand: STPCardBrand? {
            switch selectedPaymentMethod?.details {
            case .card(let card):
                return card.brand
            default:
                return nil
            }
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
                case .failure(_):
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

        func updatePaymentMethod(_ paymentMethod: ConsumerPaymentDetails) -> Int? {
            guard let index = paymentMethods.firstIndex(where: {$0.stripeID == paymentMethod.stripeID}) else {
                return nil
            }

            if paymentMethod.isDefault {
                paymentMethods.forEach({ $0.isDefault = false })
            }

            paymentMethods[index] = paymentMethod

            delegate?.viewModelDidChange(self)

            return index
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

/// Helper functions for ConsumerPaymentDetails
private extension ConsumerPaymentDetails {
    var paymentMethodType: STPPaymentMethodType {
        switch details {
        case .card:
            return .card
        case .bankAccount:
            return .linkInstantDebit
        }
    }
}
