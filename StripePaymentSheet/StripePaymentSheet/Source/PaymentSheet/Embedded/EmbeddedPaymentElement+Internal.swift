//
//  EmbeddedPaymentElement+Internal.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 10/10/24.
//
import SafariServices
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
        previousSelection: RowButtonType? = nil,
        previousSelectedRowChangeButtonState: (shouldShowChangeButton: Bool, sublabel: String?)? = nil,
        delegate: EmbeddedPaymentMethodsViewDelegate? = nil
    ) -> EmbeddedPaymentMethodsView {
        // Restore the customer's previous payment method.
        // Caveats:
        // - Only payment method details (including checkbox state) and billing details are restored
        // - Only restored if the previous input resulted in a completed form i.e. partial or invalid input is still discarded

        let shouldShowApplePay = PaymentSheet.isApplePayEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let shouldShowLink = PaymentSheet.isLinkEnabled(elementsSession: loadResult.elementsSession, configuration: configuration)
        let savedPaymentMethodAccessoryType = RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: loadResult.savedPaymentMethods.count,
            isFirstCardCoBranded: loadResult.savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: loadResult.elementsSession.isCardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: loadResult.elementsSession.paymentMethodRemoveLast(configuration: configuration),
            allowsPaymentMethodRemoval: loadResult.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
            allowsPaymentMethodUpdate: loadResult.elementsSession.paymentMethodUpdateForPaymentSheet,
            omitChevron: configuration.appearance.embeddedPaymentElement.row.style.omitChevronInAccessoryButton
        )
        let initialSelection: RowButtonType? = {
            // First, respect the previous selection
            if let previousSelection {
                return previousSelection
            }

            // If there's no previous customer input, default to the customer's default or the first saved payment method, if any
            let customerDefault = CustomerPaymentOption.selectedPaymentMethod(for: configuration.customer?.id, elementsSession: loadResult.elementsSession, surface: .paymentSheet)
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
            initialSelectedRowType: initialSelection,
            initialSelectedRowChangeButtonState: previousSelectedRowChangeButtonState,
            paymentMethodTypes: loadResult.paymentMethodTypes,
            savedPaymentMethod: loadResult.savedPaymentMethods.first,
            appearance: configuration.appearance,
            shouldShowApplePay: shouldShowApplePay,
            shouldShowLink: shouldShowLink,
            savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
            mandateProvider: mandateProvider,
            shouldShowMandate: configuration.embeddedViewDisplaysMandateText,
            savedPaymentMethods: loadResult.savedPaymentMethods,
            customer: configuration.customer,
            currency: loadResult.intent.currency,
            incentive: loadResult.elementsSession.incentive,
            analyticsHelper: analyticsHelper,
            delegate: delegate
        )
    }

    /// Helper method to inform delegate only if the payment option changed
    func informDelegateIfPaymentOptionUpdated() {
        if lastUpdatedPaymentOption != paymentOption {
            delegate?.embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: self)
            lastUpdatedPaymentOption = paymentOption
        }
    }

    // Helper method to create Form VC for a payment method row, if applicable.
    static func makeFormViewControllerIfNecessary(
        selection: RowButtonType?,
        previousPaymentOption: PaymentOption?,
        configuration: Configuration,
        intent: Intent,
        elementsSession: STPElementsSession,
        savedPaymentMethods: [STPPaymentMethod],
        analyticsHelper: PaymentSheetAnalyticsHelper,
        formCache: PaymentMethodFormCache,
        delegate: EmbeddedFormViewControllerDelegate
    ) -> EmbeddedFormViewController? {
        guard case let .new(paymentMethodType) = selection else {
            return nil
        }

        let formViewController = EmbeddedFormViewController(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession,
            shouldUseNewCardNewCardHeader: savedPaymentMethods.first?.type == .card,
            paymentMethodType: paymentMethodType,
            previousPaymentOption: previousPaymentOption,
            analyticsHelper: analyticsHelper,
            formCache: formCache,
            delegate: delegate
        )

        if Self.shouldShowForm(formViewController.form, configuration: configuration) {
            return formViewController
        } else {
            return nil
        }
    }
}

// MARK: - EmbeddedPaymentMethodsViewDelegate

