//
//  PaymentSheetVerticalViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/3/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class PaymentSheetVerticalViewController: UIViewController, FlowControllerViewControllerProtocol, PaymentSheetViewControllerProtocol {
    enum Error: Swift.Error {
        case missingPaymentMethodFormViewController
        case noPaymentOptionOnBuyButtonTap
    }
    var selectedPaymentOption: PaymentSheet.PaymentOption? {
        if isLinkWalletButtonSelected {
            return .link(option: .wallet)
        } else if let paymentMethodListViewController, children.contains(paymentMethodListViewController) {
            // If we're showing the list, use its selection:
            switch paymentMethodListViewController.currentSelection {
            case nil:
                return nil
            case .applePay:
                return .applePay
            case .link:
                return .link(option: .wallet)
            case .new(paymentMethodType: let paymentMethodType):
                return .new(confirmParams: IntentConfirmParams(type: paymentMethodType))
            case .saved(paymentMethod: let paymentMethod):
                // TODO: Handle confirmParams - look at SavedPaymentOptionsViewController.selectedPaymentOptionIntentConfirmParams & CVC
                return .saved(paymentMethod: paymentMethod, confirmParams: nil)
            }
        } else {
            // Otherwise, we must be showing the form - use its payment option
            guard let paymentMethodFormViewController else {
                stpAssertionFailure("Expected paymentMethodFormViewController")
                let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError, error: Error.missingPaymentMethodFormViewController)
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                return nil
            }
            return paymentMethodFormViewController.paymentOption
        }
    }
    // Edge-case, only set to true when Link is selected via wallet in flow controller
    var isLinkWalletButtonSelected: Bool = false
    /// The type of the Stripe payment method that's currently selected in the UI for new and saved PMs. Returns nil Apple Pay and .stripe(.link) for Link.
    /// Note that, unlike selectedPaymentOption, this is non-nil even if the PM form is invalid.
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType? {
        if isLinkWalletButtonSelected {
            // If the Link wallet button was tapped, that is our selection until the sheet re-appears
            return nil
        } else if let paymentMethodListViewController, children.contains(paymentMethodListViewController) {
            return selectedPaymentOption?.paymentMethodType
        } else {
            // Otherwise, we must be showing the form - use its payment option
            return paymentMethodFormViewController?.paymentMethodType
        }
    }
    let loadResult: PaymentSheetLoader.LoadResult
    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    let configuration: PaymentSheet.Configuration
    var intent: Intent {
        return loadResult.intent
    }
    var error: Swift.Error?
    var isPaymentInFlight: Bool = false
    private var savedPaymentMethods: [STPPaymentMethod]
    let isFlowController: Bool
    private var previousPaymentOption: PaymentOption?
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate?
    weak var paymentSheetDelegate: PaymentSheetViewControllerDelegate?

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()

    var paymentMethodListViewController: VerticalPaymentMethodListViewController?
    var paymentMethodFormViewController: PaymentMethodFormViewController?

    lazy var paymentContainerView: DynamicHeightContainerView = {
        DynamicHeightContainerView()
    }()

    lazy var walletHeaderView: PaymentSheetViewController.WalletHeaderView? = {
        var walletOptions: PaymentSheetViewController.WalletHeaderView.WalletOptions = []

        // Offer Apple Pay in wallet if enabled and not in flow controller
        if loadResult.isApplePayEnabled, !isFlowController {
            walletOptions.insert(.applePay)
        }

        // Offer Link in wallet if we are not in flow controller or if we are in flow controller and Apple Pay is disabled
        if (!isFlowController && loadResult.isLinkEnabled) || (isFlowController && !loadResult.isApplePayEnabled && loadResult.isLinkEnabled) {
            walletOptions.insert(.link)
        }

        // If no wallet options available return nil
        guard !walletOptions.isEmpty else { return nil }

        let header = PaymentSheetViewController.WalletHeaderView(
            options: walletOptions,
            appearance: configuration.appearance,
            applePayButtonType: configuration.applePay?.buttonType ?? .plain,
            isPaymentIntent: intent.isPaymentIntent,
            delegate: self
        )
        return header
    }()

    lazy var headerLabel: UILabel = {
        let label = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        label.text = .Localized.select_payment_method
        label.isHidden = walletHeaderView != nil // Only show this header label if the wallet header view is empty
        return label
    }()

    var savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType? {
        RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: savedPaymentMethods.count,
            isFirstCardCoBranded: savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: loadResult.intent.cardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            allowsPaymentMethodRemoval: loadResult.intent.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        )
    }

    lazy var primaryButton: ConfirmButton = {
        ConfirmButton(
            callToAction: .setup, // Dummy value; real value is set after init
            applePayButtonType: configuration.applePay?.buttonType ?? .plain,
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapPrimaryButton()
            }
        )
    }()

    private lazy var mandateView: VerticalMandateView = {
        return VerticalMandateView(formProvider: { [weak self] paymentMethodType in
            return self?.makeFormVC(paymentMethodType: paymentMethodType).form
        })
    }()

    // MARK: - Initializers

    init(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool, previousPaymentOption: PaymentOption? = nil) {
        self.loadResult = loadResult
        self.configuration = configuration
        self.previousPaymentOption = previousPaymentOption
        self.isFlowController = isFlowController
        self.savedPaymentMethods = loadResult.savedPaymentMethods
        self.paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: loadResult.intent,
            configuration: configuration,
            logAvailability: false
        )
        super.init(nibName: nil, bundle: nil)

        regenerateUI()
        // Only use the previous customer input for the first form shown
        self.previousPaymentOption = nil
        updatePrimaryButton()
        updateMandate(animated: false)
    }

    /// Regenerates the main content - either the PM list or the PM form
    func regenerateUI(updatedListSelection: VerticalPaymentMethodListSelection? = nil) {
        // Remove any content vcs; we'll rebuild and add them now
        if let paymentMethodListViewController {
            remove(childViewController: paymentMethodListViewController)
        }
        if let paymentMethodFormViewController {
            remove(childViewController: paymentMethodFormViewController)
        }
        // Determine whether to show the form only or the payment method list
        let firstPaymentMethodType = paymentMethodTypes[0]
        // Create the PM List VC so that we can see how many rows it displays
        let paymentMethodListViewController = makePaymentMethodListViewController(selection: updatedListSelection)
        if paymentMethodListViewController.rowCount == 1 && firstPaymentMethodType == .stripe(.card) {
            // If we'd only show one PM in the vertical list and it's `card`, display the form instead of the payment method list.
            let formVC = makeFormVC(paymentMethodType: firstPaymentMethodType, shouldShowHeader: walletHeaderView == nil)
            self.paymentMethodFormViewController = formVC
            add(childViewController: formVC, containerView: paymentContainerView)
            headerLabel.isHidden = true
        } else {
            // Otherwise, we're using the list
            self.paymentMethodListViewController = paymentMethodListViewController
            if case let .new(confirmParams: confirmParams) = previousPaymentOption,
               paymentMethodTypes.contains(confirmParams.paymentMethodType),
               shouldDisplayForm(for: confirmParams.paymentMethodType)
            {
                // If the previous customer input was for a PM form and it collects user input, display the form on top of the list
                let formVC = makeFormVC(paymentMethodType: confirmParams.paymentMethodType)
                self.paymentMethodFormViewController = formVC
                add(childViewController: formVC, containerView: paymentContainerView)
                navigationBar.setStyle(.back(showAdditionalButton: false))
                headerLabel.isHidden = true
            } else {
                // Otherwise, show the list of PMs
                add(childViewController: paymentMethodListViewController, containerView: paymentContainerView)
            }
        }
    }

    func updatePrimaryButton() {
        let callToAction: ConfirmButton.CallToActionType = {
            if let override = paymentMethodFormViewController?.overridePrimaryButtonState {
                return override.ctaType
            }
            if let customCtaLabel = configuration.primaryButtonLabel {
                return isFlowController ? .custom(title: customCtaLabel) : .customWithLock(title: customCtaLabel)
            }

            if isFlowController {
                return .add(paymentMethodType: selectedPaymentMethodType ?? .stripe(.unknown))
            }
            return .makeDefaultTypeForPaymentSheet(intent: intent)
        }()
        let state: ConfirmButton.Status = {
            if isPaymentInFlight {
                return .processing
            }
            if let override = paymentMethodFormViewController?.overridePrimaryButtonState {
                return override.enabled ? .enabled : .disabled
            }
            return selectedPaymentOption == nil ? .disabled : .enabled
        }()
        let style: ConfirmButton.Style = {
            // If the button invokes Apple Pay, it must be styled as the Apple Pay button
            if case .applePay = selectedPaymentOption, !isFlowController {
                return .applePay
            }
            return .stripe
        }()
        primaryButton.update(
            state: state,
            style: style,
            callToAction: callToAction,
            animated: true
        )
    }

    func updateMandate(animated: Bool = true) {
        self.mandateView.paymentMethodType = self.selectedPaymentMethodType
        self.mandateView.layoutIfNeeded()
        if animated {
            animateHeightChange {
                self.mandateView.isHidden = !self.mandateView.isDisplayingMandate
            }
        } else {
            self.mandateView.isHidden = !self.mandateView.isDisplayingMandate
        }
    }

    func makePaymentMethodListViewController(selection: VerticalPaymentMethodListSelection?) -> VerticalPaymentMethodListViewController {
        // Determine the initial selection - either the previous payment option or the last VC's selection
        let initialSelection: VerticalPaymentMethodListSelection? = {
            if let selection {
                return selection
            }

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
                if shouldDisplayForm(for: confirmParams.paymentMethodType) {
                    return nil
                } else {
                    return .new(paymentMethodType: confirmParams.paymentMethodType)
                }
            case nil:
                // If there's no previous customer input...
                if let paymentMethodListViewController, let lastSelection =  paymentMethodListViewController.currentSelection {
                    // ...use the previous paymentMethodListViewController's selection
                    if case let .saved(paymentMethod: paymentMethod) = lastSelection {
                        // If the previous selection was a saved PM, only use it if it still exists:
                        if savedPaymentMethods.map({ $0.stripeId }).contains(paymentMethod.stripeId) {
                            return lastSelection
                        }
                    } else {
                        return lastSelection
                    }
                }
                // Default to the first saved payment method, if any
                return savedPaymentMethods.first.map { .saved(paymentMethod: $0) }
            }
        }()
        return VerticalPaymentMethodListViewController(
            initialSelection: initialSelection,
            savedPaymentMethod: savedPaymentMethods.first,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: loadResult.isApplePayEnabled && isFlowController,
            shouldShowLink: loadResult.isLinkEnabled && walletHeaderView == nil,
            savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
            appearance: configuration.appearance,
            delegate: self
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)
        paymentContainerView.directionalLayoutMargins = .zero

        // One stack view contains all our subviews
        let spacerView = UIView.makeSpacerView(height: 0)
        let views: [UIView] = [headerLabel, walletHeaderView, paymentContainerView, mandateView, spacerView, primaryButton].compactMap { $0 }
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.setCustomSpacing(24, after: headerLabel)
        if let walletHeaderView {
            stackView.setCustomSpacing(24, after: walletHeaderView)
        }
        stackView.setCustomSpacing(12, after: paymentContainerView)
        stackView.setCustomSpacing(20, after: spacerView)
        stackView.sendSubviewToBack(mandateView)

        view.addAndPinSubview(stackView, insets: .init(top: 0, leading: 0, bottom: PaymentSheetUI.defaultSheetMargins.bottom, trailing: 0))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isLinkWalletButtonSelected = false
    }

    // MARK: - PaymentSheetViewControllerProtocol

    func clearTextFields() {
        paymentMethodFormViewController?.clearTextFields()
    }

    // MARK: - Helpers

    var isUserInteractionEnabled: Bool = true {
        didSet {
            if isUserInteractionEnabled != view.isUserInteractionEnabled {
                sendEventToSubviews(
                    isUserInteractionEnabled ? .shouldEnableUserInteraction : .shouldDisableUserInteraction,
                    from: view
                )
            }
            view.isUserInteractionEnabled = isUserInteractionEnabled
            navigationBar.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }

    func pay(with paymentOption: PaymentOption) {
        view.endEditing(true)
        isPaymentInFlight = true
        error = nil
        updatePrimaryButton()
        isUserInteractionEnabled = false

        // Confirm the payment with the payment option
        let startTime = NSDate.timeIntervalSinceReferenceDate
        paymentSheetDelegate?.paymentSheetViewControllerShouldConfirm(self, with: paymentOption) { result, deferredIntentConfirmationType in
            let elapsedTime = NSDate.timeIntervalSinceReferenceDate - startTime
            DispatchQueue.main.asyncAfter(
                deadline: .now() + max(PaymentSheetUI.minimumFlightTime - elapsedTime, 0)
            ) { [self] in
                STPAnalyticsClient.sharedClient.logPaymentSheetPayment(
                    isCustom: false,
                    paymentMethod: paymentOption.analyticsValue,
                    result: result,
                    linkEnabled: loadResult.isLinkEnabled,
                    activeLinkSession: LinkAccountContext.shared.account?.sessionState == .verified,
                    linkSessionType: self.intent.linkPopupWebviewOption,
                    currency: self.intent.currency,
                    intentConfig: self.intent.intentConfig,
                    deferredIntentConfirmationType: deferredIntentConfirmationType,
                    paymentMethodTypeAnalyticsValue: paymentOption.paymentMethodTypeAnalyticsValue,
                    error: result.error,
                    linkContext: paymentOption.linkContext,
                    apiClient: self.configuration.apiClient
                )

                self.isPaymentInFlight = false
                switch result {
                case .canceled:
                    // Keep customer on payment sheet
                    self.updatePrimaryButton()
                    self.isUserInteractionEnabled = true
                case .failed(let error):
                    #if !canImport(CompositorServices)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                    // Update state
                    self.updatePrimaryButton()
                    self.isUserInteractionEnabled = true
                    // TODO: Handle error.
                    print(error)
                case .completed:
                    // We're done!
                    let delay: TimeInterval =
                    self.presentedViewController?.isBeingDismissed == true ? 1 : 0
                    // Hack: PaymentHandler calls the completion block while SafariVC is still being dismissed - "wait" until it's finished before updating UI
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
#if !canImport(CompositorServices)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
                        self.primaryButton.update(state: .succeeded, animated: true) {
                            // Wait a bit before closing the sheet
                            self.paymentSheetDelegate?.paymentSheetViewControllerDidFinish(self, result: .completed)
                        }
                    }
                }
            }
        }
    }

    @objc func didTapPrimaryButton() {
        // If the form has overridden the primary buy button, hand control over to the form
        guard paymentMethodFormViewController?.overridePrimaryButtonState == nil else {
            paymentMethodFormViewController?.didTapCallToActionButton(from: self)
            return
        }

        // Send analytic when primary button is tapped
        let paymentMethodType = selectedPaymentMethodType ?? .stripe(.unknown)
        STPAnalyticsClient.sharedClient.logPaymentSheetConfirmButtonTapped(paymentMethodTypeIdentifier: paymentMethodType.identifier, linkContext: selectedPaymentOption?.linkContext)

        // If FlowController, simply close the sheet
        if isFlowController {
            self.flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: false)
            return
        }

        // Otherwise, grab the payment option
        guard let selectedPaymentOption else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetViewControllerError, error: Error.noPaymentOptionOnBuyButtonTap)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Tapped buy button while adding without paymentOption")
            return
        }
        pay(with: selectedPaymentOption)
    }

    @objc func presentManageScreen() {
        // Special case, only 1 card remaining but is co-branded, show update view controller
        if savedPaymentMethods.count == 1,
           let paymentMethod = savedPaymentMethods.first,
           paymentMethod.isCoBrandedCard,
           loadResult.intent.cardBrandChoiceEligible {
            let updateViewController = UpdateCardViewController(paymentMethod: paymentMethod,
                                                                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                                                                appearance: configuration.appearance,
                                                                hostedSurface: .paymentSheet,
                                                                canRemoveCard: configuration.allowsRemovalOfLastSavedPaymentMethod && loadResult.intent.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
                                                                isTestMode: configuration.apiClient.isTestmode)
            updateViewController.delegate = self
            bottomSheetController?.pushContentViewController(updateViewController)
            return
        }

        let vc = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
            paymentMethods: savedPaymentMethods,
            paymentMethodRemove: loadResult.intent.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
            isCBCEligible: loadResult.intent.cardBrandChoiceEligible
        )
        vc.delegate = self
        bottomSheetController?.pushContentViewController(vc)
    }
}

