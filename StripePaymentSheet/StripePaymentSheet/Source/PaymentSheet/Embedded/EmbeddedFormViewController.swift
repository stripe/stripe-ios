//
//  EmbeddedFormViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/8/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class EmbeddedFormViewController: UIViewController, FlowControllerViewControllerProtocol, PaymentSheetViewControllerProtocol {

    var collectsUserInput: Bool {
        return paymentMethodFormViewController?.form.collectsUserInput ?? false
    }

    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType? {
        return paymentMethodType
    }

    enum Error: Swift.Error {
        case missingPaymentMethodListViewController
        case missingContentViewController
        case noPaymentOptionOnBuyButtonTap
    }
    var selectedPaymentOption: PaymentSheet.PaymentOption? {
        if let paymentMethodFormViewController {
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
    let loadResult: PaymentSheetLoader.LoadResult
    let paymentMethodType: PaymentSheet.PaymentMethodType
    let configuration: PaymentElementConfiguration
    let intent: Intent
    let elementsSession: STPElementsSession
    let formCache: PaymentMethodFormCache = .init()
    let analyticsHelper: PaymentSheetAnalyticsHelper
    var error: Swift.Error?
    var isPaymentInFlight: Bool = false
    let isFlowController: Bool
    /// Previous customer input - in FlowController's `update` flow, this is the customer input prior to `update`, used so we can restore their state in this VC.
    private var previousPaymentOption: PaymentOption?
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate?
    weak var paymentSheetDelegate: PaymentSheetViewControllerDelegate?
    /// The content offset % of the payment method list before we transitioned away from it
    var paymentMethodListContentOffsetPercentage: CGFloat?
    /// True while we are showing the CVC recollection UI (`cvcRecollectionViewController`)
    var isRecollectingCVC: Bool = false
    /// Variable to decide we should collect CVC
    var isCVCRecollectionEnabled: Bool

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()

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

    // TOOD(porter) Do we show mandates in the form?
    private lazy var mandateView = { SimpleMandateTextView(theme: configuration.appearance.asElementsTheme) }()
    private lazy var errorLabel: UILabel = {
        ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
    }()
    let stackView: UIStackView = UIStackView()

    // MARK: - Initializers

    init(configuration: PaymentElementConfiguration, loadResult: PaymentSheetLoader.LoadResult, isFlowController: Bool, paymentMethodType: PaymentSheet.PaymentMethodType, previousPaymentOption: PaymentOption? = nil, analyticsHelper: PaymentSheetAnalyticsHelper) {
        // Only call loadResult.intent.cvcRecollectionEnabled once per load
        self.isCVCRecollectionEnabled = loadResult.intent.cvcRecollectionEnabled

        self.loadResult = loadResult
        self.intent = loadResult.intent
        self.elementsSession = loadResult.elementsSession
        self.configuration = configuration
        self.previousPaymentOption = previousPaymentOption
        self.isFlowController = isFlowController
        self.analyticsHelper = analyticsHelper
        self.paymentMethodType = paymentMethodType

        super.init(nibName: nil, bundle: nil)

        regenerateUI()
        // Only use the previous customer input for the first form shown
        self.previousPaymentOption = nil
    }

    /// Regenerates the main content - either the PM list or the PM form and updates all UI elements (pay button, error, mandate)
    func regenerateUI(updatedListSelection: VerticalPaymentMethodListSelection? = nil) {
        if let paymentMethodFormViewController {
            remove(childViewController: paymentMethodFormViewController)
        }
        // If we'd only show one PM in the vertical list and it's `card`, display the form instead of the payment method list.
        let formVC = makeFormVC(paymentMethodType: paymentMethodType)
        self.paymentMethodFormViewController = formVC
        add(childViewController: formVC, containerView: paymentContainerView)
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

    private func makeFormVC(paymentMethodType: PaymentSheet.PaymentMethodType) -> PaymentMethodFormViewController {
        let previousCustomerInput: IntentConfirmParams? = {
            if case let .new(confirmParams: confirmParams) = previousPaymentOption {
                return confirmParams
            } else {
                return nil
            }
        }()
        let headerView: UIView = {
            return FormHeaderView(
                paymentMethodType: paymentMethodType,
                // Special case: use "New Card" instead of "Card" if the displayed saved PM is a card
                shouldUseNewCardHeader: loadResult.savedPaymentMethods.first?.type == .card,
                appearance: configuration.appearance
            )
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

    func updateMandate(animated: Bool = true) {
        let mandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent)
        let newMandateText = mandateProvider.mandate(for: selectedPaymentOption?.paymentMethodType,
                                                     savedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
                                                     bottomNoticeAttributedString: paymentMethodFormViewController?.bottomNoticeAttributedString)
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

    func didCancel() {
        if isFlowController {
            flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: true)
        } else {
            paymentSheetDelegate?.paymentSheetViewControllerDidCancel(self)
        }
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
}

// MARK: - BottomSheetContentViewController
extension EmbeddedFormViewController: BottomSheetContentViewController {
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

extension EmbeddedFormViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didCancel()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op, embedded should never have nested forms
    }
}

extension EmbeddedFormViewController: PaymentMethodFormViewControllerDelegate {
    func didUpdate(_ viewController: PaymentMethodFormViewController) {
        error = nil  // clear error
        updateUI()
        if viewController.paymentOption != nil {
            analyticsHelper.logFormCompleted(paymentMethodTypeIdentifier: viewController.paymentMethodType.identifier)
        }
    }

    func updateErrorLabel(for error: Swift.Error?) {
        self.error = error
        updateError()
    }
}

// MARK: - ElementDelegate
/// Used for CVC Recollection - we are the delegate of the CVC element
extension EmbeddedFormViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        updateUI()
    }

    func didUpdate(element: Element) {
        self.error = nil
        updateUI()
    }
}
