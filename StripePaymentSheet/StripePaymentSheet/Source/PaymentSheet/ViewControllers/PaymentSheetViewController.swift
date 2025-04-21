//
//  PaymentSheetViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/12/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// For internal SDK use only
@objc(STP_Internal_PaymentSheetViewController)
class PaymentSheetViewController: UIViewController, PaymentSheetViewControllerProtocol {
    enum PaymentSheetViewControllerError: Error {
        case addingNewNoPaymentOptionOnBuyButtonTap
        case selectingSavedNoPaymentOptionOnBuyButtonTap
        case sheetNavigationBarDidBack
    }

    // MARK: - Read-only Properties
    var savedPaymentMethods: [STPPaymentMethod] {
        return savedPaymentOptionsViewController.savedPaymentMethods
    }
    let isApplePayEnabled: Bool
    let configuration: PaymentSheet.Configuration

    let isLinkEnabled: Bool
    let isCVCRecollectionEnabled: Bool

    var isWalletEnabled: Bool {
        return isApplePayEnabled || isLinkEnabled
    }

    var shouldShowWalletHeader: Bool {
        switch mode {
        case .addingNew:
            return isWalletEnabled
        case .selectingSaved:
            return isLinkEnabled || isApplePayEnabled
        }
    }
    let intent: Intent
    let elementsSession: STPElementsSession
    let loadResult: PaymentSheetLoader.LoadResult
    let formCache: PaymentMethodFormCache = .init()
    let analyticsHelper: PaymentSheetAnalyticsHelper

    // MARK: - Writable Properties
    weak var delegate: PaymentSheetViewControllerDelegate?
    enum Mode {
        case selectingSaved
        case addingNew
    }
    private var mode: Mode
    private(set) var error: Error?
    private var isPaymentInFlight: Bool = false
    private(set) var isDismissable: Bool = true

    private lazy var savedPaymentMethodManager: SavedPaymentMethodManager = {
        return SavedPaymentMethodManager(configuration: configuration, elementsSession: elementsSession)
    }()

    // MARK: - Views

    private lazy var addPaymentMethodViewController: AddPaymentMethodViewController = {
        return AddPaymentMethodViewController(
            intent: intent,
            elementsSession: elementsSession,
            configuration: configuration,
            paymentMethodTypes: loadResult.paymentMethodTypes,
            formCache: formCache,
            analyticsHelper: analyticsHelper,
            delegate: self
        )
    }()

