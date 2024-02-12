//
//  PaymentSheetFlowControllerViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 11/4/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol PaymentSheetFlowControllerViewControllerDelegate: AnyObject {
    func paymentSheetFlowControllerViewControllerShouldClose(
        _ PaymentSheetFlowControllerViewController: PaymentSheetFlowControllerViewController, didCancel: Bool)
    func paymentSheetFlowControllerViewControllerDidUpdateSelection(
        _ PaymentSheetFlowControllerViewController: PaymentSheetFlowControllerViewController)
}

/// For internal SDK use only
@objc(STP_Internal_PaymentSheetFlowControllerViewController)
class PaymentSheetFlowControllerViewController: UIViewController {
    // MARK: - Internal Properties
    let intent: Intent
    let configuration: PaymentSheet.Configuration
    var savedPaymentMethods: [STPPaymentMethod] {
        return savedPaymentOptionsViewController.savedPaymentMethods
    }
    var selectedPaymentOption: PaymentOption? {
        switch mode {
        case .addingNew:
            if let paymentOption = addPaymentMethodViewController.paymentOption {
                return paymentOption
            } else if let paymentOption = savedPaymentOptionsViewController.selectedPaymentOption {
                // If no valid payment option from adding, fallback on any saved payment method
                return paymentOption
            } else if isHackyLinkButtonSelected {
                return .link(option: .wallet)
            } else if isApplePayEnabled {
                return .applePay
            }
            return nil
        case .selectingSaved:
            return savedPaymentOptionsViewController.selectedPaymentOption
        }
    }

    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType {
        switch mode {
        case .selectingSaved:
            guard let selectedPaymentOption = selectedPaymentOption else {
                return .stripe(.unknown)
            }
            if case let .saved(paymentMethod, _) = selectedPaymentOption {
                return .stripe(paymentMethod.type)
            } else if case .applePay = selectedPaymentOption {
                return .stripe(.card)
            } else {
                return .stripe(.unknown)
            }
        case .addingNew:
            return addPaymentMethodViewController.selectedPaymentMethodType
        }
    }
    weak var delegate: PaymentSheetFlowControllerViewControllerDelegate?
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()
    /// Returns true if Apple Pay is not enabled and Link is enabled and there are no saved payment methods
    private var linkOnlyMode: Bool {
        return !isApplePayEnabled && isLinkEnabled && !savedPaymentOptionsViewController.hasOptionsExcludingAdd
    }
    // Only show the wallet header when Link is the only available PM
    private var shouldShowWalletHeader: Bool {
        switch mode {
        case .addingNew:
            return linkOnlyMode
        case .selectingSaved:
            return false
        }
    }
    private(set) var error: Error?
    private(set) var isDismissable: Bool = true

    // MARK: - Private Properties
    enum Mode {
        case selectingSaved
        case addingNew
    }
    private var mode: Mode
    private var isSavingInProgress: Bool = false
    private var isVerificationInProgress: Bool = false
    private let isApplePayEnabled: Bool
    private let isLinkEnabled: Bool
    private var isHackyLinkButtonSelected: Bool = false

