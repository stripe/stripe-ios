//
//  EmbeddedPaymentElement+Internal.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/10/24.
//
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension EmbeddedPaymentElement {
    @MainActor
    static func makeView(
        configuration: Configuration,
        loadResult: PaymentSheetLoader.LoadResult,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        previousPaymentOption: PaymentOption? = nil,
        delegate: EmbeddedPaymentMethodsViewDelegate? = nil
    ) -> EmbeddedPaymentMethodsView {
        // Restore the customer's previous payment method.
        // Caveats:
        // - Only payment method details (including checkbox state) and billing details are restored
        // - Only restored if the previous input resulted in a completed form i.e. partial or invalid input is still discarded
        // TODO: Restore the form, if any

        let shouldShowApplePay = PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let shouldShowLink = PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let savedPaymentMethodAccessoryType = RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: loadResult.savedPaymentMethods.count,
            isFirstCardCoBranded: loadResult.savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: loadResult.elementsSession.isCardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            allowsPaymentMethodRemoval: loadResult.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        )
        let initialSelection: EmbeddedPaymentMethodsView.Selection? = {
            // Select the previous payment option
            switch previousPaymentOption {
            case .applePay:
                return .applePay
            case .link:
                return .link
            case .external(paymentMethod: let paymentMethod, billingDetails: _):
                return .new(paymentMethodType: .external(paymentMethod))
            case .saved(paymentMethod: let paymentMethod, confirmParams: _):
                return .saved(paymentMethod: paymentMethod)
            case .new(confirmParams: let confirmParams):
                return .new(paymentMethodType: confirmParams.paymentMethodType)
            case nil:
                break
            }

            // If there's no previous customer input, default to the customer's default or the first saved payment method, if any
            let customerDefault = CustomerPaymentOption.defaultPaymentMethod(for: configuration.customer?.id)
            switch customerDefault {
            case .applePay:
                return .applePay
            case .link:
                return .link
            case .stripeId, nil:
                return loadResult.savedPaymentMethods.first.map { .saved(paymentMethod: $0) }
            }
        }()
        let mandateProvider = VerticalListMandateProvider(
            configuration: configuration,
            elementsSession: loadResult.elementsSession,
            intent: loadResult.intent,
            analyticsHelper: analyticsHelper
        )
        return EmbeddedPaymentMethodsView(
            initialSelection: initialSelection,
            paymentMethodTypes: loadResult.paymentMethodTypes,
            savedPaymentMethods: loadResult.savedPaymentMethods,
            appearance: configuration.appearance,
            shouldShowApplePay: shouldShowApplePay,
            shouldShowLink: shouldShowLink,
            savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
            mandateProvider: mandateProvider,
            shouldShowMandate: configuration.embeddedViewDisplaysMandateText,
            delegate: delegate
        )
    }
}

// MARK: - EmbeddedPaymentMethodsViewDelegate

extension EmbeddedPaymentElement: EmbeddedPaymentMethodsViewDelegate {
    func heightDidChange() {
        delegate?.embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: self)
    }

    func selectionDidUpdate() {
        delegate?.embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: self)
    }
    func presentSavedPaymentMethods(selectedSavedPaymentMethod: STPPaymentMethod?) {
        let elementsSession = loadResult.elementsSession
        if savedPaymentMethods.count == 1,
           let paymentMethod = savedPaymentMethods.first,
           paymentMethod.isCoBrandedCard,
           elementsSession.isCardBrandChoiceEligible {
            let updateViewController = UpdateCardViewController(paymentMethod: paymentMethod,
                                                                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                                                                appearance: configuration.appearance,
                                                                hostedSurface: .paymentSheet,
                                                                canRemoveCard: configuration.allowsRemovalOfLastSavedPaymentMethod && elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
                                                                isTestMode: configuration.apiClient.isTestmode,
                                                                cardBrandFilter: configuration.cardBrandFilter)
            updateViewController.delegate = self
            let bottomSheetVC = BottomSheetViewController(contentViewController: updateViewController,
                                                          appearance: configuration.appearance,
                                                          isTestMode: configuration.apiClient.isTestmode, didCancelNative3DS2: {
                self.paymentHandler.cancel3DS2ChallengeFlow()
            })
            presentingViewController?.presentAsBottomSheet(bottomSheetVC, appearance: configuration.appearance)
            return
        }

        let verticalSavedPaymentMethodsViewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: selectedSavedPaymentMethod,
            paymentMethods: savedPaymentMethods,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper
        )
        verticalSavedPaymentMethodsViewController.delegate = self
        let bottomSheetVC = BottomSheetViewController(contentViewController: verticalSavedPaymentMethodsViewController,
                                                      appearance: configuration.appearance,
                                                      isTestMode: configuration.apiClient.isTestmode,
                                                      didCancelNative3DS2: {
            self.paymentHandler.cancel3DS2ChallengeFlow()
        })
        presentingViewController?.presentAsBottomSheet(bottomSheetVC, appearance: configuration.appearance)
    }
}