// MARK: - BottomSheetContentViewController
extension PaymentSheetVerticalViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isPaymentInFlight
    }

    func didTapOrSwipeToDismiss() {
        guard !isPaymentInFlight else {
           return
        }
        if isFlowController {
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: true)
        } else {
            paymentSheetDelegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    var requiresFullScreen: Bool {
        // TODO
        return false
    }

    func didFinishAnimatingHeight() {
        // no-op
    }
}

// MARK: - VerticalSavedPaymentMethodsViewControllerDelegate

extension PaymentSheetVerticalViewController: VerticalSavedPaymentMethodsViewControllerDelegate {
    func didComplete(viewController: VerticalSavedPaymentMethodsViewController,
                     with selectedPaymentMethod: STPPaymentMethod?,
                     latestPaymentMethods: [STPPaymentMethod]) {
        // Update our list of saved payment methods to be the latest from the manage screen in case of updates/removals
        self.savedPaymentMethods = latestPaymentMethods
        var selection: VerticalPaymentMethodListSelection?
        if let selectedPaymentMethod {
            selection = .saved(paymentMethod: selectedPaymentMethod)
        }
        regenerateUI(updatedListSelection: selection)

        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

// MARK: - VerticalPaymentMethodListViewDelegate

extension PaymentSheetVerticalViewController: VerticalPaymentMethodListViewDelegate {

    func shouldSelectPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool {
        switch selection {
        case .applePay, .link:
            return true
        case let .new(paymentMethodType: paymentMethodType):
            // Only make payment methods appear selected in the list if they don't push to a form
            return !makeFormVC(paymentMethodType: paymentMethodType).form.collectsUserInput
        case .saved:
            return true
        }
    }

    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) {
#if !canImport(CompositorServices)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
        switch selection {
        case .applePay, .link, .saved:
            break
        case let .new(paymentMethodType: paymentMethodType):
            let pmFormVC = makeFormVC(paymentMethodType: paymentMethodType)
            if pmFormVC.form.collectsUserInput {
                // The payment method form collects user input, display it
                self.paymentMethodFormViewController = pmFormVC
                switchContentIfNecessary(to: pmFormVC, containerView: paymentContainerView)
                navigationBar.setStyle(.back(showAdditionalButton: false))
                walletHeaderView?.isHidden = true
                headerLabel.isHidden = true
            }
        }
        updatePrimaryButton()
        updateMandate()
    }

    func didTapSavedPaymentMethodAccessoryButton() {
        presentManageScreen()
    }

    private func makeFormVC(paymentMethodType: PaymentSheet.PaymentMethodType, shouldShowHeader: Bool = true) -> PaymentMethodFormViewController {
        let previousCustomerInput: IntentConfirmParams? = {
            if case let .new(confirmParams: confirmParams) = previousPaymentOption {
                return confirmParams
            } else {
                return nil
            }
        }()

        return PaymentMethodFormViewController(
            type: paymentMethodType,
            intent: intent,
            previousCustomerInput: previousCustomerInput,
            configuration: configuration,
            isLinkEnabled: loadResult.isLinkEnabled,
            shouldShowHeader: shouldShowHeader,
            hasASavedCard: !savedPaymentMethods.filter({ $0.type == .card }).isEmpty,
            delegate: self
        )
    }

    private func shouldDisplayForm(for paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        return makeFormVC(paymentMethodType: paymentMethodType).form.collectsUserInput
    }
}

extension PaymentSheetVerticalViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        // TODO:
        if isFlowController {
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: true)
        } else {
            paymentSheetDelegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // Hide the keyboard if it appeared and switch back to the vertical list
        view.endEditing(true)
        paymentMethodFormViewController = nil
        switchContentIfNecessary(to: paymentMethodListViewController!, containerView: paymentContainerView)
        navigationBar.setStyle(.close(showAdditionalButton: false))
        headerLabel.isHidden = walletHeaderView != nil
        walletHeaderView?.isHidden = walletHeaderView == nil
        updatePrimaryButton()
        updateMandate()
    }
}

