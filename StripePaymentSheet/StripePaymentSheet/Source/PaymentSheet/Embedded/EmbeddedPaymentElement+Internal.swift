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
        previousSelection: RowButtonType? = nil,
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
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            allowsPaymentMethodRemoval: loadResult.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
            isFlatCheckmarkStyle: configuration.appearance.embeddedPaymentElement.row.style == .flatWithCheckmark
        )
        let initialSelection: RowButtonType? = {
            // First, respect the previous selection
            if let previousSelection {
                return previousSelection
            }

            // If there's no previous customer input, default to the customer's default or the first saved payment method, if any
            var customerDefault: CustomerPaymentOption?
            // if opted in to the "set as default" feature, try to get default payment method from elements session
            if configuration.allowsSetAsDefaultPM {
                if let defaultPaymentMethod = loadResult.elementsSession.customer?.getDefaultOrFirstPaymentMethod() {
                    customerDefault = CustomerPaymentOption.stripeId(defaultPaymentMethod.stripeId)
                }
            } else {
                customerDefault = CustomerPaymentOption.defaultPaymentMethod(for: configuration.customer?.id)
            }
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
            savedPaymentMethods: loadResult.savedPaymentMethods,
            customer: configuration.customer,
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
        guard formViewController.collectsUserInput else {
            return nil
        }
        return formViewController
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
            previousPaymentOption:  selectedFormViewController?.previousPaymentOption,
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession,
            savedPaymentMethods: savedPaymentMethods,
            analyticsHelper: analyticsHelper,
            formCache: formCache,
            delegate: self
        )

        // 2. Inform the delegate of the updated payment option
        informDelegateIfPaymentOptionUpdated()
    }

    func embeddedPaymentMethodsViewDidTapPaymentMethodRow() {
        guard let selectedFormViewController else {
            // If the current selection has no form VC, there's nothing to do
            return
        }
        // Present the current selection's form VC
        delegate?.embeddedPaymentElementWillPresent(embeddedPaymentElement: self)
        let bottomSheet = bottomSheetController(with: selectedFormViewController)
        stpAssert(presentingViewController != nil, "Presenting view controller not found, set EmbeddedPaymentElement.presentingViewController.")
        stpAssert(selectedFormViewController.delegate != nil)
        presentingViewController?.presentAsBottomSheet(bottomSheet, appearance: configuration.appearance)

    }

    func embeddedPaymentMethodsViewDidTapViewMoreSavedPaymentMethods(selectedSavedPaymentMethod: STPPaymentMethod?) {
        // Special case, only 1 card remaining, skip showing the list and show update view controller
        if savedPaymentMethods.count == 1,
           let paymentMethod = savedPaymentMethods.first {
            let updateViewModel = UpdatePaymentMethodViewModel(paymentMethod: paymentMethod,
                                                               appearance: configuration.appearance,
                                                               hostedSurface: .paymentSheet,
                                                               cardBrandFilter: configuration.cardBrandFilter,
                                                               canRemove: configuration.allowsRemovalOfLastSavedPaymentMethod && elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
                                                               isCBCEligible: paymentMethod.isCoBrandedCard && elementsSession.isCardBrandChoiceEligible,
                                                               allowsSetAsDefaultPM: configuration.allowsSetAsDefaultPM,
                                                               isDefault: paymentMethod == elementsSession.customer?.getDefaultPaymentMethod()
            )
            let updateViewController = UpdatePaymentMethodViewController(
                                                                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                                                                isTestMode: configuration.apiClient.isTestmode,
                                                                viewModel: updateViewModel)
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
            analyticsHelper: analyticsHelper
        )
        verticalSavedPaymentMethodsViewController.delegate = self
        let bottomSheetVC = bottomSheetController(with: verticalSavedPaymentMethodsViewController)
        presentingViewController?.presentAsBottomSheet(bottomSheetVC, appearance: configuration.appearance)
    }
}

// MARK: UpdatePaymentMethodViewControllerDelegate
extension EmbeddedPaymentElement: UpdatePaymentMethodViewControllerDelegate {
    func didRemove(viewController: UpdatePaymentMethodViewController, paymentMethod: StripePayments.STPPaymentMethod) {
        // Detach the payment method from the customer
        savedPaymentMethodManager.detach(paymentMethod: paymentMethod)
        analyticsHelper.logSavedPaymentMethodRemoved(paymentMethod: paymentMethod)

        // Update savedPaymentMethods
        self.savedPaymentMethods.removeAll(where: { $0.stripeId == paymentMethod.stripeId })

        let accessoryType = getAccessoryButton(savedPaymentMethods: savedPaymentMethods)
        embeddedPaymentMethodsView.updateSavedPaymentMethodRow(savedPaymentMethods,
                                                               isSelected: false,
                                                               accessoryType: accessoryType)
        presentingViewController?.dismiss(animated: true)
    }

    func didUpdate(viewController: UpdatePaymentMethodViewController,
                   paymentMethod: StripePayments.STPPaymentMethod,
                   updateParams: StripePayments.STPPaymentMethodUpdateParams) async throws {
        let updatedPaymentMethod = try await savedPaymentMethodManager.update(paymentMethod: paymentMethod, with: updateParams)

        // Update savedPaymentMethods
        if let row = self.savedPaymentMethods.firstIndex(where: { $0.stripeId == updatedPaymentMethod.stripeId }) {
            self.savedPaymentMethods[row] = updatedPaymentMethod
        }

        let accessoryType = getAccessoryButton(savedPaymentMethods: savedPaymentMethods)
        let isSelected = embeddedPaymentMethodsView.selectedRowButton?.type.isSaved ?? false
        embeddedPaymentMethodsView.updateSavedPaymentMethodRow(savedPaymentMethods,
                                                               isSelected: isSelected,
                                                               accessoryType: accessoryType)
        presentingViewController?.dismiss(animated: true)
    }