extension EmbeddedPaymentElement: EmbeddedPaymentMethodsViewDelegate {
    func embeddedPaymentMethodsViewDidUpdateHeight() {
        delegate?.embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: self)
    }

    func embeddedPaymentMethodsViewDidUpdateSelection() {
        // 1. Update the currently selection's form VC to match the selection.
        // Note `paymentOption` derives from this property
        self.selectedFormViewController = Self.makeFormViewControllerIfNecessary(
            selection: embeddedPaymentMethodsView.selectedRowButton?.type,
            previousPaymentOption: selectedFormViewController?.previousPaymentOption,
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: savedPaymentMethods,
            analyticsHelper: analyticsHelper,
            formCache: formCache,
            delegate: self
        )

        // 2. Inform the delegate of the updated payment option if there is no form. If there is a form, we don't want to inform the delegate b/c the paymentOption is in an indeterminate state until the customer completes or cancels out of the form.
        if self.selectedFormViewController == nil {
            informDelegateIfPaymentOptionUpdated()
        }
    }

    func embeddedPaymentMethodsViewDidTapPaymentMethodRow() {
        // 😓 Note: This method depends on `embeddedPaymentMethodsViewDidUpdateSelection` being called *before* this method is called when a row is tapped.
        guard let selectedFormViewController else {
            // If the current selection has no form VC, simply alert the merchant of the selection if they are using immediateAction
            if case .immediateAction(let didSelectPaymentOption) = configuration.rowSelectionBehavior {
                didSelectPaymentOption()
            }
            return
        }
        // Present the current selection's form VC
        delegate?.embeddedPaymentElementWillPresent(embeddedPaymentElement: self)
        let bottomSheet = bottomSheetController(with: selectedFormViewController)
        assert(presentingViewController != nil, "Presenting view controller not found, set EmbeddedPaymentElement.presentingViewController.")
        stpAssert(selectedFormViewController.delegate != nil)
        presentingViewController?.presentAsBottomSheet(bottomSheet, appearance: configuration.appearance)
    }

    func embeddedPaymentMethodsViewDidTapViewMoreSavedPaymentMethods(selectedSavedPaymentMethod: STPPaymentMethod?) {
        // Special case, only 1 card remaining, skip showing the list and show update view controller
        if savedPaymentMethods.count == 1,
           let paymentMethod = savedPaymentMethods.first {
            let updateConfig = UpdatePaymentMethodViewController.Configuration(paymentMethod: paymentMethod,
                                                                               appearance: configuration.appearance,
                                                                               billingDetailsCollectionConfiguration: configuration.billingDetailsCollectionConfiguration,
                                                                               hostedSurface: .paymentSheet,
                                                                               cardBrandFilter: configuration.cardBrandFilter,
                                                                               canRemove: elementsSession.paymentMethodRemoveLast(configuration: configuration) && elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
                                                                               canUpdate: elementsSession.paymentMethodUpdateForPaymentSheet,
                                                                               isCBCEligible: paymentMethod.isCoBrandedCard && elementsSession.isCardBrandChoiceEligible,
                                                                               allowsSetAsDefaultPM: elementsSession.paymentMethodSetAsDefaultForPaymentSheet,
                                                                               isDefault: paymentMethod == defaultPaymentMethod)
            let removeSavedPaymentMethodMessage = UpdatePaymentMethodViewController.resolveRemoveMessage(
                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                paymentMethodRemoveIsPartial: elementsSession.paymentMethodRemoveIsPartialForPaymentSheet(),
                merchantName: configuration.merchantDisplayName)
            let updateViewController = UpdatePaymentMethodViewController(removeSavedPaymentMethodMessage: removeSavedPaymentMethodMessage,
                                                                         isTestMode: configuration.apiClient.isTestmode,
                                                                         configuration: updateConfig)
            updateViewController.delegate = self
            let bottomSheetVC = bottomSheetController(with: updateViewController)
            presentingViewController?.presentAsBottomSheet(bottomSheetVC, appearance: configuration.appearance)
            return
        }

        let verticalSavedPaymentMethodsViewController = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: selectedSavedPaymentMethod,
            paymentMethods: savedPaymentMethods,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper,
            defaultPaymentMethod: defaultPaymentMethod
        )
        verticalSavedPaymentMethodsViewController.delegate = self
        let bottomSheetVC = bottomSheetController(with: verticalSavedPaymentMethodsViewController)
        presentingViewController?.presentAsBottomSheet(bottomSheetVC, appearance: configuration.appearance)
    }

    func shouldAnimateOnPress(_ paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        let formViewController = EmbeddedFormViewController(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession,
            shouldUseNewCardNewCardHeader: savedPaymentMethods.first?.type == .card,
            paymentMethodType: paymentMethodType,
            previousPaymentOption: nil,
            analyticsHelper: analyticsHelper,
            formCache: .init(),  // Use a fresh form cache to ensure forms aren't re-added to a different view controller's hierarchy
            delegate: self
        )

        // Show an animation on the label if the payment method shows a form
        return formViewController.collectsUserInput
    }
}

