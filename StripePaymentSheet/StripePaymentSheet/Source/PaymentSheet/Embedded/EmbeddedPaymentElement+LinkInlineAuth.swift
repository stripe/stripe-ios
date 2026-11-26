//
//  EmbeddedPaymentElement+LinkInlineAuth.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeCore
import UIKit

extension EmbeddedPaymentElement {
    /// Starts inline Link verification if the session's returning Link customer is eligible.
    /// - Parameter logsIneligibility: Whether to log why a returning customer who needs to verify didn't get the card.
    func setUpLinkInlineAuthIfEligible(loadResult: PaymentSheetLoader.LoadResult, logsIneligibility: Bool = false) {
        guard linkInlineAuth == nil, !hasConfirmedIntent else { return }
        let eligibility = EmbeddedLinkInlineVerificationEligibility.evaluate(
            elementsSession: loadResult.elementsSession,
            configuration: configuration,
            linkAccount: LinkAccountContext.shared.account,
            savedPaymentMethods: loadResult.savedPaymentMethods,
            analyticsHelper: analyticsHelper.linkAnalytics
        )
        let eligible: EmbeddedLinkInlineVerificationEligibility.Eligible
        switch eligibility {
        case .success(let value):
            eligible = value
        case .failure(let reason):
            // Only returning customers who need to verify, while the feature is on, say something about the card.
            let isUninteresting: Set<EmbeddedLinkInlineVerificationEligibility.IneligibleReason> = [.disabledByServer, .linkNotDisplayed, .notReturningLinkUser, .alreadyVerified]
            if logsIneligibility, !isUninteresting.contains(reason) {
                analyticsHelper.linkAnalytics.logEmbeddedInlineAuthIneligible(reason: reason.rawValue)
            }
            return
        }
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
            experimentAnalyticsHelper: analyticsHelper.experimentAnalyticsHelper,
            linkAnalyticsHelper: analyticsHelper.linkAnalytics
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

    /// Whether the Link row can open the Link wallet to pick what to pay with.
    /// This is the case once a customer who saw inline verification is verified.
    var linkRowOpensWallet: Bool {
        guard placesLinkFirst else { return false }
        return LinkAccountContext.shared.account?.sessionState == .verified
            && deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration)
    }

    /// Whether selecting the Link row opens the Link wallet, rather than only selecting Link.
    /// - Parameter linkWasSelected: Whether the Link row was already selected, i.e. the customer tapped it again or tapped "Change".
    func linkRowSelectionOpensWallet(linkWasSelected: Bool) -> Bool {
        // The Link-only row always opens Link, which asks the customer to verify again first if their session expired.
        if showsOnlyLink,
           LinkAccountContext.shared.account?.isRegistered == true,
           deviceCanUseNativeLink(elementsSession: elementsSession, configuration: configuration) {
            return linkWasSelected
        }
        guard linkRowOpensWallet else { return false }
        // Selecting Link again keeps the payment details it showed. Tapping it while selected changes them.
        if linkPaymentDetails != nil {
            return linkWasSelected
        }
        // With nothing picked yet, `.confirm` pays in the Link wallet at confirm time instead.
        if case .confirm = configuration.formSheetAction {
            return false
        }
        return true
    }

    /// The Link payment details the Link row shows and pays with, if they're still usable.
    var linkPaymentDetails: ConsumerPaymentDetails? {
        guard let linkConfirmOption, isLinkConfirmOptionStillValid(linkConfirmOption),
              case .withPaymentDetails(_, _, let paymentDetails, _, _) = linkConfirmOption else {
            return nil
        }
        return paymentDetails
    }

    /// The context the Link wallet would use to pick payment details, for deciding what to pay with without opening it.
    func makeLinkContext(linkAccount: PaymentSheetLinkAccount?) -> PayWithLinkViewController.Context {
        PayWithLinkViewController.Context(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            customerProvider: loadResult.customerProvider,
            linkBrand: configuration.resolvedLinkBrand(elementsSession: elementsSession, linkAccount: linkAccount),
            shouldOfferApplePay: false,
            shouldFinishOnClose: false,
            launchedFromFlowController: true,
            initiallySelectedPaymentDetailsID: nil,
            callToAction: .continue,
            analyticsHelper: analyticsHelper
        )
    }

