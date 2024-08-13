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
        case missingPaymentMethodListViewController
        case missingContentViewController
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
                let params = IntentConfirmParams(type: paymentMethodType)
                params.setDefaultBillingDetailsIfNecessary(for: configuration)
                switch paymentMethodType {
                case .stripe:
                    return .new(confirmParams: params)
                case .external(let type):
                    return .external(paymentMethod: type, billingDetails: params.paymentMethodParams.nonnil_billingDetails)
                case .instantDebits:
                    return .new(confirmParams: params)
                }
            case .saved(paymentMethod: let paymentMethod):
                return .saved(paymentMethod: paymentMethod, confirmParams: nil)
            }
        } else if let paymentMethodFormViewController {
            return paymentMethodFormViewController.paymentOption
        } else if isRecollectingCVC, let cvcRecollectionViewController {
            return cvcRecollectionViewController.paymentOption
        } else {
            stpAssertionFailure()
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError, error: Error.missingContentViewController, additionalNonPIIParams: ["error_message": "Missing content! Expected list, form, or cvc", "first_child_vc": String(describing: children.first)])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            return nil
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
    let intent: Intent
    let elementsSession: STPElementsSession
    let formCache: PaymentMethodFormCache = .init()
    let analyticsHelper: PaymentSheetAnalyticsHelper
    var error: Swift.Error?
    var isPaymentInFlight: Bool = false
    private var savedPaymentMethods: [STPPaymentMethod]
    let isFlowController: Bool
    /// Previous customer input - in FlowController's `update` flow, this is the customer input prior to `update`, used so we can restore their state in this VC.
    private var previousPaymentOption: PaymentOption?
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate?
    weak var paymentSheetDelegate: PaymentSheetViewControllerDelegate?
    let shouldShowApplePayInList: Bool
    let shouldShowLinkInList: Bool
    /// Whether or not we are in the special case where we don't show the list and show the card form directly
    var shouldDisplayCardFormOnly: Bool {
        return paymentMethodTypes.count == 1 && paymentMethodTypes[0] == .stripe(.card)
        && savedPaymentMethods.isEmpty
        && !shouldShowApplePayInList
        && !shouldShowLinkInList
    }
    /// The content offset % of the payment method list before we transitioned away from it
    var paymentMethodListContentOffsetPercentage: CGFloat?
    /// True while we are showing the CVC recollection UI (`cvcRecollectionViewController`)
    var isRecollectingCVC: Bool = false
    /// Variable to decide we should collect CVC
    var isCVCRecollectionEnabled: Bool

    private lazy var savedPaymentMethodManager: SavedPaymentMethodManager = {
        SavedPaymentMethodManager(configuration: configuration, elementsSession: elementsSession)
    }()

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
    var cvcRecollectionViewController: CVCReconfirmationVerticalViewController?

    lazy var paymentContainerView: DynamicHeightContainerView = {
        DynamicHeightContainerView()
    }()

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

    private lazy var mandateView = { SimpleMandateTextView(theme: configuration.appearance.asElementsTheme) }()
    private lazy var errorLabel: UILabel = {
        ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
    }()
    let stackView: UIStackView = UIStackView()

    // MARK: - Initializers

    init(configuration: PaymentSheet.Configuration, loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool, analyticsHelper: PaymentSheetAnalyticsHelper, previousPaymentOption: PaymentOption? = nil) {
        // Only call loadResult.intent.cvcRecollectionEnabled once per load
        self.isCVCRecollectionEnabled = loadResult.intent.cvcRecollectionEnabled

        self.loadResult = loadResult
        self.intent = loadResult.intent
        self.elementsSession = loadResult.elementsSession
        self.configuration = configuration
        self.previousPaymentOption = previousPaymentOption
        self.isFlowController = isFlowController
        self.savedPaymentMethods = loadResult.savedPaymentMethods
        self.paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: loadResult.intent,
            elementsSession: elementsSession,
            configuration: configuration,
            logAvailability: false
        )
        self.shouldShowApplePayInList = PaymentSheet.isApplePayEnabled(elementsSession: elementsSession, configuration: configuration) && isFlowController
        // Edge case: If Apple Pay isn't in the list, show Link as a wallet button and not in the list
        self.shouldShowLinkInList = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration) && isFlowController && shouldShowApplePayInList
        self.analyticsHelper = analyticsHelper
        super.init(nibName: nil, bundle: nil)

        regenerateUI()
        // Only use the previous customer input for the first form shown
        self.previousPaymentOption = nil
    }

    /// Regenerates the main content - either the PM list or the PM form and updates all UI elements (pay button, error, mandate)
    func regenerateUI(updatedListSelection: VerticalPaymentMethodListSelection? = nil) {
        // Remove any content vcs; we'll rebuild and add them now
        if let paymentMethodListViewController {
            remove(childViewController: paymentMethodListViewController)
        }
        if let paymentMethodFormViewController {
            remove(childViewController: paymentMethodFormViewController)
        }
        if shouldDisplayCardFormOnly {
            // If we'd only show one PM in the vertical list and it's `card`, display the form instead of the payment method list.
            let formVC = makeFormVC(paymentMethodType: .stripe(.card))
            self.paymentMethodFormViewController = formVC
            add(childViewController: formVC, containerView: paymentContainerView)
        } else {
            // Otherwise, we're using the list
            let paymentMethodListViewController = makePaymentMethodListViewController(selection: updatedListSelection)
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
            } else {
                // Otherwise, show the list of PMs
                add(childViewController: paymentMethodListViewController, containerView: paymentContainerView)
            }
        }
        updateUI()
    }

    /// Updates all UI elements (pay button, error, mandate)
    func updateUI() {
        updatePrimaryButton()
        updateMandate()
        updateError()
    }

    func updatePrimaryButton() {
        let callToAction: ConfirmButton.CallToActionType = {
            if let override = paymentMethodFormViewController?.overridePrimaryButtonState {
                return override.ctaType
            }
            if isRecollectingCVC {
                return .custom(title: String.Localized.confirm)
            }
            if let customCtaLabel = configuration.primaryButtonLabel {
                return isFlowController ? .custom(title: customCtaLabel) : .customWithLock(title: customCtaLabel)
            }

            if isFlowController {
                return .continue
            }
            return .makeDefaultTypeForPaymentSheet(intent: intent)
        }()
        let state: ConfirmButton.Status = {
            if isPaymentInFlight {
                return .processing
            }
            if let cvcRecollectionViewController, isRecollectingCVC {
                return cvcRecollectionViewController.paymentOptionIntentConfirmParams == nil ? .disabled : .enabled
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
        let theme = configuration.appearance.asElementsTheme
        let newMandateText: NSAttributedString? = {
            guard let selectedPaymentMethodType else { return nil }
            if selectedPaymentOption?.savedPaymentMethod != nil {
                // 1. For saved PMs, manually build mandates
                switch selectedPaymentMethodType {
                case .stripe(.USBankAccount):
                    return USBankAccountPaymentMethodElement.attributedMandateTextSavedPaymentMethod(alignment: .natural, theme: theme)
                case .stripe(.SEPADebit):
                    return .init(string: String(format: String.Localized.sepa_mandate_text, configuration.merchantDisplayName))
                default:
                    return nil
                }
            } else {
                // 2. For new PMs, see if we have a bottomNoticeAttributedString
                if let bottomNoticeAttributedString = paymentMethodFormViewController?.bottomNoticeAttributedString {
                    return bottomNoticeAttributedString
                }
                // 3. If not, generate the form
                let form = makeFormVC(paymentMethodType: selectedPaymentMethodType).form
                guard !form.collectsUserInput else {
                    // If it collects user input, the mandate will be displayed in the form and not here
                    return nil
                }
                // Get the mandate from the form, if available
                // 🙋‍♂️ Note: assumes mandates are SimpleMandateElement!
                return form.getAllUnwrappedSubElements().compactMap({ $0 as? SimpleMandateElement }).first?.mandateTextView.attributedText
            }
        }()
        animateHeightChange {
            self.mandateView.attributedText = newMandateText
            self.mandateView.setHiddenIfNecessary(newMandateText == nil)
        }
    }

    func updateError() {
        errorLabel.text = error?.nonGenericDescription
        animateHeightChange({ [self] in
            errorLabel.setHiddenIfNecessary(error == nil)
            if error != nil {
                // Without this, setting `contentOffsetPercentage = 1` uses the height of the scroll view without accounting for the error label
                errorLabel.setNeedsLayout()
                errorLabel.layoutIfNeeded()
            }
        }, postLayoutAnimations: {
            if self.error != nil {
                // Scroll the view to the bottom to ensure the error is visible
                self.bottomSheetController?.contentOffsetPercentage = 1
            }
        })
    }

    func makePaymentMethodListViewController(selection: VerticalPaymentMethodListSelection?) -> VerticalPaymentMethodListViewController {
        // Determine the initial selection - either `selection`, the previous payment option, the last VC's selection, or the customer's default.
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
                if let paymentMethodListViewController, let lastSelection = paymentMethodListViewController.currentSelection {
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
                // Default to the customer's default or the first saved payment method, if any
                let customerDefault = CustomerPaymentOption.defaultPaymentMethod(for: configuration.customer?.id)
                switch customerDefault {
                case .applePay:
                    return isFlowController ? .applePay : nil // Only default to Apple Pay in flow controller mode
                case .link:
                    return isFlowController ? .link : nil // Only default to Link in flow controller mode
                case .stripeId, nil:
                    return savedPaymentMethods.first.map { .saved(paymentMethod: $0) }
                }
            }
        }()
        let savedPaymentMethodAccessoryType = RowButton.RightAccessoryButton.getAccessoryButtonType(
            savedPaymentMethodsCount: savedPaymentMethods.count,
            isFirstCardCoBranded: savedPaymentMethods.first?.isCoBrandedCard ?? false,
            isCBCEligible: loadResult.elementsSession.isCardBrandChoiceEligible,
            allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
            allowsPaymentMethodRemoval: loadResult.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
        )
        return VerticalPaymentMethodListViewController(
            initialSelection: initialSelection,
            savedPaymentMethod: savedPaymentMethods.first,
            paymentMethodTypes: paymentMethodTypes,
            shouldShowApplePay: shouldShowApplePayInList,
            shouldShowLink: shouldShowLinkInList,
            savedPaymentMethodAccessoryType: savedPaymentMethodAccessoryType,
            overrideHeaderView: makeWalletHeaderView(),
            appearance: configuration.appearance,
            currency: loadResult.intent.currency,
            amount: loadResult.intent.amount,
            delegate: self
        )
    }

    func makeWalletHeaderView() -> UIView? {
        var walletOptions: PaymentSheetViewController.WalletHeaderView.WalletOptions = []
        if PaymentSheet.isApplePayEnabled(elementsSession: elementsSession, configuration: configuration) && !shouldShowApplePayInList {
            walletOptions.insert(.applePay)
        }
        if PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration) && !shouldShowLinkInList {
            walletOptions.insert(.link)
        }
        guard !walletOptions.isEmpty else {
            return nil
        }
        return PaymentSheetViewController.WalletHeaderView(
            options: walletOptions,
            appearance: configuration.appearance,
            applePayButtonType: configuration.applePay?.buttonType ?? .plain,
            isPaymentIntent: intent.isPaymentIntent,
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
        let views: [UIView] = [paymentContainerView, mandateView, errorLabel].compactMap { $0 }
        for view in views {
            stackView.addArrangedSubview(view)
        }
        stackView.spacing = 20
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.axis = .vertical
        stackView.sendSubviewToBack(mandateView)

        for subview in [stackView, primaryButton] {
            subview.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(subview)
        }
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            primaryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: PaymentSheetUI.defaultSheetMargins.leading),
            primaryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -PaymentSheetUI.defaultSheetMargins.trailing),

            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: primaryButton.topAnchor, constant: -32),
            primaryButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])
    }

    var didSendLogShow: Bool = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if !didSendLogShow {
            // Only send this once to match the behavior of horizontal mode
            didSendLogShow = true
            analyticsHelper.logShow(showingSavedPMList: false) // We never show the saved PM list first
        }
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
        updateError()
        updatePrimaryButton()
        isUserInteractionEnabled = false

        // Confirm the payment with the payment option
        let startTime = NSDate.timeIntervalSinceReferenceDate
        paymentSheetDelegate?.paymentSheetViewControllerShouldConfirm(self, with: paymentOption) { result, deferredIntentConfirmationType in
            let elapsedTime = NSDate.timeIntervalSinceReferenceDate - startTime
            DispatchQueue.main.asyncAfter(
                deadline: .now() + max(PaymentSheetUI.minimumFlightTime - elapsedTime, 0)
            ) { [self] in
                analyticsHelper.logPayment(
                    paymentOption: paymentOption,
                    result: result,
                    deferredIntentConfirmationType: deferredIntentConfirmationType
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

                    let nsError = error as NSError
                    let isCVCError = nsError.domain == STPError.stripeDomain && nsError.userInfo[STPError.errorParameterKey] as? String == "cvc"
                    if isRecollectingCVC,
                       !isCVCError {
                        // If we're recollecting CVC, pop back to the main list unless the error is for the cvc field
                        sheetNavigationBarDidBack(navigationBar)
                    }

                    // Update state
                    self.isUserInteractionEnabled = true
                    self.error = error
                    self.updateError()
                    self.updatePrimaryButton()
                    UIAccessibility.post(notification: .layoutChanged, argument: self.errorLabel)
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

        // Otherwise, grab the payment option
        guard let selectedPaymentOption else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetViewControllerError, error: Error.noPaymentOptionOnBuyButtonTap)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Tapped buy button while adding without paymentOption")
            return
        }

        // Send analytic when primary button is tapped
        analyticsHelper.logConfirmButtonTapped(paymentOption: selectedPaymentOption)

        // If FlowController, simply close the sheet
        if isFlowController {
            self.flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: false)
            return
        }

        // If the selected payment option is a saved card, CVC is enabled, and we are PS, handle CVC specially:
        if case let .saved(paymentMethod, _) = selectedPaymentOption, paymentMethod.type == .card, isCVCRecollectionEnabled, !isFlowController, !isRecollectingCVC {
            let cvcRecollectionViewController = CVCReconfirmationVerticalViewController(
                paymentMethod: paymentMethod,
                intent: intent,
                configuration: configuration,
                elementDelegate: self
            )
            self.cvcRecollectionViewController = cvcRecollectionViewController
            isRecollectingCVC = true
            paymentMethodListContentOffsetPercentage = bottomSheetController?.contentOffsetPercentage
            switchContentIfNecessary(to: cvcRecollectionViewController, containerView: paymentContainerView)
            navigationBar.setStyle(.back(showAdditionalButton: false))
            error = nil
            updateUI()
            return
        }

        pay(with: selectedPaymentOption)
    }

    @objc func presentManageScreen() {
        error = nil
        // Special case, only 1 card remaining but is co-branded, show update view controller
        if savedPaymentMethods.count == 1,
           let paymentMethod = savedPaymentMethods.first,
           paymentMethod.isCoBrandedCard,
           elementsSession.isCardBrandChoiceEligible {
            let updateViewController = UpdateCardViewController(paymentMethod: paymentMethod,
                                                                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                                                                appearance: configuration.appearance,
                                                                hostedSurface: .paymentSheet,
                                                                canRemoveCard: configuration.allowsRemovalOfLastSavedPaymentMethod && elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
                                                                isTestMode: configuration.apiClient.isTestmode)
            updateViewController.delegate = self
            bottomSheetController?.pushContentViewController(updateViewController)
            return
        }

        let vc = VerticalSavedPaymentMethodsViewController(
            configuration: configuration,
            selectedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
            paymentMethods: savedPaymentMethods,
            elementsSession: elementsSession,
            analyticsHelper: analyticsHelper
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
        didCancel()
    }

    var requiresFullScreen: Bool {
        return false
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

    func shouldClose() {
        didTapOrSwipeToDismiss()
    }
}

// MARK: - VerticalPaymentMethodListViewControllerDelegate

extension PaymentSheetVerticalViewController: VerticalPaymentMethodListViewControllerDelegate {

    func shouldSelectPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool {
        switch selection {
        case .applePay, .link:
            return true
        case let .new(paymentMethodType: paymentMethodType):
            // Only make payment methods appear selected in the list if they don't push to a form
            return !shouldDisplayForm(for: paymentMethodType)
        case .saved:
            return true
        }
    }

    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) {
        analyticsHelper.logNewPaymentMethodSelected(paymentMethodTypeIdentifier: selection.analyticsIdentifier)
        error = nil
#if !canImport(CompositorServices)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
        switch selection {
        case .applePay:
            CustomerPaymentOption.setDefaultPaymentMethod(.applePay, forCustomer: configuration.customer?.id)
        case .link:
            CustomerPaymentOption.setDefaultPaymentMethod(.link, forCustomer: configuration.customer?.id)
        case .saved(let paymentMethod):
            CustomerPaymentOption.setDefaultPaymentMethod(.stripeId(paymentMethod.stripeId), forCustomer: configuration.customer?.id)
        case let .new(paymentMethodType: paymentMethodType):
            let pmFormVC = makeFormVC(paymentMethodType: paymentMethodType)
            if pmFormVC.form.collectsUserInput {
                // The payment method form collects user input, display it
                self.paymentMethodFormViewController = pmFormVC
                paymentMethodListContentOffsetPercentage = bottomSheetController?.contentOffsetPercentage
                switchContentIfNecessary(to: pmFormVC, containerView: paymentContainerView, contentOffsetPercentage: 0)
                navigationBar.setStyle(.back(showAdditionalButton: false))
            }
        }
        updateUI()
    }

    func didTapSavedPaymentMethodAccessoryButton() {
#if !canImport(CompositorServices)
        UISelectionFeedbackGenerator().selectionChanged()
#endif
        presentManageScreen()
    }

    private func makeFormVC(paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentMethodFormViewController {
        let previousCustomerInput: IntentConfirmParams? = {
            if case let .new(confirmParams: confirmParams) = previousPaymentOption {
                return confirmParams
            } else {
                return nil
            }
        }()
        let headerView: UIView = {
            if shouldDisplayCardFormOnly, let wallet = makeWalletHeaderView() {
                return wallet
            } else {
                return FormHeaderView(
                    paymentMethodType: paymentMethodType,
                    // Special case: use "New Card" instead of "Card" if the displayed saved PM is a card
                    shouldUseNewCardHeader: savedPaymentMethods.first?.type == .card,
                    appearance: configuration.appearance
                )
            }
        }()
        return PaymentMethodFormViewController(
            type: paymentMethodType,
            intent: intent,
            elementsSession: elementsSession,
            previousCustomerInput: previousCustomerInput,
            formCache: formCache,
            configuration: configuration,
            headerView: headerView,
            analyticsHelper: analyticsHelper,
            delegate: self
        )
    }

    private func shouldDisplayForm(for paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        return PaymentSheetFormFactory(
            intent: intent,
            elementsSession: elementsSession,
            configuration: .paymentSheet(configuration),
            paymentMethod: paymentMethodType,
            previousCustomerInput: nil,
            linkAccount: LinkAccountContext.shared.account,
            analyticsHelper: analyticsHelper
        ).make().collectsUserInput
    }

    func didCancel() {
        if isFlowController {
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: true)
        } else {
            paymentSheetDelegate?.paymentSheetViewControllerDidCancel(self)
        }
    }
}