    // MARK: - Views
    private let addPaymentMethodViewController: AddPaymentMethodViewController
    private let savedPaymentOptionsViewController: SavedPaymentOptionsViewController
    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
    }()
    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()
    private lazy var errorLabel: UILabel = {
        return ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
    }()
    private lazy var confirmButton: ConfirmButton = {
        let button = ConfirmButton(
            callToAction: .add(paymentMethodType: selectedPaymentMethodType),
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapAddButton()
            }
        )
        return button
    }()

    private lazy var bottomNoticeTextField: UITextView = {
        return ElementsUI.makeNoticeTextField(theme: configuration.appearance.asElementsTheme)
    }()

    private typealias WalletHeaderView = PaymentSheetViewController.WalletHeaderView
    private lazy var walletHeader: WalletHeaderView = {
        var walletOptions: WalletHeaderView.WalletOptions = []

        if linkOnlyMode {
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

    // MARK: - Init

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        intent: Intent,
        savedPaymentMethods: [STPPaymentMethod],
        configuration: PaymentSheet.Configuration,
        previousPaymentOption: PaymentOption? = nil,
        isApplePayEnabled: Bool,
        isLinkEnabled: Bool,
        isCVCRecollectionEnabled: Bool
    ) {
        self.intent = intent
        self.isApplePayEnabled = isApplePayEnabled
        self.isLinkEnabled = isLinkEnabled

        self.configuration = configuration

        // Restore the customer's previous payment method. For saved PMs, this happens naturally already, so we just need to handle new payment methods.
        // Caveats:
        // - Only card details (including checkbox state) and billing details are restored
        // - Only restored if the previous input resulted in a completed form i.e. partial or invalid input is still discarded
        // TODO(Link): Consider how we want to restore the customer's previous inputs, if at all.
        let previousNewPaymentMethodParams: IntentConfirmParams? = {
            guard let previousPaymentOption = previousPaymentOption else {
                return nil
            }
            switch previousPaymentOption {
            case .applePay, .saved, .link:
                // TODO(Link): Handle link when we re-enable it
                return nil
            case .new(confirmParams: let params):
                return params
            case let .external(paymentMethod, billingDetails):
                let params = IntentConfirmParams(type: .external(paymentMethod))
                params.paymentMethodParams.billingDetails = billingDetails
                return params
            }
        }()
        // Default to saved payment selection mode, as long as we aren't restoring a customer's previous new payment method input
        // and they have saved PMs or Apple Pay or Link is enabled
        self.mode = (previousNewPaymentMethodParams == nil) && (savedPaymentMethods.count > 0 || isApplePayEnabled || isLinkEnabled)
                ? .selectingSaved
                : .addingNew

        self.savedPaymentOptionsViewController = SavedPaymentOptionsViewController(
            savedPaymentMethods: savedPaymentMethods,
            configuration: .init(
                customerID: configuration.customer?.id,
                showApplePay: isApplePayEnabled,
                showLink: isLinkEnabled,
                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                merchantDisplayName: configuration.merchantDisplayName,
                isCVCRecollectionEnabled: isCVCRecollectionEnabled,
                isTestMode: configuration.apiClient.isTestmode,
                allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod
            ),
            paymentSheetConfiguration: configuration,
            intent: intent,
            appearance: configuration.appearance,
            cbcEligible: intent.cardBrandChoiceEligible
        )
        self.addPaymentMethodViewController = AddPaymentMethodViewController(
            intent: intent,
            configuration: configuration,
            previousCustomerInput: previousNewPaymentMethodParams // Restore the customer's previous new payment method input
        )
        super.init(nibName: nil, bundle: nil)
        self.savedPaymentOptionsViewController.delegate = self
        self.addPaymentMethodViewController.delegate = self
    }

    // MARK: - UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background

        // One stack view contains all our subviews
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
            walletHeader,
            paymentContainerView,
            errorLabel,
            confirmButton,
            bottomNoticeTextField,
        ])
        stackView.bringSubviewToFront(headerLabel)
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        [stackView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        // Get our margins in order
        view.directionalLayoutMargins = PaymentSheetUI.defaultSheetMargins
        // Hack: Payment container needs to extend to the edges, so we'll 'cancel out' the layout margins with negative padding
        paymentContainerView.directionalLayoutMargins = .insets(
            leading: -PaymentSheetUI.defaultSheetMargins.leading,
            trailing: -PaymentSheetUI.defaultSheetMargins.trailing
        )

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])

        // Automatically switch into the adding new mode when Link is the only available payment method
        if linkOnlyMode {
            mode = .addingNew
        }

        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        STPAnalyticsClient.sharedClient.logPaymentSheetShow(
            isCustom: true,
            paymentMethod: mode.analyticsValue,
            linkEnabled: intent.supportsLink(allowV2Features: configuration.allowLinkV2Features),
            activeLinkSession: LinkAccountContext.shared.account?.sessionState == .verified,
            currency: intent.currency,
            intentConfig: intent.intentConfig,
            apiClient: configuration.apiClient
        )
    }

    // MARK: - Private Methods

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
                            self, action: #selector(didSelectEditSavedPaymentMethodsButton),
                            for: .touchUpInside)
                        return .close(showAdditionalButton: false)
                    }
                case .addingNew:
                    self.navigationBar.additionalButton.removeTarget(
                        self, action: #selector(didSelectEditSavedPaymentMethodsButton),
                        for: .touchUpInside)
                    return savedPaymentOptionsViewController.hasPaymentOptions
                        ? .back : .close(showAdditionalButton: false)
                }
            }())
    }

    // state -> view
    private func updateUI() {
        // Disable interaction if necessary
        let shouldEnableUserInteraction = !isSavingInProgress && !isVerificationInProgress
        if shouldEnableUserInteraction != view.isUserInteractionEnabled {
            sendEventToSubviews(
                shouldEnableUserInteraction ?
                    .shouldEnableUserInteraction : .shouldDisableUserInteraction,
                from: view
            )
        }
        view.isUserInteractionEnabled = shouldEnableUserInteraction
        isDismissable = !isSavingInProgress && !isVerificationInProgress

        configureNavBar()

        // Content header
        walletHeader.isHidden = !shouldShowWalletHeader
        walletHeader.showsCardPaymentMessage = (addPaymentMethodViewController.paymentMethodTypes == [.stripe(.card)])
        headerLabel.isHidden = shouldShowWalletHeader

        switch mode {
        case .selectingSaved:
            headerLabel.text = STPLocalizedString(
                "Select your payment method",
                "Title shown above a carousel containing the customer's payment methods")
        case .addingNew:
            if addPaymentMethodViewController.paymentMethodTypes == [.stripe(.card)] {
                headerLabel.text = STPLocalizedString("Add a card", "Title shown above a card entry form")
            } else {
                headerLabel.text = STPLocalizedString("Choose a payment method", "TODO")
            }
        }

        // Content
        let targetViewController: UIViewController = {
            switch mode {
            case .selectingSaved:
                return savedPaymentOptionsViewController
            case .addingNew:
                return addPaymentMethodViewController
            }
        }()
        switchContentIfNecessary(
            to: targetViewController,
            containerView: paymentContainerView
        )

        // Error
        switch mode {
        case .addingNew:
            if addPaymentMethodViewController.setErrorIfNecessary(for: error) == false {
                errorLabel.text = error?.localizedDescription
            }
        case .selectingSaved:
            errorLabel.text = error?.localizedDescription
        }
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.errorLabel.setHiddenIfNecessary(self.error == nil)
        }

        // Buy button
        updateButton()

        // Notice
        updateBottomNotice()
    }

    func updateButton() {
        switch mode {
        case .selectingSaved:
            if selectedPaymentMethodType.requiresMandateDisplayForSavedSelection {
                if confirmButton.isHidden {
                    confirmButton.alpha = 0
                    confirmButton.setHiddenIfNecessary(false)
                    UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                        self.confirmButton.alpha = 1
                        self.view.layoutIfNeeded()
                    }
                }
                confirmButton.update(state: savedPaymentOptionsViewController.isRemovingPaymentMethods ? .disabled : .enabled,
                                     callToAction: .customWithLock(title: String.Localized.continue), animated: true)
            } else {
                if !confirmButton.isHidden {
                    UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                        // We're selecting a saved PM without a mandate, there's no 'Add' button
                        self.confirmButton.alpha = 0
                        self.confirmButton.setHiddenIfNecessary(true)
                        self.view.layoutIfNeeded()
                    }
                }
            }

        case .addingNew:
            // Configure add button
            if confirmButton.isHidden {
                confirmButton.alpha = 0
                confirmButton.setHiddenIfNecessary(false)
                UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                    self.confirmButton.alpha = 1
                    self.view.layoutIfNeeded()
                }
            }
            var confirmButtonState: ConfirmButton.Status = {
                if isSavingInProgress || isVerificationInProgress {
                    // We're in the middle of adding the PM
                    return .processing
                } else if addPaymentMethodViewController.paymentOption == nil {
                    // We don't have valid payment method params yet
                    return .disabled
                } else {
                    return .enabled
                }
            }()

            var callToAction: ConfirmButton.CallToActionType = .add(paymentMethodType: selectedPaymentMethodType)
            if let overrideCallToAction = addPaymentMethodViewController.overrideCallToAction {
                callToAction = overrideCallToAction
                confirmButtonState = addPaymentMethodViewController.overrideCallToActionShouldEnable ? .enabled : .disabled
            }

            confirmButton.update(
                state: confirmButtonState,
                callToAction: callToAction,
                animated: true
            )
        }
    }

    func updateBottomNotice() {
        switch mode {
        case .selectingSaved:
            if selectedPaymentMethodType.requiresMandateDisplayForSavedSelection {
                self.bottomNoticeTextField.attributedText = savedPaymentOptionsViewController.bottomNoticeAttributedString // TODO remove probably?
            } else {
                self.bottomNoticeTextField.attributedText = nil
            }
        case .addingNew:
            self.bottomNoticeTextField.attributedText = addPaymentMethodViewController.bottomNoticeAttributedString
        }
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.bottomNoticeTextField.setHiddenIfNecessary(self.bottomNoticeTextField.attributedText?.length == 0)
        }
    }

    @objc
    private func didTapAddButton() {
        STPAnalyticsClient.sharedClient.logPaymentSheetConfirmButtonTapped(paymentMethodTypeIdentifier: selectedPaymentMethodType.identifier)
        switch mode {
        case .selectingSaved:
            self.delegate?.paymentSheetFlowControllerViewControllerShouldClose(self, didCancel: false)
        case .addingNew:
            if let buyButtonOverrideBehavior = addPaymentMethodViewController.overrideBuyButtonBehavior {
                addPaymentMethodViewController.didTapCallToActionButton(behavior: buyButtonOverrideBehavior, from: self)
            } else {
                self.delegate?.paymentSheetFlowControllerViewControllerShouldClose(self, didCancel: false)
            }
        }

    }

    func didDismiss(didCancel: Bool) {
        // When we close the window, unset the hacky Link button. This will reset the PaymentOption to nil, if needed.
        isHackyLinkButtonSelected = false
        // If the customer was adding a new payment method and it's incomplete/invalid, return to the saved PM screen
        delegate?.paymentSheetFlowControllerViewControllerShouldClose(self, didCancel: didCancel)
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            configureEditSavedPaymentMethodsButton()
            updateUI()
        }
    }
}