// MARK: UpdateCardViewControllerDelegate
extension EmbeddedPaymentElement: UpdateCardViewControllerDelegate {
    nonisolated func didRemove(viewController: UpdateCardViewController, paymentMethod: StripePayments.STPPaymentMethod) {
        Task { @MainActor in
            // Detach the payment method from the customer
            savedPaymentMethodManager.detach(paymentMethod: paymentMethod)
            analyticsHelper.logSavedPaymentMethodRemoved(paymentMethod: paymentMethod)

            // Update savedPaymentMethods
            self.savedPaymentMethods.removeAll(where: { $0.stripeId == paymentMethod.stripeId })

            let savedPaymentMethodAccessoryType = accessoryButton(savedPaymentMethods: savedPaymentMethods)
            embeddedPaymentMethodsView.updateSavedPaymentMethods(savedPaymentMethods,
                                                                 userSelectedPaymentMethod: nil,
                                                                 savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType)
            presentingViewController?.dismiss(animated: true)
        }
    }

    func didUpdate(viewController: UpdateCardViewController,
                   paymentMethod: StripePayments.STPPaymentMethod,
                   updateParams: StripePayments.STPPaymentMethodUpdateParams) async throws {
        let updatedPaymentMethod = try await savedPaymentMethodManager.update(paymentMethod: paymentMethod, with: updateParams)

        // Update savedPaymentMethods
        if let row = self.savedPaymentMethods.firstIndex(where: { $0.stripeId == updatedPaymentMethod.stripeId }) {
            self.savedPaymentMethods[row] = updatedPaymentMethod
        }

        let savedPaymentMethodAccessoryType = accessoryButton(savedPaymentMethods: savedPaymentMethods)
        embeddedPaymentMethodsView.updateSavedPaymentMethods(savedPaymentMethods,
                                                             userSelectedPaymentMethod: updatedPaymentMethod,
                                                             savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType)
        Task { @MainActor in
            presentingViewController?.dismiss(animated: true)
        }
    }
    nonisolated func didDismiss(viewController: UpdateCardViewController) {
        Task { @MainActor in
            presentingViewController?.dismiss(animated: true)
        }
    }

    private func accessoryButton(savedPaymentMethods: [STPPaymentMethod]) -> RowButton.RightAccessoryButton.AccessoryType? {
        return RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: savedPaymentMethods.count,
            isFirstCardCoBranded: savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: loadResult.elementsSession.isCardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            allowsPaymentMethodRemoval: loadResult.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        )
    }
}

extension EmbeddedPaymentElement: VerticalSavedPaymentMethodsViewControllerDelegate {
    nonisolated func didComplete(viewController: VerticalSavedPaymentMethodsViewController,
                                 with selectedPaymentMethod: StripePayments.STPPaymentMethod?,
                                 latestPaymentMethods: [StripePayments.STPPaymentMethod]) {
        Task { @MainActor in
            self.savedPaymentMethods = latestPaymentMethods
            let savedPaymentMethodAccessoryType = accessoryButton(savedPaymentMethods: latestPaymentMethods)
            embeddedPaymentMethodsView.updateSavedPaymentMethods(savedPaymentMethods,
                                                                 userSelectedPaymentMethod: selectedPaymentMethod,
                                                                 savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType)
            presentingViewController?.dismiss(animated: true)
        }
    }

    nonisolated func shouldClose() {
        Task { @MainActor in
            presentingViewController?.dismiss(animated: true)
        }
    }
}

// MARK: - EmbeddedPaymentElement.PaymentOptionDisplayData

extension EmbeddedPaymentElement.PaymentOptionDisplayData {
    init(paymentOption: PaymentOption, mandateText: NSAttributedString?) {
        self.mandateText = mandateText
        self.image = paymentOption.makeIcon(updateImageHandler: nil) // ☠️ This can make a blocking network request TODO: https://jira.corp.stripe.com/browse/MOBILESDK-2604 Refactor this!
        switch paymentOption {
        case .applePay:
            label = String.Localized.apple_pay
            paymentMethodType = "apple_pay"
            billingDetails = nil
        case .saved(let paymentMethod, _):
            label = paymentMethod.paymentSheetLabel
            paymentMethodType = paymentMethod.type.identifier
            billingDetails = paymentMethod.billingDetails?.toPaymentSheetBillingDetails()
        case .new(let confirmParams):
            label = confirmParams.paymentSheetLabel
            paymentMethodType = confirmParams.paymentMethodType.identifier
            billingDetails = confirmParams.paymentMethodParams.billingDetails?.toPaymentSheetBillingDetails()
        case .link(let option):
            label = option.paymentSheetLabel
            paymentMethodType = STPPaymentMethodType.link.identifier
            billingDetails = option.billingDetails?.toPaymentSheetBillingDetails()
        case .external(let paymentMethod, let stpBillingDetails):
            label = paymentMethod.label
            paymentMethodType = paymentMethod.type
            billingDetails = stpBillingDetails.toPaymentSheetBillingDetails()
        }
    }
}