extension PaymentSheetVerticalViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didCancel()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // Hide the keyboard if it appeared and switch back to the vertical list
        view.endEditing(true)
        error = nil
        paymentMethodFormViewController = nil
        cvcRecollectionViewController = nil
        guard let paymentMethodListViewController else {
            stpAssertionFailure("Expected paymentMethodListViewController")
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError, error: Error.missingPaymentMethodListViewController)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            didCancel()
            return
        }
        if !isRecollectingCVC {
            paymentMethodListViewController.clearSelection()
        }
        isRecollectingCVC = false
        switchContentIfNecessary(to: paymentMethodListViewController, containerView: paymentContainerView, contentOffsetPercentage: paymentMethodListContentOffsetPercentage)
        navigationBar.setStyle(.close(showAdditionalButton: false))
        updateUI()
    }
}

// MARK: UpdateCardViewControllerDelegate
extension PaymentSheetVerticalViewController: UpdateCardViewControllerDelegate {
    func didRemove(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod) {
        // Detach the payment method from the customer
        savedPaymentMethodManager.detach(paymentMethod: paymentMethod)

        // Update savedPaymentMethods
        self.savedPaymentMethods.removeAll(where: { $0.stripeId == paymentMethod.stripeId })

        // Update UI
        regenerateUI()
        _ = viewController.bottomSheetController?.popContentViewController()
    }

    func didUpdate(viewController: UpdateCardViewController, paymentMethod: STPPaymentMethod, updateParams: STPPaymentMethodUpdateParams) async throws {
        // Update the payment method
        let updatedPaymentMethod = try await savedPaymentMethodManager.update(paymentMethod: paymentMethod, with: updateParams)

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
        error = nil  // clear error
        updateUI()
    }

    func updateErrorLabel(for error: Swift.Error?) {
        self.error = error
        updateError()
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

// MARK: - ElementDelegate
/// Used for CVC Recollection - we are the delegate of the CVC element
extension PaymentSheetVerticalViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        updateUI()
    }

    func didUpdate(element: Element) {
        self.error = nil
        updateUI()
    }
}