// MARK: - BottomSheetContentViewController
/// :nodoc:
extension PaymentSheetFlowControllerViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        if isDismissable {
            didDismiss(didCancel: true)
        }
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: - SavedPaymentOptionsViewControllerDelegate
/// :nodoc:
extension PaymentSheetFlowControllerViewController: SavedPaymentOptionsViewControllerDelegate {
    func didUpdate(_ viewController: SavedPaymentOptionsViewController) {
        // no-op
        assertionFailure("Used to bubble up CVC Input. This should never happen for FlowController")

    }
    func didSelectUpdate(viewController: SavedPaymentOptionsViewController,
                         paymentMethodSelection: SavedPaymentOptionsViewController.Selection,
                         updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        guard case .saved(let paymentMethod) = paymentMethodSelection,
            let ephemeralKey = configuration.customer?.ephemeralKeySecret
        else {
            throw PaymentSheetError.unknown(debugDescription: "Failed to read ephemeral key secret")
        }

        return try await configuration.apiClient.updatePaymentMethod(with: paymentMethod.stripeId,
                                                                     paymentMethodUpdateParams: updateParams,
                                                                     ephemeralKeySecret: ephemeralKey)
    }

    func didUpdateSelection(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        STPAnalyticsClient.sharedClient.logPaymentSheetPaymentOptionSelect(isCustom: true,
                                                                           paymentMethod: paymentMethodSelection.analyticsValue,
                                                                           intentConfig: intent.intentConfig,
                                                                           apiClient: configuration.apiClient)
        guard case Mode.selectingSaved = mode else {
            assertionFailure()
            return
        }
        switch paymentMethodSelection {
        case .add:
            mode = .addingNew
            error = nil // Clear any errors
            updateUI()
        case .applePay, .link, .saved:
            delegate?.paymentSheetFlowControllerViewControllerDidUpdateSelection(self)
            updateUI()
            if isDismissable, !selectedPaymentMethodType.requiresMandateDisplayForSavedSelection {
                delegate?.paymentSheetFlowControllerViewControllerShouldClose(self, didCancel: false)
            }
        }
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
            paymentMethod.stripeId, fromCustomerUsing: ephemeralKey
        ) { (_) in
            // no-op
        }

