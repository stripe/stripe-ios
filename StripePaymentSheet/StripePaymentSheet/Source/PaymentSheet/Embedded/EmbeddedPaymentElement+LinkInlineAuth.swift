//
//  EmbeddedPaymentElement+LinkInlineAuth.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeCore
import UIKit

extension EmbeddedPaymentElement {
    /// Starts inline Link verification if the session's returning Link customer is eligible.
    func setUpLinkInlineAuthIfEligible(loadResult: PaymentSheetLoader.LoadResult) {
        guard linkInlineAuth == nil, !hasConfirmedIntent else { return }
        let eligibility = EmbeddedLinkInlineVerificationEligibility.evaluate(
            elementsSession: loadResult.elementsSession,
            configuration: configuration,
            linkAccount: LinkAccountContext.shared.account,
            savedPaymentMethods: loadResult.savedPaymentMethods,
            analyticsHelper: analyticsHelper.linkAnalytics
        )
        guard case .success(let eligible) = eligibility else { return }
        let experiment = EmbeddedLinkInlineVerificationExperiment(
            elementsSession: loadResult.elementsSession,
            dimensions: Self.linkInlineVerificationExperimentDimensions(
                configuration: configuration,
                loadResult: loadResult,
                coordinator: eligible.coordinator
            )
        )
        let controller = EmbeddedLinkInlineAuthController(
            eligible: eligible,
            experiment: experiment,
            configuration: configuration,
            linkBrand: configuration.resolvedLinkBrand(elementsSession: loadResult.elementsSession, linkAccount: eligible.linkAccount),
            experimentAnalyticsHelper: analyticsHelper.experimentAnalyticsHelper
        )
        controller.host = self
        linkInlineAuth = controller
        if controller.showsCard {
            placesLinkFirst = true
        }
        // Watches the container, which stays put when updates replace the list.
        let monitor = EmbeddedVisibilityMonitor(view: containerView) { [weak controller] in
            controller?.elementBecameVisible()
        }
        linkInlineAuthVisibilityMonitor = monitor
        monitor.viewDidMoveToWindow()
    }

    /// Keeps the current inline verification across an update if it can continue, otherwise ends it and checks eligibility again.
    func refreshLinkInlineAuth(loadResult: PaymentSheetLoader.LoadResult) {
        if let linkInlineAuth {
            // The account itself is preserved across updates, so only recheck what an update can change.
            let canContinue = linkInlineAuth.phase != .finished
                && loadResult.elementsSession.linkEmbeddedInlineVerificationEnabled
                && PaymentSheet.shouldShowLinkButton(elementsSession: loadResult.elementsSession, configuration: configuration)
                && LinkAccountContext.shared.account === linkInlineAuth.linkAccount
            guard !canContinue else { return }
            linkInlineAuth.invalidate()
            self.linkInlineAuth = nil
            linkInlineAuthVisibilityMonitor = nil
        }
        setUpLinkInlineAuthIfEligible(loadResult: loadResult)
    }

    static func linkInlineVerificationExperimentDimensions(
        configuration: Configuration,
        loadResult: PaymentSheetLoader.LoadResult,
        coordinator: LinkAuthFlowCoordinator
    ) -> [String: String] {
        let paymentMethodTypes = loadResult.paymentMethodTypes.map(\.identifier)
        let isApplePayEnabled = PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let rowStyle: String = switch configuration.appearance.embeddedPaymentElement.row.style {
        case .flatWithRadio: "flat_with_radio"
        case .floatingButton: "floating_button"
        case .flatWithCheckmark: "flat_with_checkmark"
        case .flatWithDisclosure: "flat_with_disclosure"
        }
        let formSheetAction: String = switch configuration.formSheetAction {
        case .confirm: "confirm"
        case .continue: "continue"
        }
        let rowSelectionBehavior: String = switch configuration.rowSelectionBehavior {
        case .default: "default"
        case .immediateAction: "immediate_action"
        }
        return [
            "displayed_payment_method_types": paymentMethodTypes.joined(separator: ","),
            "displayed_payment_method_types_including_wallets": (paymentMethodTypes + (isApplePayEnabled ? ["apple_pay"] : []) + ["link"]).joined(separator: ","),
            "has_saved_payment_method": (!loadResult.savedPaymentMethods.isEmpty).description,
            "embedded_row_style": rowStyle,
            "embedded_form_sheet_action": formSheetAction,
            "embedded_row_selection_behavior": rowSelectionBehavior,
            "link_verification_methods": coordinator.actions.contains(.email) ? "sms_email" : "sms",
            "large_text_size": UITraitCollection.current.preferredContentSizeCategory.isAccessibilityCategory.description,
        ]
    }
}

extension EmbeddedPaymentElement: EmbeddedLinkInlineAuthControllerHost {
    func linkInlineAuthPresentingViewController() -> UIViewController? {
        guard let presentingViewController = resolvedPresentingViewController, presentingViewController.presentedViewController == nil else {
            return nil
        }
        return presentingViewController
    }

    func linkInlineAuthWillPresent() {
        delegate?.embeddedPaymentElementWillPresent(embeddedPaymentElement: self)
    }

    func linkInlineAuthDidCollapse() {
        embeddedPaymentMethodsView.collapseLinkInlineVerification(animated: true)
        embeddedPaymentMethodsView.updateLinkRow(for: LinkAccountContext.shared.account, animated: false)
        informDelegateIfPaymentOptionUpdated()
    }

    func linkInlineAuthDidVerify() {
        // Verifying changes the account in place, which LinkAccountContext doesn't announce.
        embeddedPaymentMethodsView.updateLinkRow(for: LinkAccountContext.shared.account, animated: true)
        informDelegateIfPaymentOptionUpdated()
    }
}
