//
//  EmbeddedPaymentElement+Internal.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/10/24.
//

extension EmbeddedPaymentElement {
    @MainActor
    static func makeView(
        configuration: Configuration,
        loadResult: PaymentSheetLoader.LoadResult,
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
            intent: loadResult.intent
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

    struct _UpdateResult {
        let loadResult: PaymentSheetLoader.LoadResult
        let view: EmbeddedPaymentMethodsView
    }

    nonisolated static func update(
        configuration: Configuration,
        intentConfiguration: IntentConfiguration
    ) async throws -> _UpdateResult {
        // TODO: Change dummy analytics helper
        let dummyAnalyticsHelper = PaymentSheetAnalyticsHelper(isCustom: false, configuration: .init())
        let loadResult = try await PaymentSheetLoader.load(
            mode: .deferredIntent(intentConfiguration),
            configuration: configuration,
            analyticsHelper: dummyAnalyticsHelper,
            integrationShape: .embedded
        )
        // 1. Update our variables. Re-initialize embedded view to update the UI to match the newly loaded data.
        let embeddedPaymentMethodsView = await Self.makeView(
            configuration: configuration,
            loadResult: loadResult
            // TODO: https://jira.corp.stripe.com/browse/MOBILESDK-2583 Restore previous payment option
        )

        // 2. Pre-load image into cache
        // Hack: Accessing paymentOption has the side-effect of ensuring its `image` property is loaded (from the internet instead of disk) before we call the completion handler.
        _ = await embeddedPaymentMethodsView.displayData
        return .init(loadResult: loadResult, view: embeddedPaymentMethodsView)
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
}
