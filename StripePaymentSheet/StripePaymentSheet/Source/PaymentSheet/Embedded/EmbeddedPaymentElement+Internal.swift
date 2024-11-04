//
//  EmbeddedPaymentElement+Internal.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/10/24.
//

@_spi(STP) import StripeCore

extension EmbeddedPaymentElement {
    @MainActor
    static func makeView(
        configuration: Configuration,
        loadResult: PaymentSheetLoader.LoadResult,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        delegate: EmbeddedPaymentMethodsViewDelegate? = nil
    ) -> EmbeddedPaymentMethodsView {
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
            // Default to the customer's default or the first saved payment method, if any
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
            savedPaymentMethod: loadResult.savedPaymentMethods.first,
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
        guard case let .new(paymentMethodType) = embeddedPaymentMethodsView.selection else {
            return
        }

        guard let presentingVC = presentingViewController else {
            assertionFailure("Presenting view controller not found, set EmbeddedPaymentElement.presentingViewController.")
            return
        }

        let embeddedFormVC = EmbeddedFormViewController(
            configuration: configuration,
            loadResult: loadResult,
            paymentMethodType: paymentMethodType,
            previousPaymentOption: lastSeenPaymentOption,
            analyticsHelper: analyticsHelper,
            formCache: formCache
        )
        embeddedFormVC.delegate = self

        // Only show forms that require user input
        guard embeddedFormVC.collectsUserInput else { return }

        let bottomSheet = BottomSheetViewController(
            contentViewController: embeddedFormVC,
            appearance: configuration.appearance,
            isTestMode: configuration.apiClient.isTestmode,
            didCancelNative3DS2: {}
        )

        delegate?.embeddedPaymentElementWillPresent(embeddedPaymentElement: self)
        presentingVC.presentAsBottomSheet(bottomSheet, appearance: configuration.appearance)
        self.formViewController = embeddedFormVC
    }
}

extension EmbeddedPaymentElement: EmbeddedFormViewControllerDelegate {
    func embeddedFormViewControllerShouldConfirm(_ embeddedFormViewController: EmbeddedFormViewController, with paymentOption: PaymentOption, completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void) {
        // TODO(porter)
    }
    
    func embeddedFormViewControllerShouldContinue(_ embeddedFormViewController: EmbeddedFormViewController, result: PaymentSheetResult) {
        // TODO(porter)
    }
    
    func embeddedFormViewControllerDidCancel(_ embeddedFormViewController: EmbeddedFormViewController) {
        embeddedPaymentMethodsView.resetSelection()
        embeddedFormViewController.dismiss(animated: true)
    }
    
    func embeddedFormViewControllerShouldClose(_ embeddedFormViewController: EmbeddedFormViewController) {
        self.lastSeenPaymentOption = embeddedFormViewController.selectedPaymentOption
        if embeddedFormViewController.selectedPaymentOption == nil {
            embeddedPaymentMethodsView.resetSelection()
        }
        embeddedFormViewController.dismiss(animated: true)
    }
    
}