    private let savedPaymentOptionsViewController: SavedPaymentOptionsViewController
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()
    private lazy var walletHeader: WalletHeaderView = {
        var walletOptions: WalletHeaderView.WalletOptions = []

        if isApplePayEnabled {
            walletOptions.insert(.applePay)
        }

        if isLinkEnabled {
            walletOptions.insert(.link)
        }

        let header = WalletHeaderView(
            options: walletOptions,
            appearance: configuration.appearance,
            applePayButtonType: configuration.applePay?.buttonType ?? .plain,
            isPaymentIntent: intent.isPaymentIntent,
            delegate: self
        )
        return header
    }()
    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
    }()
    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()
    private lazy var errorLabel: UILabel = {
        return ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
    }()
    private lazy var bottomNoticeTextField: UITextView = {
        return ElementsUI.makeNoticeTextField(theme: configuration.appearance.asElementsTheme)
    }()
    private lazy var buyButton: ConfirmButton = {
        let callToAction: ConfirmButton.CallToActionType = {
            if let customCtaLabel = configuration.primaryButtonLabel {
                return .customWithLock(title: customCtaLabel)
            }

            return .makeDefaultTypeForPaymentSheet(intent: intent)
        }()

        let button = ConfirmButton(
            callToAction: callToAction,
            applePayButtonType: configuration.applePay?.buttonType ?? .plain,
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapBuyButton()
            }
        )
        return button
    }()

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        configuration: PaymentSheet.Configuration,
        loadResult: PaymentSheetLoader.LoadResult,
        analyticsHelper: PaymentSheetAnalyticsHelper,
        delegate: PaymentSheetViewControllerDelegate
    ) {
        // Only call loadResult.intent.cvcRecollectionEnabled once per load
        let isCVCRecollectionEnabled = loadResult.intent.cvcRecollectionEnabled

        self.loadResult = loadResult
        self.intent = loadResult.intent
        self.elementsSession = loadResult.elementsSession
        self.configuration = configuration
        self.isApplePayEnabled = PaymentSheet.isApplePayEnabled(elementsSession: elementsSession, configuration: configuration)
        self.isLinkEnabled = PaymentSheet.isLinkEnabled(elementsSession: elementsSession, configuration: configuration)
        self.isCVCRecollectionEnabled = isCVCRecollectionEnabled
        self.delegate = delegate
        self.savedPaymentOptionsViewController = SavedPaymentOptionsViewController(
            savedPaymentMethods: loadResult.savedPaymentMethods,
            configuration: .init(
                customerID: configuration.customer?.id,
                showApplePay: false,
                showLink: false,
                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                merchantDisplayName: configuration.merchantDisplayName,
                isCVCRecollectionEnabled: isCVCRecollectionEnabled,
                isTestMode: configuration.apiClient.isTestmode,
                allowsRemovalOfLastSavedPaymentMethod: elementsSession.paymentMethodRemoveLast(configuration: configuration),
                allowsRemovalOfPaymentMethods: loadResult.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet(),
                allowsSetAsDefaultPM: elementsSession.paymentMethodSetAsDefaultForPaymentSheet,
                allowsUpdatePaymentMethod: elementsSession.paymentMethodUpdateForPaymentSheet
            ),
            paymentSheetConfiguration: configuration,
            intent: intent,
            appearance: configuration.appearance,
            elementsSession: elementsSession,
            cbcEligible: elementsSession.isCardBrandChoiceEligible,
            analyticsHelper: analyticsHelper
        )

        if loadResult.savedPaymentMethods.isEmpty {
            self.mode = .addingNew
        } else {
            self.mode = .selectingSaved
        }
        self.analyticsHelper = analyticsHelper

        super.init(nibName: nil, bundle: nil)
        self.configuration.style.configure(self)
        self.savedPaymentOptionsViewController.delegate = self
        // TODO: This self.view call should be moved to viewDidLoad
        self.view.backgroundColor = configuration.appearance.colors.background
    }

    // MARK: UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = configuration.appearance.colors.background

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel, walletHeader, paymentContainerView, errorLabel, buyButton, bottomNoticeTextField,
        ])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.bringSubviewToFront(headerLabel)
        stackView.setCustomSpacing(32, after: paymentContainerView)
        stackView.setCustomSpacing(0, after: buyButton)

        // Hack: Payment container needs to extend to the edges, so we'll 'cancel out' the layout margins with negative padding
        paymentContainerView.directionalLayoutMargins = .insets(
            leading: -PaymentSheetUI.defaultSheetMargins.leading,
            trailing: -PaymentSheetUI.defaultSheetMargins.trailing
        )

        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor,
                constant: -PaymentSheetUI.defaultSheetMargins.bottom
            ),
        ])

        updateUI(animated: false)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        analyticsHelper.logShow(showingSavedPMList: mode == .selectingSaved)
    }

    func set(error: Error?) {
        self.error = error
        self.errorLabel.text = error?.nonGenericDescription
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.errorLabel.setHiddenIfNecessary(self.error == nil)
        }
    }

    // MARK: Private Methods

    private func configureNavBar() {
        navigationBar.setStyle(
            {
                switch mode {
                case .selectingSaved:
                    if self.savedPaymentOptionsViewController.canEditPaymentMethods {
                        self.configureEditSavedPaymentMethodsButton()
                        return .close(showAdditionalButton: true)
                    } else {
                        self.navigationBar.additionalButton.removeTarget(
                            self,
                            action: #selector(didSelectEditSavedPaymentMethodsButton),
                            for: .touchUpInside
                        )
                        return .close(showAdditionalButton: false)
                    }
                case .addingNew:
                    self.navigationBar.additionalButton.removeTarget(
                        self,
                        action: #selector(didSelectEditSavedPaymentMethodsButton),
                        for: .touchUpInside
                    )
                    return !savedPaymentOptionsViewController.hasPaymentOptions ? .close(showAdditionalButton: false) : .back(showAdditionalButton: false)
                }
            }()
        )

    }

    // state -> view
    private func updateUI(animated: Bool = true) {
        // Disable interaction if necessary
        let shouldEnableUserInteraction = !isPaymentInFlight
        if shouldEnableUserInteraction != view.isUserInteractionEnabled {
            sendEventToSubviews(
                shouldEnableUserInteraction ? .shouldEnableUserInteraction : .shouldDisableUserInteraction,
                from: view
            )
        }
        view.isUserInteractionEnabled = shouldEnableUserInteraction
        isDismissable = !isPaymentInFlight
        navigationBar.isUserInteractionEnabled = !isPaymentInFlight

        // Update our views (starting from the top of the screen):
        configureNavBar()

        // Content header
        walletHeader.isHidden = !shouldShowWalletHeader
        walletHeader.showsCardPaymentMessage = (addPaymentMethodViewController.paymentMethodTypes == [.stripe(.card)])

        switch mode {
        case .addingNew:
            headerLabel.isHidden = isWalletEnabled
            headerLabel.text = configuration.addCardHeaderText ?? STPLocalizedString(
                "Add your payment information",
                "Title shown above a form where the customer can enter payment information like credit card details, email, billing address, etc."
            )
        case .selectingSaved:
            headerLabel.isHidden = shouldShowWalletHeader
            headerLabel.text = .Localized.select_your_payment_method
        }

        // Content
        switchContentIfNecessary(
            to: mode == .selectingSaved
                ? savedPaymentOptionsViewController : addPaymentMethodViewController,
            containerView: paymentContainerView
        )

        // Error
        errorLabel.text = error?.nonGenericDescription
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.errorLabel.setHiddenIfNecessary(self.error == nil)
        }

        // Buy button
        let buyButtonStyle: ConfirmButton.Style
        var buyButtonStatus: ConfirmButton.Status
        var showBuyButton: Bool = true

        var callToAction = self.intent.callToAction
        if let customCtaLabel = configuration.primaryButtonLabel {
            callToAction = .customWithLock(title: customCtaLabel)
        }
        switch mode {
        case .selectingSaved:
            if case .applePay = savedPaymentOptionsViewController.selectedPaymentOption {
                buyButtonStyle = .applePay
            } else {
                buyButtonStyle = .stripe
            }
            buyButtonStatus = buyButtonEnabledForSavedPayments()
            showBuyButton = savedPaymentOptionsViewController.selectedPaymentOption != nil
        case .addingNew:
            buyButtonStyle = .stripe
            if let overridePrimaryButtonState = addPaymentMethodViewController.overridePrimaryButtonState {
                callToAction = overridePrimaryButtonState.ctaType
                buyButtonStatus = overridePrimaryButtonState.enabled ? .enabled : .disabled
            } else {
                buyButtonStatus = addPaymentMethodViewController.paymentOption == nil ? .disabled : .enabled
            }
        }

        // Notice
        updateBottomNotice()

        if isPaymentInFlight {
            buyButtonStatus = .processing
        }
        self.buyButton.update(
            state: buyButtonStatus,
            style: buyButtonStyle,
            callToAction: callToAction,
            animated: animated,
            completion: nil
        )

        let updateButtonVisibility = {
            self.buyButton.isHidden = !showBuyButton
        }

        if animated {
            animateHeightChange(updateButtonVisibility)
        } else {
            updateButtonVisibility()
        }
    }

    func buyButtonEnabledForSavedPayments() -> ConfirmButton.Status {
        if savedPaymentOptionsViewController.isRemovingPaymentMethods || (savedPaymentOptionsViewController.selectedPaymentOptionIntentConfirmParamsRequired &&
            savedPaymentOptionsViewController.selectedPaymentOptionIntentConfirmParams == nil) {
            return .disabled
        }
        return .enabled
    }

    func updateBottomNotice() {
        switch mode {
        case .selectingSaved:
            self.bottomNoticeTextField.attributedText = savedPaymentOptionsViewController.bottomNoticeAttributedString
        case .addingNew:
            self.bottomNoticeTextField.attributedText = addPaymentMethodViewController.bottomNoticeAttributedString
        }
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.bottomNoticeTextField.setHiddenIfNecessary(self.bottomNoticeTextField.attributedText?.length == 0)
        }
    }

    @objc
    private func didTapBuyButton() {
        let paymentOption: PaymentOption
        switch mode {
        case .addingNew:
            if addPaymentMethodViewController.overridePrimaryButtonState != nil {
                addPaymentMethodViewController.didTapCallToActionButton(from: self)
                return
            } else {
                guard let newPaymentOption = addPaymentMethodViewController.paymentOption else {
                    let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetViewControllerError,
                                                      error: PaymentSheetViewControllerError.addingNewNoPaymentOptionOnBuyButtonTap,
                                                      additionalNonPIIParams: [:])
                    STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                    stpAssertionFailure("Tapped buy button while adding without paymentOption")
                    return
                }
                paymentOption = newPaymentOption
            }
        case .selectingSaved:
            guard
                let selectedPaymentOption = savedPaymentOptionsViewController.selectedPaymentOption
            else {
                let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetViewControllerError,
                                                  error: PaymentSheetViewControllerError.selectingSavedNoPaymentOptionOnBuyButtonTap,
                                                  additionalNonPIIParams: [:])
                STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
                stpAssertionFailure("Tapped buy button while selecting saved without paymentOption")
                return
            }
            paymentOption = selectedPaymentOption
        }
        analyticsHelper.logConfirmButtonTapped(paymentOption: paymentOption)
        pay(with: paymentOption)
    }

    func pay(with paymentOption: PaymentOption) {
        view.endEditing(true)
        isPaymentInFlight = true
        // Clear any errors
        error = nil
        updateUI()

        // Confirm the payment with the payment option
        let startTime = NSDate.timeIntervalSinceReferenceDate
        self.delegate?.paymentSheetViewControllerShouldConfirm(self, with: paymentOption) { result, deferredIntentConfirmationType in
            let elapsedTime = NSDate.timeIntervalSinceReferenceDate - startTime
            DispatchQueue.main.asyncAfter(
                deadline: .now() + max(PaymentSheetUI.minimumFlightTime - elapsedTime, 0)
            ) {
                self.analyticsHelper.logPayment(
                    paymentOption: paymentOption,
                    result: result,
                    deferredIntentConfirmationType: deferredIntentConfirmationType
                )
                self.isPaymentInFlight = false
                switch result {
                case .canceled:
                    // Do nothing, keep customer on payment sheet
                    self.updateUI()
                case .failed(let error):
                    #if !canImport(CompositorServices)
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    #endif
                    // Update state
                    self.error = error
                    self.updateUI()
                    UIAccessibility.post(notification: .layoutChanged, argument: self.errorLabel)
                case .completed:
                    // We're done!
                    let delay: TimeInterval = self.presentedViewController?.isBeingDismissed == true ? 1 : 0
                    // Hack: PaymentHandler calls the completion block while SafariVC is still being dismissed - "wait" until it's finished before updating UI
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
#if !canImport(CompositorServices)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
                        self.buyButton.update(state: .succeeded, animated: true) {
                            // Wait a bit before closing the sheet
                            self.delegate?.paymentSheetViewControllerDidFinish(self, result: .completed)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Wallet Header Delegate

extension PaymentSheetViewController: WalletHeaderViewDelegate {

    func walletHeaderViewApplePayButtonTapped(_ header: WalletHeaderView) {
        set(error: nil)
        pay(with: .applePay)
    }

    func walletHeaderViewPayWithLinkTapped(_ header: WalletHeaderView) {
        set(error: nil)
        delegate?.paymentSheetViewControllerDidSelectPayWithLink(self)
    }

}

// MARK: - BottomSheetContentViewController
/// :nodoc:
extension PaymentSheetViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        if isDismissable {
            delegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: - SavedPaymentOptionsViewControllerDelegate
/// :nodoc:
extension PaymentSheetViewController: SavedPaymentOptionsViewControllerDelegate {

    func didUpdate(_ viewController: SavedPaymentOptionsViewController) {
        error = nil  // clear error
        updateUI()
    }

    func didSelectUpdateCardBrand(viewController: SavedPaymentOptionsViewController,
                                  paymentMethodSelection: SavedPaymentOptionsViewController.Selection,
                                  updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        guard case .saved(let paymentMethod) = paymentMethodSelection else {
            throw PaymentSheetError.unknown(debugDescription: "Failed to read payment method from payment method selection")
        }

        return try await savedPaymentMethodManager.update(paymentMethod: paymentMethod,
                                                                  with: updateParams)
    }

    func didSelectUpdateDefault(viewController: SavedPaymentOptionsViewController,
                                paymentMethodSelection: SavedPaymentOptionsViewController.Selection) async throws -> STPCustomer {
        guard case .saved(let paymentMethod) = paymentMethodSelection else {
            throw PaymentSheetError.unknown(debugDescription: "Failed to read payment method from payment method selection")
        }

        return try await savedPaymentMethodManager.setAsDefaultPaymentMethod(defaultPaymentMethodId: paymentMethod.stripeId)
    }

    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        analyticsHelper.logSavedPMScreenOptionSelected(option: paymentMethodSelection)
        if case .add = paymentMethodSelection {
            mode = .addingNew
            error = nil  // Clear any errors
        }
        updateUI()
    }

    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        guard case .saved(let paymentMethod) = paymentMethodSelection else {
            return
        }

        savedPaymentMethodManager.detach(paymentMethod: paymentMethod)
        analyticsHelper.logSavedPaymentMethodRemoved(paymentMethod: paymentMethod)

        if !savedPaymentOptionsViewController.canEditPaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
        }

        // If there are no more options in the saved screen, switch to the "add" screen
        if !savedPaymentOptionsViewController.hasPaymentOptions {
            error = nil  // Clear any errors
            mode = .addingNew // Switch to the "Add" screen
        }
        updateUI()
    }

    func shouldCloseSheet(_ viewController: SavedPaymentOptionsViewController) {
        if isDismissable {
            delegate?.paymentSheetViewControllerDidCancel(self)
        }
    }

    // MARK: Helpers
    func configureEditSavedPaymentMethodsButton() {
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            buyButton.update(state: .disabled)
        } else {
            buyButton.update(state: buyButtonEnabledForSavedPayments())
        }
        navigationBar.additionalButton.configureCommonEditButton(isEditingPaymentMethods: savedPaymentOptionsViewController.isRemovingPaymentMethods, appearance: configuration.appearance)
        navigationBar.additionalButton.addTarget(
            self,
            action: #selector(didSelectEditSavedPaymentMethodsButton),
            for: .touchUpInside
        )
    }

    @objc
    func didSelectEditSavedPaymentMethodsButton() {
        savedPaymentOptionsViewController.isRemovingPaymentMethods.toggle()
        configureEditSavedPaymentMethodsButton()
    }

    func clearTextFields() {
        addPaymentMethodViewController.clearTextFields()
    }
}

// MARK: - AddPaymentMethodViewControllerDelegate
/// :nodoc:
extension PaymentSheetViewController: AddPaymentMethodViewControllerDelegate {
    func getWalletHeaders() -> [String] {
        var walletHeaders: [String] = []
        if isApplePayEnabled {
            walletHeaders.append("apple_pay")
        }
        if isLinkEnabled {
            walletHeaders.append("link")
        }
        return walletHeaders
    }

    func didUpdate(_ viewController: AddPaymentMethodViewController) {
        error = nil  // clear error
        updateUI()
        if viewController.paymentOption != nil {
            analyticsHelper.logFormCompleted(paymentMethodTypeIdentifier: viewController.selectedPaymentMethodType.identifier)
        }
    }

    func updateErrorLabel(for error: Error?) {
        set(error: error)
    }
}

// MARK: - SheetNavigationBarDelegate
/// :nodoc:
extension PaymentSheetViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.paymentSheetViewControllerDidCancel(self)
        // If the customer was editing saved payment methods, exit edit mode
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            configureEditSavedPaymentMethodsButton()
        }

    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // This is quite hardcoded. Could make some generic "previous state" or "previous VC" that we always go back to
        switch mode {
        case .addingNew:
            error = nil
            mode = .selectingSaved
            updateUI()
        default:
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetViewControllerError,
                                              error: PaymentSheetViewControllerError.sheetNavigationBarDidBack,
                                              additionalNonPIIParams: [:])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure("Tapped back button in invalid mode")
        }
    }
}
