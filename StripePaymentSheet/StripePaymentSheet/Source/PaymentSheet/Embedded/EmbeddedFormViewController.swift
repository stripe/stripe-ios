//
//  EmbeddedFormViewController.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 10/14/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

@MainActor protocol EmbeddedFormViewControllerDelegate: AnyObject {

    /// Notifies the delegate to confirm the payment or setup with the provided payment option.
    /// This method is called when the user taps the primary button (e.g., "Buy") while `formSheetAction` is set to `.confirm`.
    /// - Parameters:
    ///   - embeddedFormViewController: The view controller requesting the confirmation.
    ///   - completion: A completion handler to call with the `PaymentSheetResult` from the confirmation attempt.
    func embeddedFormViewControllerShouldConfirm(
        _ embeddedFormViewController: EmbeddedFormViewController,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    )

    /// This method is called when the user taps the primary button (e.g., "Buy") while `formSheetAction` is set to `.confirm` after confirmation completes.
    /// - Parameters:
    ///   - embeddedFormViewController: The view controller that has finished.
    ///   - result: The `PaymentSheetResult` of the payment or setup process.
    func embeddedFormViewControllerDidCompleteConfirmation(
        _ embeddedFormViewController: EmbeddedFormViewController,
        result: PaymentSheetResult
    )

    /// Informs the delegate that the user has canceled out of the form.
    /// This method is called when the user dismisses the view controller or taps the cancel button.
    /// - Parameter embeddedFormViewController: The view controller that was canceled.
    func embeddedFormViewControllerDidCancel(_ embeddedFormViewController: EmbeddedFormViewController)

    /// Notifies the delegate that the user completed the form and tapped the primary button..
    /// This method is called when a payment option that can be confirmed later has been provided.
    /// - Parameter embeddedFormViewController: The view controller requesting to close.
    func embeddedFormViewControllerDidContinue(_ embeddedFormViewController: EmbeddedFormViewController)
}

class EmbeddedFormViewController: UIViewController {

    /// Returns true if confirmation does not occur while the form is presented and instead is trigged by `EmbeddedPaymentElement.confirm` when the form is dismissed.
    private var shouldDeferConfirmation: Bool {
        switch configuration.formSheetAction {
        case .confirm:
            return false
        case .continue:
            return true
        }
    }

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

    var collectsUserInput: Bool {
        return paymentMethodFormViewController.form.collectsUserInput
    }

    enum Error: Swift.Error {
        case noPaymentOptionOnBuyButtonTap
    }
    var selectedPaymentOption: PaymentSheet.PaymentOption? {
        return paymentMethodFormViewController.paymentOption
    }

    private let paymentMethodType: PaymentSheet.PaymentMethodType
    private let configuration: EmbeddedPaymentElement.Configuration
    private let intent: Intent
    private let elementsSession: STPElementsSession
    private let shouldUseNewCardNewCardHeader: Bool
    private let formCache: PaymentMethodFormCache
    private let analyticsHelper: PaymentSheetAnalyticsHelper
    private var error: Swift.Error?
    private var isPaymentInFlight: Bool = false
    /// Previous customer input - in the `update` flow, this is the customer input prior to `update`, used so we can restore their state in this VC.
    private(set) var previousPaymentOption: PaymentOption?

    // MARK: - UI properties

    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()

    private lazy var paymentContainerView: DynamicHeightContainerView = {
        DynamicHeightContainerView()
    }()