// MARK: UpdatePaymentMethodViewControllerDelegate
extension EmbeddedPaymentElement: UpdatePaymentMethodViewControllerDelegate {
    func didRemove(viewController: UpdatePaymentMethodViewController, paymentMethod: StripePayments.STPPaymentMethod) {
        // Detach the payment method from the customer
        savedPaymentMethodManager.detach(paymentMethod: paymentMethod)
        analyticsHelper.logSavedPaymentMethodRemoved(paymentMethod: paymentMethod)

        // if it's the default pm, unset it
        if paymentMethod == defaultPaymentMethod {
            defaultPaymentMethod = nil
        }

        // Update savedPaymentMethods
        self.savedPaymentMethods.removeAll(where: { $0.stripeId == paymentMethod.stripeId })

        let accessoryType = getAccessoryButton(savedPaymentMethods: savedPaymentMethods)
        embeddedPaymentMethodsView.updateSavedPaymentMethodRow(savedPaymentMethods,
                                                               isSelected: false,
                                                               accessoryType: accessoryType)
        presentingViewController?.dismiss(animated: true)
    }

    func didUpdate(viewController: UpdatePaymentMethodViewController,
                   paymentMethod: StripePayments.STPPaymentMethod) async -> UpdatePaymentMethodResult {
        var errors: [Error] = []

        // Perform update if needed
        if let updateParams = viewController.updateParams,
           case .card(let paymentMethodCardParams, let billingDetails) = updateParams {
            let updateParams = STPPaymentMethodUpdateParams(card: paymentMethodCardParams, billingDetails: billingDetails)
            let hasOnlyChangedCardBrand = viewController.hasOnlyChangedCardBrand(originalPaymentMethod: paymentMethod,
                                                                                 updatedPaymentMethodCardParams: paymentMethodCardParams,
                                                                                 updatedBillingDetailsParams: billingDetails)
            if case .failure(let error) = await updateCard(paymentMethod: paymentMethod,
                                                           updateParams: updateParams,
                                                           hasOnlyChangedCardBrand: hasOnlyChangedCardBrand) {
                errors.append(error)
            }
        }

        // Update default payment method if needed
        if viewController.shouldSetAsDefault {
            if case .failure(let error) = await updateDefault(paymentMethod: paymentMethod) {
                errors.append(error)
            }
        }

        guard errors.isEmpty else {
            return .failure(errors)
        }

        let accessoryType = getAccessoryButton(savedPaymentMethods: savedPaymentMethods)
        let isSelected = embeddedPaymentMethodsView.selectedRowButton?.type.isSaved ?? false
        embeddedPaymentMethodsView.updateSavedPaymentMethodRow(savedPaymentMethods,
                                                               isSelected: isSelected,
                                                               accessoryType: accessoryType)
        presentingViewController?.dismiss(animated: true)
        return .success
    }

    private func updateCard(paymentMethod: StripePayments.STPPaymentMethod,
                            updateParams: StripePayments.STPPaymentMethodUpdateParams,
                            hasOnlyChangedCardBrand: Bool) async -> Result<Void, Error> {
        do {
            let updatedPaymentMethod = try await savedPaymentMethodManager.update(paymentMethod: paymentMethod, with: updateParams)

            // Update savedPaymentMethods
            if let row = self.savedPaymentMethods.firstIndex(where: { $0.stripeId == updatedPaymentMethod.stripeId }) {
                self.savedPaymentMethods[row] = updatedPaymentMethod
            }
            return .success(())
        } catch {
            return hasOnlyChangedCardBrand ? .failure(NSError.stp_cardBrandNotUpdatedError()) : .failure(NSError.stp_genericErrorOccurredError())
        }
    }