// MARK: UpdateCardViewControllerDelegate
extension PaymentSheetVerticalViewController: UpdateCardViewControllerDelegate {
    func didRemove(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod) {
        guard let ephemeralKeySecret = configuration.customer?.ephemeralKeySecret else { return }

        // Detach the payment method from the customer
        let manager = SavedPaymentMethodManager(configuration: configuration)
        manager.detach(paymentMethod: paymentMethod, using: ephemeralKeySecret)

        // Update savedPaymentMethods
        self.savedPaymentMethods.removeAll(where: { $0.stripeId == paymentMethod.stripeId })

        // Update UI
        regenerateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }

    func didUpdate(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod, updateParams: STPPaymentMethodUpdateParams) async throws {
        guard let ephemeralKeySecret = configuration.customer?.ephemeralKeySecret else { return }

        // Update the payment method
        let manager = SavedPaymentMethodManager(configuration: configuration)
        let updatedPaymentMethod = try await manager.update(paymentMethod: paymentMethod, with: updateParams, using: ephemeralKeySecret)

        // Update savedPaymentMethods
        if let row = self.savedPaymentMethods.firstIndex(where: { $0.stripeId == updatedPaymentMethod.stripeId }) {
            self.savedPaymentMethods[row] = updatedPaymentMethod
        }

        // Update UI
        regenerateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }
}

extension PaymentSheetVerticalViewController: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: PaymentMethodFormViewController) {
        updatePrimaryButton()
    }

    func updateErrorLabel(for error: Swift.Error?) {
        // TODO
    }
}

extension PaymentSheetVerticalViewController: WalletHeaderViewDelegate {
    func walletHeaderViewApplePayButtonTapped(_ header: PaymentSheetViewController.WalletHeaderView) {
        pay(with: .applePay)
    }

    func walletHeaderViewPayWithLinkTapped(_ header: PaymentSheetViewController.WalletHeaderView) {
        guard !isFlowController else {
            // If flow controller, note that the button was tapped and dismiss
            isLinkWalletButtonSelected = true
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: false)
            return
        }

        paymentSheetDelegate?.paymentSheetViewControllerDidSelectPayWithLink(self)
    }
}