        if !savedPaymentOptionsViewController.canEditPaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            // calling updateUI() at this point causes an issue with the height of the add card vc
            // if you do a subsequent presentation. Since bottom sheet height stuff is complicated,
            // just update the nav bar which is all we need to do anyway
            configureNavBar()
        }
        updateButton()
        updateBottomNotice()
    }

    // MARK: Helpers
    func configureEditSavedPaymentMethodsButton() {
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            navigationBar.additionalButton.setTitle(UIButton.doneButtonTitle, for: .normal)
        } else {
            navigationBar.additionalButton.setTitle(UIButton.editButtonTitle, for: .normal)
        }
        navigationBar.additionalButton.accessibilityIdentifier = "edit_saved_button"
        navigationBar.additionalButton.titleLabel?.font = configuration.appearance.font.base.medium
        navigationBar.additionalButton.titleLabel?.adjustsFontForContentSizeCategory = true
        navigationBar.additionalButton.addTarget(
            self, action: #selector(didSelectEditSavedPaymentMethodsButton), for: .touchUpInside)
    }

    @objc
    func didSelectEditSavedPaymentMethodsButton() {
        savedPaymentOptionsViewController.isRemovingPaymentMethods.toggle()
        configureEditSavedPaymentMethodsButton()
        updateUI()
    }
}