    private func updateDefault(paymentMethod: StripePayments.STPPaymentMethod) async -> Result<Void, Error> {
        do {
            _ = try await savedPaymentMethodManager.setAsDefaultPaymentMethod(defaultPaymentMethodId: paymentMethod.stripeId)
            defaultPaymentMethod = paymentMethod
            return .success(())
        } catch {
            return .failure(NSError.stp_defaultPaymentMethodNotUpdatedError())
        }
    }

    func shouldCloseSheet(_: UpdatePaymentMethodViewController) {
        presentingViewController?.dismiss(animated: true)
    }

    private func getAccessoryButton(savedPaymentMethods: [STPPaymentMethod]) -> RowButton.RightAccessoryButton.AccessoryType? {
        return RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: savedPaymentMethods.count,
            isFirstCardCoBranded: savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: elementsSession.isCardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: elementsSession.paymentMethodRemoveLast(configuration: configuration),
            allowsPaymentMethodRemoval: elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
            allowsPaymentMethodUpdate: elementsSession.paymentMethodUpdateForPaymentSheet,
            omitChevron: configuration.appearance.embeddedPaymentElement.row.style.omitChevronInAccessoryButton
        )
    }
}

extension EmbeddedPaymentElement: VerticalSavedPaymentMethodsViewControllerDelegate {
    func didComplete(
        viewController: VerticalSavedPaymentMethodsViewController,
        with selectedPaymentMethod: STPPaymentMethod?,
        latestPaymentMethods: [STPPaymentMethod],
        didTapToDismiss: Bool,
        defaultPaymentMethod: STPPaymentMethod?
    ) {
        self.savedPaymentMethods = latestPaymentMethods
        // Update our default payment method to be the latest from the manage screen in case of update
        self.defaultPaymentMethod = defaultPaymentMethod
        let accessoryType = getAccessoryButton(
            savedPaymentMethods: latestPaymentMethods
        )

        // Select the *saved payment method if we selected a payment method
        // or
        // there are still saved payment methods & the saved payment method was previously selected to presenting
        let isSelected = (latestPaymentMethods.count > 1 && selectedPaymentMethod != nil) ||
        (embeddedPaymentMethodsView.selectedRowButton?.type.isSaved ?? false && latestPaymentMethods.count > 0)
        embeddedPaymentMethodsView.updateSavedPaymentMethodRow(savedPaymentMethods,
                                                               isSelected: isSelected,
                                                               accessoryType: accessoryType)
        presentingViewController?.dismiss(animated: true)
    }
}

// MARK: - EmbeddedPaymentElement.PaymentOptionDisplayData

extension EmbeddedPaymentElement.PaymentOptionDisplayData {
    init(paymentOption: PaymentOption, mandateText: NSAttributedString?, currency: String?, iconStyle: PaymentSheet.Appearance.IconStyle) {
        self.mandateText = mandateText
        self.image = paymentOption.makeIcon(currency: currency, iconStyle: iconStyle) // TODO: https://jira.corp.stripe.com/browse/MOBILESDK-2604 Refactor this!
        switch paymentOption {
        case .applePay:
            label = String.Localized.apple_pay
            paymentMethodType = "apple_pay"
            billingDetails = nil
            shippingDetails = nil
        case .saved(let paymentMethod, let confirmParams):
            label = paymentMethod.paymentOptionLabel(confirmParams: confirmParams)
            paymentMethodType = paymentMethod.type.identifier
            billingDetails = paymentMethod.billingDetails?.toPaymentSheetBillingDetails()
            shippingDetails = nil
        case .new(let confirmParams):
            label = confirmParams.paymentSheetLabel
            paymentMethodType = confirmParams.paymentMethodType.identifier
            billingDetails = confirmParams.paymentMethodParams.billingDetails?.toPaymentSheetBillingDetails()
            shippingDetails = nil
        case .link(let option):
            label = option.paymentSheetLabel
            paymentMethodType = STPPaymentMethodType.link.identifier
            billingDetails = option.billingDetails?.toPaymentSheetBillingDetails()
            shippingDetails = option.shippingAddress
        case .external(let paymentMethod, let stpBillingDetails):
            label = paymentMethod.displayText
            paymentMethodType = paymentMethod.type
            billingDetails = stpBillingDetails.toPaymentSheetBillingDetails()
            shippingDetails = nil
        }
    }
}

