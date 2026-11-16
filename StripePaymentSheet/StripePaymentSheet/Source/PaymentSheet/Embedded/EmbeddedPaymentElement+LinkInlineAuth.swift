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
            forcesDialog: loadResult.elementsSession.linkEmbeddedInlineVerificationForcesDialog,
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
            guard !canContinue else {
                linkInlineAuth.forcesDialog = loadResult.elementsSession.linkEmbeddedInlineVerificationForcesDialog
                return
            }
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

    // MARK: - Link wallet

    /// Whether tapping the Link row opens the Link wallet to pick what to pay with, rather than only selecting Link.
    /// This is the case once a customer who saw inline verification is verified.
    var linkRowOpensWallet: Bool {
        guard placesLinkFirst, case .continue = configuration.formSheetAction else { return false }
        return LinkAccountContext.shared.account?.sessionState == .verified
            && deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration)
    }

    /// Opens the Link wallet so the customer can pick a payment method, then selects the Link row with it.
    /// - Parameter revertsSelectionOnClose: Whether closing the wallet without picking anything restores the previously selected row.
    func presentLinkWallet(revertsSelectionOnClose: Bool) {
        guard let presenter = linkInlineAuthPresentingViewController() else {
            if revertsSelectionOnClose {
                restoreSelectionBeforeLink()
            }
            return
        }
        delegate?.embeddedPaymentElementWillPresent(embeddedPaymentElement: self)
        presenter.presentNativeLink(
            selectedPaymentDetailsID: linkConfirmOption.flatMap { PaymentOption.link(option: $0).currentLinkPaymentMethod },
            configuration: configuration,
            nativeSheetPresentation: nativeSheetPresentation,
            intent: intent,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper
        ) { [weak self] confirmOption, _, _ in
            self?.linkWalletDidFinish(with: confirmOption, revertsSelectionOnClose: revertsSelectionOnClose)
        }
    }

    func linkWalletDidFinish(with confirmOption: PaymentSheet.LinkConfirmOption?, revertsSelectionOnClose: Bool) {
        guard let confirmOption else {
            if revertsSelectionOnClose, embeddedPaymentMethodsView.selectedRowButton?.type == .link {
                restoreSelectionBeforeLink()
            }
            return
        }
        // `.wallet` means the wallet couldn't hand back payment details, so Link pays through the wallet at confirm time.
        if case .wallet = confirmOption {
            linkConfirmOption = nil
        } else {
            linkConfirmOption = confirmOption
        }
        guard embeddedPaymentMethodsView.selectedRowButton?.type == .link || embeddedPaymentMethodsView.selectLinkRow() else {
            linkConfirmOption = nil
            return
        }
        updateChangeButtonAndSublabelState(for: .link)
        persistDefaultPaymentMethodSelection(.link)
        informDelegateIfPaymentOptionUpdated()
        completeImmediateRowSelectionIfNeeded()
    }

    private func restoreSelectionBeforeLink() {
        embeddedPaymentMethodsView.resetSelectionToLastSelection()
        if let restoredSelection = embeddedPaymentMethodsView.selectedRowButton?.type {
            updateChangeButtonAndSublabelState(for: restoredSelection)
        }
        informDelegateIfPaymentOptionUpdated()
    }

    /// With `formSheetAction = .confirm`, a customer who verifies inline pays in the Link wallet, the same way a form sheet pays.
    private func payInLinkWallet(completion: @escaping (PaymentSheetResult) -> Void) {
        guard let presenter = linkInlineAuthPresentingViewController() else { return }
        delegate?.embeddedPaymentElementWillPresent(embeddedPaymentElement: self)
        Task { @MainActor [weak self] in
            guard let self else { return }
            _ = await self.latestUpdateTask?.value
            let authContext = PaymentSheetAuthenticationContextViewController(presentingViewController: presenter, appearance: self.configuration.appearance)
            let brand = self.configuration.resolvedLinkBrand(elementsSession: self.elementsSession, linkAccount: LinkAccountContext.shared.account)
            let result = await self._confirm(paymentOption: .link(option: .wallet(brand: brand)), authContext: authContext).result
            completion(result)
        }
    }
}

extension EmbeddedPaymentElement: EmbeddedLinkInlineAuthControllerHost {
    func linkInlineAuthPresentingViewController() -> UIViewController? {
        guard let presentingViewController = resolvedPresentingViewController,
              presentingViewController.presentedViewController == nil,
              presentingViewController.viewIfLoaded?.window != nil else {
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

    func linkInlineAuthDidVerify(fromCard: Bool) {
        // Verifying changes the account in place, which LinkAccountContext doesn't announce.
        embeddedPaymentMethodsView.updateLinkRow(for: LinkAccountContext.shared.account, animated: true)
        informDelegateIfPaymentOptionUpdated()
        guard fromCard else { return }
        switch configuration.formSheetAction {
        case .continue:
            presentLinkWallet(revertsSelectionOnClose: false)
        case .confirm(let completion):
            payInLinkWallet(completion: completion)
        }
    }
}