// MARK: - AddPaymentMethodViewControllerDelegate
/// :nodoc:
extension PaymentSheetFlowControllerViewController: AddPaymentMethodViewControllerDelegate {
    func didUpdate(_ viewController: AddPaymentMethodViewController) {
        error = nil  // clear error
        updateUI()
    }

    func shouldOfferLinkSignup(_ viewController: AddPaymentMethodViewController) -> Bool {
        guard isLinkEnabled && !intent.disableLinkSignup else {
            return false
        }

        let isAccountNotRegisteredOrMissing = LinkAccountContext.shared.account.flatMap({ !$0.isRegistered }) ?? true
        return isAccountNotRegisteredOrMissing && !UserDefaults.standard.customerHasUsedLink
    }

    func updateErrorLabel(for error: Error?) {
        // no-op: No current use case for this
    }
}
// MARK: - SheetNavigationBarDelegate
/// :nodoc:
extension PaymentSheetFlowControllerViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        didDismiss(didCancel: true)
    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        // This is quite hardcoded. Could make some generic "previous mode" or "previous VC" that we always go back to
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

// MARK: - PaymentSheetPaymentMethodType Helpers
extension PaymentSheet.PaymentMethodType {
    var requiresMandateDisplayForSavedSelection: Bool {
        return self == .stripe(.USBankAccount) || self == .stripe(.SEPADebit)
    }
}

extension PaymentSheetFlowControllerViewController: WalletHeaderViewDelegate {
    func walletHeaderViewApplePayButtonTapped(_ header: PaymentSheetViewController.WalletHeaderView) {
        // no-op
    }

    func walletHeaderViewPayWithLinkTapped(_ header: PaymentSheetViewController.WalletHeaderView) {
        // Link should be the selected payment option, as the Link header button is only available in `linkOnlyMode`
        mode = .addingNew
        didDismiss(didCancel: false)
        isHackyLinkButtonSelected = true
        updateUI()
    }
}