extension EmbeddedPaymentElement: EmbeddedFormViewControllerDelegate {
    func embeddedFormViewControllerShouldConfirm(
        _ embeddedFormViewController: EmbeddedFormViewController,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    ) {
        Task { @MainActor in
            let (result, deferredIntentConfirmationType) = await _confirm(paymentOption: paymentOption, authContext: embeddedFormViewController)
            completion(result, deferredIntentConfirmationType)
        }
    }

    func embeddedFormViewControllerDidCompleteConfirmation(_ embeddedFormViewController: EmbeddedFormViewController, result: PaymentSheetResult) {
        embeddedFormViewController.dismiss(animated: true) {
            if case let .confirm(completion) = self.configuration.formSheetAction {
                completion(result)
            }
        }
    }

    func embeddedFormViewControllerDidCancel(_ embeddedFormViewController: EmbeddedFormViewController) {
        let lastSelection = embeddedPaymentMethodsView.previousSelectedRowButton?.type
        let currentlySelectedType = embeddedPaymentMethodsView.selectedRowButton?.type

        // If the user re-selects a valid payment option w/ form, then modifies it, then hits close, we clear selection
        // Ideally we would revert back to the valid payment option that existed when the form was presented rather than totally clear selection
        // To restore to the previous payment option we need to restore the previous form VC that contained the previous payment option
        // TODO (https://jira.corp.stripe.com/browse/MOBILESDK-3361): Consider restoring the form VC and form cache to revert to the last valid payment option
        if lastSelection == currentlySelectedType,
           lastUpdatedPaymentOption != paymentOption {
            embeddedPaymentMethodsView.resetSelection()
        } else {
            // Go back to the previous selection if there was one
            embeddedPaymentMethodsView.resetSelectionToLastSelection()
        }

        // Show change button if the newly selected row needs it
        if let currentlySelectedType = embeddedPaymentMethodsView.selectedRowButton?.type{
            updateChangeButtonAndSublabelState(for: currentlySelectedType)
        }

        embeddedFormViewController.dismiss(animated: true) {
            if case let .confirm(completion) = self.configuration.formSheetAction {
                completion(.canceled)
            }
        }
    }

    func embeddedFormViewControllerDidContinue(_ embeddedFormViewController: EmbeddedFormViewController) {
        // Show change button if the selected row needs it
        if let newSelectedType = embeddedPaymentMethodsView.selectedRowButton?.type {
            updateChangeButtonAndSublabelState(for: newSelectedType)
        }
        embeddedFormViewController.dismiss(animated: true)
        informDelegateIfPaymentOptionUpdated()
        if case .immediateAction(let didSelectPaymentOption) = configuration.rowSelectionBehavior {
            didSelectPaymentOption()
        }
    }

    // Updates whether or not the change button shows and what sublabel (if any) the selected row button shows
    func updateChangeButtonAndSublabelState(for type: RowButtonType) {
        guard let _paymentOption,
              let displayData = paymentOption,
              case .new = type,
              selectedFormViewController != nil else {
            embeddedPaymentMethodsView.selectedRowChangeButtonState = (false, nil)
            return
        }

        // Don't show the change button for the disclosure style
        let shouldShowChangeButton = configuration.appearance.embeddedPaymentElement.row.style != .flatWithDisclosure
        if shouldShowChangeButton {
            embeddedPaymentMethodsView.selectedRowButton?.addChangeButton()
        }

        // Add a sublabel
        let sublabel: String? = {
            switch type.paymentMethodType {
            case .stripe(.card):
                guard case .new(confirmParams: let params) = _paymentOption else {
                    return nil
                }
                let brand = STPCardValidator.brand(for: params.paymentMethodParams.card)
                let brandString = brand == .unknown ? nil : STPCardBrandUtilities.stringFrom(brand)
                return [brandString, displayData.label].compactMap({ $0 }).joined(separator: " ")
            case .stripe(.USBankAccount):
                return displayData.label
            default:
                return nil
            }
        }()
        // Only overwrite the existing sublabel if we have a new one
        if let sublabel {
            embeddedPaymentMethodsView.selectedRowButton?.setSublabel(text: sublabel)
        }

        embeddedPaymentMethodsView.selectedRowChangeButtonState = (shouldShowChangeButton, sublabel)
    }
}

