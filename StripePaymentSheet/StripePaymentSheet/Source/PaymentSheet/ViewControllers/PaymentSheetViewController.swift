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

protocol PaymentSheetViewControllerDelegate: AnyObject {
    func paymentSheetViewControllerShouldConfirm(
        _ paymentSheetViewController: PaymentSheetViewController,
        with paymentOption: PaymentOption,
        completion: @escaping (PaymentSheetResult, STPAnalyticsClient.DeferredIntentConfirmationType?) -> Void
    )
    func paymentSheetViewControllerDidFinish(
        _ paymentSheetViewController: PaymentSheetViewController,
        result: PaymentSheetResult
    )
    func paymentSheetViewControllerDidCancel(
        _ paymentSheetViewController: PaymentSheetViewController
    )
    func paymentSheetViewControllerDidSelectPayWithLink(
        _ paymentSheetViewController: PaymentSheetViewController
    )
}

/// For internal SDK use only
@objc(STP_Internal_PaymentSheetViewController)
class PaymentSheetViewController: UIViewController {
    // MARK: - Read-only Properties
    let savedPaymentMethods: [STPPaymentMethod]
    let isApplePayEnabled: Bool
    let configuration: PaymentSheet.Configuration

    let isLinkEnabled: Bool

    var isWalletEnabled: Bool {
        return isApplePayEnabled || isLinkEnabled
    }

    var shouldShowWalletHeader: Bool {
        switch mode {
        case .addingNew:
            return isWalletEnabled
        case .selectingSaved:
            // When selecting saved we only add the wallet header for Link -- ApplePay by itself is inlined
            return isLinkEnabled
        }
    }

    // MARK: - Writable Properties
    weak var delegate: PaymentSheetViewControllerDelegate?
    private(set) var intent: Intent
    enum Mode {
        case selectingSaved
        case addingNew
    }
    private var mode: Mode
    private(set) var error: Error?
    private var isPaymentInFlight: Bool = false
    private(set) var isDismissable: Bool = true

    // MARK: - Views

    private lazy var addPaymentMethodViewController: AddPaymentMethodViewController = {
        return AddPaymentMethodViewController(
            intent: intent,
            configuration: configuration,
            delegate: self
        )
    }()
    private lazy var savedPaymentOptionsViewController: SavedPaymentOptionsViewController = {
        let showApplePay = !shouldShowWalletHeader && isApplePayEnabled
        let showLink = !shouldShowWalletHeader && isLinkEnabled

        return SavedPaymentOptionsViewController(
            savedPaymentMethods: savedPaymentMethods,
            configuration: .init(
                customerID: configuration.customer?.id,
                showApplePay: showApplePay,
                showLink: showLink,
                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                merchantDisplayName: configuration.merchantDisplayName
            ),
            appearance: configuration.appearance,
            delegate: self
        )
    }()
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