    private lazy var primaryButton: ConfirmButton = {
        ConfirmButton(
            callToAction: .setup, // Dummy value; real value is set after init
            applePayButtonType: configuration.applePay?.buttonType ?? .plain,
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapPrimaryButton()
            }
        )
    }()

    private lazy var paymentMethodFormViewController: PaymentMethodFormViewController = {
        let previousCustomerInput: IntentConfirmParams? = {
            if case let .new(confirmParams: confirmParams) = previousPaymentOption {
                return confirmParams
            } else {
                return nil
            }
        }()

        let headerView = FormHeaderView(
            paymentMethodType: paymentMethodType,
            // Special case: use "New Card" instead of "Card" if the displayed saved PM is a card
            shouldUseNewCardHeader: shouldUseNewCardNewCardHeader,
            appearance: configuration.appearance,
            currency: intent.currency,
            incentive: elementsSession.incentive?.takeIfAppliesTo(paymentMethodType)
        )

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
    }()

    private lazy var mandateView = SimpleMandateTextView(theme: configuration.appearance.asElementsTheme)
    private lazy var errorLabel = ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
    private let stackView: UIStackView = UIStackView()

    weak var delegate: EmbeddedFormViewControllerDelegate?

    init(configuration: EmbeddedPaymentElement.Configuration,
         intent: Intent,
         elementsSession: STPElementsSession,
         shouldUseNewCardNewCardHeader: Bool,
         paymentMethodType: PaymentSheet.PaymentMethodType,
         previousPaymentOption: PaymentOption? = nil,
         analyticsHelper: PaymentSheetAnalyticsHelper,
         formCache: PaymentMethodFormCache = .init(),
         delegate: EmbeddedFormViewControllerDelegate
    ) {
        self.intent = intent
        self.elementsSession = elementsSession
        self.shouldUseNewCardNewCardHeader = shouldUseNewCardNewCardHeader
        self.configuration = configuration
        self.previousPaymentOption = previousPaymentOption
        self.analyticsHelper = analyticsHelper
        self.paymentMethodType = paymentMethodType
        self.formCache = formCache
        self.delegate = delegate

        super.init(nibName: nil, bundle: nil)

        add(childViewController: paymentMethodFormViewController, containerView: paymentContainerView)
        updateUI()
    }

    /// Updates all UI elements (pay button, error, mandate)
    private func updateUI() {
        updatePrimaryButton()
        updateMandate()
        updateError()
    }

    private func updatePrimaryButton() {
        let callToAction: ConfirmButton.CallToActionType = {
            if let override = paymentMethodFormViewController.overridePrimaryButtonState {
                return override.ctaType
            }
            if let customCtaLabel = configuration.primaryButtonLabel {
                return shouldDeferConfirmation ? .custom(title: customCtaLabel) : .customWithLock(title: customCtaLabel)
            }

            if shouldDeferConfirmation {
                return .continue
            }
            return .makeDefaultTypeForPaymentSheet(intent: intent)
        }()
        let state: ConfirmButton.Status = {
            if isPaymentInFlight {
                return .processing
            }
            if let override = paymentMethodFormViewController.overridePrimaryButtonState {
                return override.enabled ? .enabled : .disabled
            }
            return selectedPaymentOption == nil ? .disabled : .enabled
        }()
        primaryButton.update(
            state: state,
            style: .stripe,
            callToAction: callToAction,
            animated: true
        )
    }

    func updateMandate() {
        let mandateProvider = VerticalListMandateProvider(configuration: configuration, elementsSession: elementsSession, intent: intent, analyticsHelper: analyticsHelper)
        let newMandateText = mandateProvider.mandate(
            for: selectedPaymentOption?.paymentMethodType,
            savedPaymentMethod: selectedPaymentOption?.savedPaymentMethod,
            bottomNoticeAttributedString: paymentMethodFormViewController.bottomNoticeAttributedString
        )
        animateHeightChange {
            self.mandateView.attributedText = newMandateText
            self.mandateView.setHiddenIfNecessary(newMandateText == nil)
        }
    }

    private func updateError() {
        errorLabel.text = error?.nonGenericDescription
        animateHeightChange({ [self] in
            errorLabel.setHiddenIfNecessary(error == nil)
            if error != nil {
                // TODO(porter) Don't think we need this
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

    private func didCancel() {
        if let delegate {
            delegate.embeddedFormViewControllerDidCancel(self)
        } else {
            stpAssertionFailure()
            dismiss(animated: true)
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

    // MARK: - Confirmation handling

    private func pay(with paymentOption: PaymentOption) {
        view.endEditing(true)
        isPaymentInFlight = true
        error = nil
        updateError()
        updatePrimaryButton()
        isUserInteractionEnabled = false

        // Confirm the payment with the payment option
        let startTime = NSDate.timeIntervalSinceReferenceDate
        delegate?.embeddedFormViewControllerShouldConfirm(self, with: paymentOption) { result, _ in
            let elapsedTime = NSDate.timeIntervalSinceReferenceDate - startTime
            DispatchQueue.main.asyncAfter(
                deadline: .now() + max(PaymentSheetUI.minimumFlightTime - elapsedTime, 0)
            ) { [self] in
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
                            self.delegate?.embeddedFormViewControllerDidCompleteConfirmation(self, result: result)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Tap handling

    @objc func didTapPrimaryButton() {
        // If the form has overridden the primary buy button, hand control over to the form
        guard paymentMethodFormViewController.overridePrimaryButtonState == nil else {
            paymentMethodFormViewController.didTapCallToActionButton(from: self)
            return
        }

        // Otherwise, grab the payment option
        guard let selectedPaymentOption else {
            // TODO(wooj) Log an error here that is not specific to PaymentSheetViewController
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetViewControllerError, error: Error.noPaymentOptionOnBuyButtonTap)
             STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Tapped buy button while adding without paymentOption")
            return
        }

        // Send analytic when primary button is tapped
        analyticsHelper.logConfirmButtonTapped(paymentOption: selectedPaymentOption)

        // If we defer confirmation, simply close the sheet
        if shouldDeferConfirmation {
            self.delegate?.embeddedFormViewControllerDidContinue(self)
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

// MARK: - SheetNavigationBarDelegate
extension EmbeddedFormViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didCancel()
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // no-op, embedded should never have nested forms
    }
}

// MARK: - PaymentMethodFormViewControllerDelegate
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

extension EmbeddedFormViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }
}