    /// The mandate and bank data-sharing consent the Link wallet shows for `paymentDetails`, combined.
    static func linkMandateText(for paymentDetails: ConsumerPaymentDetails, context: PayWithLinkViewController.Context) -> NSAttributedString? {
        let texts = [
            PayWithLinkViewController.WalletViewModel.mandate(for: paymentDetails, context: context),
            PayWithLinkViewController.WalletViewModel.bankAccountDataConsent(for: paymentDetails, context: context),
        ].compactMap { $0 }
        guard let first = texts.first else { return nil }
        let combined = NSMutableAttributedString(attributedString: first)
        for text in texts.dropFirst() {
            combined.append(NSAttributedString(string: "\n\n"))
            combined.append(text)
        }
        return combined
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
            customerProvider: loadResult.customerProvider,
            nativeSheetPresentation: nativeSheetPresentation,
            intent: intent,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper
        ) { [weak self] confirmOption, shouldReturnToPaymentSheet, _ in
            guard let self else { return }
            self.linkWalletDidFinish(
                with: confirmOption,
                shouldReturnToPaymentSheet: shouldReturnToPaymentSheet,
                revertsSelectionOnClose: revertsSelectionOnClose
            )
        }
    }

    /// - Parameter shouldReturnToPaymentSheet: Whether the customer chose to pay another way, rather than closing the wallet.
    func linkWalletDidFinish(
        with confirmOption: PaymentSheet.LinkConfirmOption?,
        shouldReturnToPaymentSheet: Bool = false,
        revertsSelectionOnClose: Bool
    ) {
        guard let confirmOption else {
            if shouldReturnToPaymentSheet, showsOnlyLink {
                analyticsHelper.linkAnalytics.logEmbeddedInlineAuthPaidAnotherWay()
                payAnotherWay()
                return
            }
            analyticsHelper.linkAnalytics.logEmbeddedInlineAuthWalletClosed()
            if revertsSelectionOnClose, embeddedPaymentMethodsView.selectedRowButton?.type == .link {
                restoreSelectionBeforeLink()
            }
            return
        }
        analyticsHelper.linkAnalytics.logEmbeddedInlineAuthWalletSelected()
        // The wallet showed its mandate and records its bank data-sharing consent itself.
        preselectedLinkPaymentDetailsID = nil
        selectLink(with: confirmOption)
    }

    /// Shows every payment method again, with none selected, so the customer can pick something other than Link.
    private func payAnotherWay() {
        linkConfirmOption = nil
        preselectedLinkPaymentDetailsID = nil
        remakeEmbeddedPaymentMethodsView(selection: nil, linkOnlyPaymentDetails: nil)
        informDelegateIfPaymentOptionUpdated()
    }

    /// Selects the Link row to pay with `confirmOption`. With payment details, Link becomes the only row.
    private func selectLink(with confirmOption: PaymentSheet.LinkConfirmOption) {
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
        if showsOnlyLink || linkPaymentDetails != nil {
            // Shows the payment details on the Link-only row. Without any, e.g. for `.wallet`, the list shows every payment method instead.
            remakeEmbeddedPaymentMethodsView(selection: .link, linkOnlyPaymentDetails: linkPaymentDetails)
        }
        updateChangeButtonAndSublabelState(for: .link)
        persistDefaultPaymentMethodSelection(.link)
        informDelegateIfPaymentOptionUpdated()
        completeImmediateRowSelectionIfNeeded()
    }

    private func restoreSelectionBeforeLink() {
        embeddedPaymentMethodsView.resetSelectionToLastSelection()
        _ = restoreAcceptedForm(
            from: paymentOptionToRestoreAfterLinkWallet,
            for: embeddedPaymentMethodsView.selectedRowButton?.type
        )
        paymentOptionToRestoreAfterLinkWallet = nil
        if let restoredSelection = embeddedPaymentMethodsView.selectedRowButton?.type {
            updateChangeButtonAndSublabelState(for: restoredSelection)
        }
        informDelegateIfPaymentOptionUpdated()
    }

    // MARK: - Preselecting Link payment details

    enum LinkPreselectionFallbackReason: String, Error {
        case noSupportedTypes = "no_supported_types"
        case loadFailed = "load_failed"
        case noPaymentDetails = "no_payment_details"
        case unsupported
        case needsCardDetails = "needs_card_details"
        case needsBillingDetails = "needs_billing_details"
        /// With `.immediateAction`, the merchant moves on right away, so the customer wouldn't see the mandate below the list.
        case mandateNotVisible = "mandate_not_visible"
    }

    /// After a customer verifies inline, selects the Link row with the payment details the Link wallet would select first, usually their default.
    /// Opens the Link wallet instead if those payment details can't be used without it.
    func preselectDefaultLinkPaymentMethod() {
        guard linkPreselectionTask == nil else { return }
        guard let linkAccount = LinkAccountContext.shared.account, linkAccount.sessionState == .verified else { return }
        let selectionBeforePreselecting = embeddedPaymentMethodsView.selectedRowButton?.type
        embeddedPaymentMethodsView.setLinkRowLoading(true)
        linkPreselectionTask = Task { @MainActor [weak self] in
            guard let self else { return }
            let result = await self.loadDefaultLinkConfirmOption(linkAccount: linkAccount)
            self.finishPreselectingLinkPaymentMethod(result, linkAccount: linkAccount, selectionBeforePreselecting: selectionBeforePreselecting)
        }
    }

    private func loadDefaultLinkConfirmOption(linkAccount: PaymentSheetLinkAccount) async -> Result<PaymentSheet.LinkConfirmOption, LinkPreselectionFallbackReason> {
        let supportedTypes = makeLinkContext(linkAccount: linkAccount).getSupportedPaymentDetailsTypes(linkAccount: linkAccount)
        guard !supportedTypes.isEmpty else { return .failure(.noSupportedTypes) }
        // Like the Link wallet, which also fetches the shipping address when it's opened to pick payment details.
        let shippingAddressTask = Task {
            try? await linkAccount.listShippingAddress(shouldRetryOnAuthError: false)
        }
        defer { shippingAddressTask.cancel() }
        let paymentDetails: [ConsumerPaymentDetails]
        do {
            paymentDetails = try await linkAccount.listPaymentDetails(supportedTypes: supportedTypes.toSortedArray(), shouldRetryOnAuthError: false)
        } catch {
            return .failure(.loadFailed)
        }
        let shippingAddresses = await shippingAddressTask.value?.shippingAddresses
        let shippingAddress = shippingAddresses?.first { $0.isDefault ?? false } ?? shippingAddresses?.first
        return await defaultLinkConfirmOption(in: paymentDetails, linkAccount: linkAccount, shippingAddress: shippingAddress)
    }

    /// Picks the payment details the Link wallet would select first, if they can be used without opening it.
    func defaultLinkConfirmOption(
        in paymentDetails: [ConsumerPaymentDetails],
        linkAccount: PaymentSheetLinkAccount,
        shippingAddress: ShippingAddressesResponse.ShippingAddress?
    ) async -> Result<PaymentSheet.LinkConfirmOption, LinkPreselectionFallbackReason> {
        let context = makeLinkContext(linkAccount: linkAccount)
        let viewModel = PayWithLinkViewController.WalletViewModel(linkAccount: linkAccount, context: context, paymentMethods: paymentDetails)
        guard let selectedPaymentDetails = viewModel.selectedPaymentMethod else { return .failure(.noPaymentDetails) }
        guard viewModel.selectedPaymentMethodIsSupported else { return .failure(.unsupported) }
        guard !viewModel.shouldRecollectCardCVC, !viewModel.shouldRecollectCardExpiryDate else { return .failure(.needsCardDetails) }
        if case .immediateAction = configuration.rowSelectionBehavior, configuration.embeddedViewDisplaysMandateText,
           Self.linkMandateText(for: selectedPaymentDetails, context: context) != nil {
            return .failure(.mandateNotVisible)
        }
        guard case let .complete(updatedPaymentDetails, confirmationExtras) = await LinkBillingDetailsValidator(linkAccount: linkAccount, context: context).validate(selectedPaymentDetails) else {
            return .failure(.needsBillingDetails)
        }
        return .success(.withPaymentDetails(
            brand: context.linkBrand,
            account: linkAccount,
            paymentDetails: updatedPaymentDetails,
            confirmationExtras: confirmationExtras,
            shippingAddress: shippingAddress
        ))
    }

    func finishPreselectingLinkPaymentMethod(
        _ result: Result<PaymentSheet.LinkConfirmOption, LinkPreselectionFallbackReason>,
        linkAccount: PaymentSheetLinkAccount,
        selectionBeforePreselecting: RowButtonType?
    ) {
        linkPreselectionTask = nil
        embeddedPaymentMethodsView.setLinkRowLoading(false)
        // Drop the result if the account changed, or the selection changed some other way, e.g. the merchant cleared it.
        guard !hasConfirmedIntent,
              LinkAccountContext.shared.account === linkAccount,
              linkAccount.sessionState == .verified,
              embeddedPaymentMethodsView.selectedRowButton?.type == selectionBeforePreselecting else {
            return
        }
        switch result {
        case .success(let confirmOption):
            if case .withPaymentDetails(_, _, let paymentDetails, _, _) = confirmOption {
                preselectedLinkPaymentDetailsID = paymentDetails.stripeID
                analyticsHelper.linkAnalytics.logEmbeddedInlineAuthPreselected(paymentDetailsType: paymentDetails.type.rawValue)
            }
            selectLink(with: confirmOption)
        case .failure(let reason):
            analyticsHelper.linkAnalytics.logEmbeddedInlineAuthPreselectionFellBack(reason: reason.rawValue)
            switch configuration.formSheetAction {
            case .continue:
                presentLinkWallet(revertsSelectionOnClose: false)
            case .confirm(let completion):
                payInLinkWallet(completion: completion)
            }
        }
    }

    /// Records the bank data-sharing consent shown below the list, before paying with bank account details preselected after verifying.
    /// The Link wallet records it itself for payment details picked there.
    func recordLinkBankAccountConsentIfNeeded(for paymentOption: PaymentOption) async {
        guard case .link(.withPaymentDetails(_, let linkAccount, let paymentDetails, _, _)) = paymentOption,
              paymentDetails.stripeID == preselectedLinkPaymentDetailsID else {
            return
        }
        await PayWithLinkViewController.WalletViewModel.recordBankAccountConsentIfNeeded(
            for: paymentDetails,
            linkAccount: linkAccount,
            elementsSession: elementsSession
        )
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
        preselectDefaultLinkPaymentMethod()
    }
}