            switch intent {
            case .paymentIntent(let paymentIntent):
                return .pay(amount: paymentIntent.amount, currency: paymentIntent.currency)
            case .setupIntent:
                return .setup
            case .deferredIntent(_, let intentConfig):
                switch intentConfig.mode {
                case .payment(let amount, let currency, _, _):
                    return .pay(amount: amount, currency: currency)
                case .setup:
                    return .setup
                }
            }
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
        intent: Intent,
        savedPaymentMethods: [STPPaymentMethod],
        configuration: PaymentSheet.Configuration,
        isApplePayEnabled: Bool,
        isLinkEnabled: Bool,
        delegate: PaymentSheetViewControllerDelegate
    ) {
        self.intent = intent
        self.savedPaymentMethods = savedPaymentMethods
        self.configuration = configuration
        self.isApplePayEnabled = isApplePayEnabled
        self.isLinkEnabled = isLinkEnabled
        self.delegate = delegate

        if savedPaymentMethods.isEmpty {
            self.mode = .addingNew
        } else {
            self.mode = .selectingSaved
        }

        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = configuration.appearance.colors.background
    }

    deinit {
        LinkAccountContext.shared.removeObserver(self)
    }

    // MARK: UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()

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
        STPAnalyticsClient.sharedClient.logPaymentSheetShow(
            isCustom: false,
            paymentMethod: mode.analyticsValue,
            linkEnabled: intent.supportsLink,
            activeLinkSession: LinkAccountContext.shared.account?.sessionState == .verified,
            currency: intent.currency,
            intentConfig: intent.intentConfig
        )
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
                    if self.savedPaymentOptionsViewController.hasRemovablePaymentMethods {
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
                    return savedPaymentMethods.isEmpty ? .close(showAdditionalButton: false) : .back
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
        walletHeader.showsCardPaymentMessage = (addPaymentMethodViewController.paymentMethodTypes == [.card])

        switch mode {
        case .addingNew:
            headerLabel.isHidden = isWalletEnabled
            headerLabel.text = STPLocalizedString(
                "Add your payment information",
                "Title shown above a form where the customer can enter payment information like credit card details, email, billing address, etc."
            )
        case .selectingSaved:
            headerLabel.isHidden = shouldShowWalletHeader
            headerLabel.text = STPLocalizedString(
                "Select your payment method",
                "Title shown above a carousel containing the customer's payment methods"
            )
        }

        // Content
        switchContentIfNecessary(
            to: mode == .selectingSaved
                ? savedPaymentOptionsViewController : addPaymentMethodViewController,
            containerView: paymentContainerView
        )

        // Error
        switch mode {
        case .addingNew:
            if addPaymentMethodViewController.setErrorIfNecessary(for: error) == false {
                errorLabel.text = error?.nonGenericDescription
            }
        case .selectingSaved:
            errorLabel.text = error?.nonGenericDescription
        }
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
            buyButtonStatus = .enabled
            showBuyButton = savedPaymentOptionsViewController.selectedPaymentOption != nil
        case .addingNew:
            buyButtonStyle = .stripe
            if let overrideCallToAction = addPaymentMethodViewController.overrideCallToAction {
                callToAction = overrideCallToAction
                buyButtonStatus = addPaymentMethodViewController.overrideCallToActionShouldEnable ? .enabled : .disabled
            } else {
                buyButtonStatus =
                    addPaymentMethodViewController.paymentOption == nil ? .disabled : .enabled
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
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetConfirmButtonTapped)
        switch mode {
        case .addingNew:
            if let buyButtonOverrideBehavior = addPaymentMethodViewController.overrideBuyButtonBehavior {
                addPaymentMethodViewController.didTapCallToActionButton(behavior: buyButtonOverrideBehavior, from: self)
            } else {
                guard let newPaymentOption = addPaymentMethodViewController.paymentOption else {
                    assertionFailure()
                    return
                }
                pay(with: newPaymentOption)
            }
        case .selectingSaved:
            guard
                let selectedPaymentOption = savedPaymentOptionsViewController.selectedPaymentOption
            else {
                assertionFailure()
                return
            }
            pay(with: selectedPaymentOption)
        }
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
                STPAnalyticsClient.sharedClient.logPaymentSheetPayment(
                    isCustom: false,
                    paymentMethod: paymentOption.analyticsValue,
                    result: result,
                    linkEnabled: self.intent.supportsLink,
                    activeLinkSession: LinkAccountContext.shared.account?.sessionState == .verified,
                    linkSessionType: self.intent.linkPopupWebviewOption,
                    currency: self.intent.currency,
                    intentConfig: self.intent.intentConfig,
                    deferredIntentConfirmationType: deferredIntentConfirmationType,
                    paymentMethodTypeAnalyticsValue: paymentOption.paymentMethodTypeAnalyticsValue,
                    error: result.error
                )

                self.isPaymentInFlight = false
                switch result {
                case .canceled:
                    // Do nothing, keep customer on payment sheet
                    self.updateUI()
                case .failed(let error):
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    // Update state
                    self.error = error
                    // Handle error
                    if PaymentSheetError.isUnrecoverable(error: error) {
                        self.delegate?.paymentSheetViewControllerDidFinish(self, result: result)
                    }
                    self.updateUI()
                    UIAccessibility.post(notification: .layoutChanged, argument: self.errorLabel)
                case .completed:
                    // We're done!
                    let delay: TimeInterval =
                        self.presentedViewController?.isBeingDismissed == true ? 1 : 0
                    // Hack: PaymentHandler calls the completion block while SafariVC is still being dismissed - "wait" until it's finished before updating UI
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        STPAnalyticsClient.sharedClient.logPaymentSheetPaymentOptionSelect(
            isCustom: false,
            paymentMethod: paymentMethodSelection.analyticsValue,
            intentConfig: intent.intentConfig
        )
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
        guard case .saved(let paymentMethod) = paymentMethodSelection,
            let ephemeralKey = configuration.customer?.ephemeralKeySecret
        else {
            return
        }
        configuration.apiClient.detachPaymentMethod(
            paymentMethod.stripeId,
            fromCustomerUsing: ephemeralKey
        ) { (_) in
            // no-op
        }
        if !savedPaymentOptionsViewController.hasRemovablePaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            // calling updateUI() at this point causes an issue with the height of the add card vc
            // if you do a subsequent presentation. Since bottom sheet height stuff is complicated,
            // just update the nav bar which is all we need to do anyway
            configureNavBar()
        }
        updateBottomNotice()
    }

    // MARK: Helpers
    func configureEditSavedPaymentMethodsButton() {
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            navigationBar.additionalButton.setTitle(UIButton.doneButtonTitle, for: .normal)
            buyButton.update(state: .disabled)
        } else {
            buyButton.update(state: .enabled)
            navigationBar.additionalButton.setTitle(UIButton.editButtonTitle, for: .normal)
        }
        navigationBar.additionalButton.accessibilityIdentifier = "edit_saved_button"
        navigationBar.additionalButton.titleLabel?.adjustsFontForContentSizeCategory = true
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
}

// MARK: - AddPaymentMethodViewControllerDelegate
/// :nodoc:
extension PaymentSheetViewController: AddPaymentMethodViewControllerDelegate {
    func didUpdate(_ viewController: AddPaymentMethodViewController) {
        error = nil  // clear error
        updateUI()
    }

    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool {
        guard isLinkEnabled else {
            return false
        }

        return LinkAccountContext.shared.account.flatMap({ !$0.isRegistered }) ?? true
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
            assertionFailure()
        }
    }
}