    func shouldCloseSheet(_: UpdatePaymentMethodViewController) {
        presentingViewController?.dismiss(animated: true)
    }

    private func getAccessoryButton(savedPaymentMethods: [STPPaymentMethod]) -> RowButton.RightAccessoryButton.AccessoryType? {
        return RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: savedPaymentMethods.count,
            isFirstCardCoBranded: savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: elementsSession.isCardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            allowsPaymentMethodRemoval: elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
            isFlatCheckmarkStyle: configuration.appearance.embeddedPaymentElement.row.style == .flatWithCheckmark
        )
    }
}

extension EmbeddedPaymentElement: VerticalSavedPaymentMethodsViewControllerDelegate {
    func didComplete(
        viewController: VerticalSavedPaymentMethodsViewController,
        with selectedPaymentMethod: STPPaymentMethod?,
        latestPaymentMethods: [STPPaymentMethod],
        didTapToDismiss: Bool
    ) {
        self.savedPaymentMethods = latestPaymentMethods
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
    init(paymentOption: PaymentOption, mandateText: NSAttributedString?) {
        self.mandateText = mandateText
        self.image = paymentOption.makeIcon(updateImageHandler: nil) // ☠️ This can make a blocking network request TODO: https://jira.corp.stripe.com/browse/MOBILESDK-2604 Refactor this!
        switch paymentOption {
        case .applePay:
            label = String.Localized.apple_pay
            paymentMethodType = "apple_pay"
            billingDetails = nil
        case .saved(let paymentMethod, let confirmParams):
            label = paymentMethod.paymentOptionLabel(confirmParams: confirmParams)
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
        // If the formViewController was populated with a previous payment option don't reset
        if embeddedFormViewController.previousPaymentOption == nil {
            embeddedPaymentMethodsView.resetSelectionToLastSelection()
            // Show change button if the newly selected row needs it
            if let newSelectedType = embeddedPaymentMethodsView.selectedRowButton?.type {
                let changeButtonState = getChangeButtonState(for: newSelectedType)
                if changeButtonState.shouldShowChangeButton {
                    embeddedPaymentMethodsView.selectedRowButton?.addChangeButton(sublabel: changeButtonState.sublabel)
                }
            }
        }
        embeddedFormViewController.dismiss(animated: true)
    }

    func embeddedFormViewControllerDidContinue(_ embeddedFormViewController: EmbeddedFormViewController) {
        // Show change button if the selected row needs it
        if let newSelectedType = embeddedPaymentMethodsView.selectedRowButton?.type {
            let changeButtonState = getChangeButtonState(for: newSelectedType)
            if changeButtonState.shouldShowChangeButton {
                embeddedPaymentMethodsView.selectedRowButton?.addChangeButton(sublabel: changeButtonState.sublabel)
            }
        }
        embeddedFormViewController.dismiss(animated: true)
        informDelegateIfPaymentOptionUpdated()
    }
    
    func getChangeButtonState(for type: RowButtonType) -> (shouldShowChangeButton: Bool, sublabel: String?) {
        guard let _paymentOption, let displayData = paymentOption else {
            return (false, nil)
        }
        // Show change button for new PMs that have a valid form
        let shouldShowChangeButton: Bool = {
            if case .new = type, selectedFormViewController != nil {
               return true
            }
            return false
        }()
        
        // Add a sublabel to the selected row for cards and us bank account like "Visa 4242"
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
        
        return (shouldShowChangeButton: shouldShowChangeButton, sublabel: sublabel)
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
        // Wait for the last update to finish and fail if didn't succeed. A failure means the view is out of sync with the intent and could e.g. not be showing a required mandate.
        if let latestUpdateTask {
            switch await latestUpdateTask.value {
            case .succeeded:
                // The view is in sync with the intent. Continue on with confirm!
                break
            case .failed(error: let error):
                return (.failed(error: error), nil)
            case .canceled:
                let errorMessage = "confirm was called when the current update task is canceled. This shouldn't be possible; the current update task should only cancel if another task began."
                stpAssertionFailure(errorMessage)
                let error = PaymentSheetError.flowControllerConfirmFailed(message: errorMessage)
                let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError, error: error)
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                return (.failed(error: error), nil)
            }
        }

        let (result, deferredIntentConfirmationType) = await PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: authContext,
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            integrationShape: .embedded,
            analyticsHelper: analyticsHelper
        )
        analyticsHelper.logPayment(
            paymentOption: paymentOption,
            result: result,
            deferredIntentConfirmationType: deferredIntentConfirmationType
        )

        // If the confirmation was successful, disable user interaction
        if case .completed = result {
            hasConfirmedIntent = true
            containerView.isUserInteractionEnabled = false
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
}

// TODO(porter) When we use Xcode 16 on CI do this instead of `STPAuthenticationContextWrapper`
// @retroactive is not supported in Xcode 15
// extension UIViewController: @retroactive STPAuthenticationContext {
//    public func authenticationPresentingViewController() -> UIViewController {
//        return self
//    }
// }

final class STPAuthenticationContextWrapper: UIViewController {
    let _presentingViewController: UIViewController

    init(presentingViewController: UIViewController) {
        self._presentingViewController = presentingViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension STPAuthenticationContextWrapper: STPAuthenticationContext {
    public func authenticationPresentingViewController() -> UIViewController {
        return _presentingViewController
    }
}