extension EmbeddedPaymentElement {

    func _confirm(paymentOption: PaymentOption, authContext: STPAuthenticationContext) async -> (
        result: PaymentSheetResult,
        deferredIntentConfirmationType: STPAnalyticsClient.DeferredIntentConfirmationType?
    ) {
        guard !hasConfirmedIntent else {
            return (.failed(error: PaymentSheetError.embeddedPaymentElementAlreadyConfirmedIntent), nil)
        }

        if let latestUpdateContext {
            switch latestUpdateContext.status {
            case .inProgress:
                // Fail confirmation immediately if an update is in progress, rather than waiting for it to complete.
                // This prevents scenarios where the user might confirm an outdated state, such as agreeing to pay X
                // but actually being charged Y due to an in-flight update changing the amount.
                let errorMessage = "confirm was called when an update task is in progress. This is not allowed, wait for updates to complete before calling confirm."
                let error = PaymentSheetError.integrationError(nonPIIDebugDescription: errorMessage)
                return (.failed(error: error), nil)
            case .succeeded:
                // The view is in sync with the intent. Continue on with confirm!
                break
            case .failed(error: let error):
                return (.failed(error: error), nil)
            case .canceled:
                let errorMessage = "confirm was called when the current update task is canceled. This shouldn't be possible; the current update task should only cancel if another task began."
                stpAssertionFailure(errorMessage)
                let error = PaymentSheetError.unknown(debugDescription: errorMessage)
                let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError, error: error)
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                return (.failed(error: error), nil)
            }
        }

        embeddedPaymentMethodsView.isUserInteractionEnabled = false

        let (result, deferredIntentConfirmationType) = await PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: authContext,
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            integrationShape: .embedded,
            confirmationChallenge: confirmationChallenge,
            analyticsHelper: analyticsHelper
        )
        analyticsHelper.logPayment(
            paymentOption: paymentOption,
            result: result,
            deferredIntentConfirmationType: deferredIntentConfirmationType
        )

        if case .completed = result {
            hasConfirmedIntent = true
        } else {
            // Re-enable interaction for failed and canceled results
            embeddedPaymentMethodsView.isUserInteractionEnabled = true
        }

        return (result, deferredIntentConfirmationType)
    }

    func bottomSheetController(with viewController: BottomSheetContentViewController) -> BottomSheetViewController {
        return BottomSheetViewController(contentViewController: viewController,
                                         appearance: configuration.appearance,
                                         isTestMode: configuration.apiClient.isTestmode,
                                         didCancelNative3DS2: {
            stpAssertionFailure("3DS2 was triggered unexpectedly")
        })
    }

    func clearPaymentOptionIfNeeded() {
        guard case .immediateAction = configuration.rowSelectionBehavior,
           case .confirm = configuration.formSheetAction else {
            return
        }

        clearPaymentOption()
    }

    static func validateRowSelectionConfiguration(configuration: Configuration) throws {
        switch configuration.rowSelectionBehavior {
        case .immediateAction:
            if case .confirm = configuration.formSheetAction, configuration.applePay != nil || configuration.customer != nil {
                // Fail init if the merchant is using immediateAction and confirm form sheet action along w/ either a Customer or Apple Pay configuration
                throw PaymentSheetError.integrationError(nonPIIDebugDescription: "Using .immediateAction with .confirm form sheet action is not supported when Apple Pay or a customer configuration is provided. Use .default row selection behavior or disable Apple Pay and saved payment methods.")
            }
        default:
            if case .flatWithDisclosure = configuration.appearance.embeddedPaymentElement.row.style {
                // Fail init if the merchant is using the flatWithDisclosure style without the immediateAction behavior since flatWithDisclosure does not provide a selected state
                throw PaymentSheetError.integrationError(nonPIIDebugDescription: "Using .flatWithDisclosure row style without .immediateAction row selection behavior is not supported. Use a different style or enable .immediateAction.")
            }
        }
    }

    /// - Returns: Whether or not we should show the given `form` for the given `configuration`.
    nonisolated static func shouldShowForm(_ form: PaymentMethodElement, configuration: EmbeddedPaymentElement.Configuration) -> Bool {
        // If the form collects user input, we definitely show it.
        if form.collectsUserInput {
            return true
        }

        // By default, we don't show or use form VCs if they don't collect user input
        // However: When `rowSelectionBehavior` is `immediateAction` and `embeddedViewDisplaysMandateText` is `true` and the customer selects a PM that has no form but has a mandate, there's a problem.
        // We'd normally show the mandate in the embedded view, but `immediateAction` implies the merchant will immediately confirm or move the customer to a different screen before they can see or consent to the mandate.
        // We therefore show a form with the mandate text and proceed as normal as if it were any other PM with a form (customer can continue or confirm in the sheet).
        let paymentMethodHasNoFormAndHasAMandate = form.collectsUserInput == false && form.getMandateText() != nil
        if
            case .immediateAction = configuration.rowSelectionBehavior,
            configuration.embeddedViewDisplaysMandateText,
            paymentMethodHasNoFormAndHasAMandate
        {
            return true
        } else {
            return false
        }
    }

}

final class PaymentSheetAuthenticationContextViewController: UIViewController {
    let _presentingViewController: UIViewController
    let appearance: PaymentSheet.Appearance

    private var pollingVC: PollingViewController?
    private var shouldPresentPollingVC = false

    init(presentingViewController: UIViewController, appearance: PaymentSheet.Appearance) {
        self._presentingViewController = presentingViewController
        self.appearance = appearance
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension PaymentSheetAuthenticationContextViewController: PaymentSheetAuthenticationContext {

    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self._presentingViewController.present(authenticationViewController, animated: true) {
                completion()
            }
        }
    }

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        DispatchQueue.main.async {
            authenticationViewController.dismiss(animated: true) {
                completion?()
            }
        }
    }

    func presentPollingVCForAction(action: StripePayments.STPPaymentHandlerPaymentIntentActionParams, type: StripePayments.STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        // Initialize the polling view controller and flag it for presentation
        self.pollingVC = PollingViewController(currentAction: action, viewModel: PollingViewModel(paymentMethodType: type),
                                                      appearance: self.appearance, safariViewController: safariViewController)
        shouldPresentPollingVC = true
    }

    func authenticationContextDidDismiss(_ viewController: UIViewController) {
        // The following code should only be executed if we have dismissed a SFSafariViewController
        guard viewController is SFSafariViewController else { return }

        if let pollingViewController = self.pollingVC, shouldPresentPollingVC {
            self._presentingViewController.present(pollingViewController, animated: true)
            self.shouldPresentPollingVC = false
        }
    }

    public func authenticationPresentingViewController() -> UIViewController {
        return _presentingViewController
    }
}

extension EmbeddedPaymentElement.Configuration.RowSelectionBehavior: Equatable {
   @_spi(STP) public static func == (lhs: EmbeddedPaymentElement.Configuration.RowSelectionBehavior, rhs: EmbeddedPaymentElement.Configuration.RowSelectionBehavior) -> Bool {
        switch (lhs, rhs) {
        case (.default, .default):
            return true
        case (.immediateAction, .immediateAction):
            return true
        default:
            return false
        }
    }
}

extension PaymentSheetResult {
    var isCanceledOrFailed: Bool {
        switch self {
        case .canceled, .failed:
            return true
        case .completed:
            return false
        }
    }
}

extension PaymentSheet.Appearance.EmbeddedPaymentElement.Row.Style {
    var omitChevronInAccessoryButton: Bool {
        switch self {
        case .flatWithCheckmark, .flatWithDisclosure:
            return true
        case .flatWithRadio, .floatingButton:
            return false
        }
    }
}
