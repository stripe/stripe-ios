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

/// For internal SDK use only
class PaymentSheetFlowControllerViewController: UIViewController, FlowControllerViewControllerProtocol {
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

    /// The type of the Stripe payment method that's currently selected in the UI for new and saved PMs. Returns nil Apple Pay and .stripe(.link) for Link.
    /// Note that, unlike selectedPaymentOption, this is non-nil even if the PM form is invalid.
    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType? {
        switch mode {
        case .selectingSaved:
            return selectedPaymentOption?.paymentMethodType
        case .addingNew:
            return addPaymentMethodViewController.selectedPaymentMethodType
        }
    }
    weak var flowControllerDelegate: FlowControllerViewControllerDelegate?
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
    private let isApplePayEnabled: Bool
    private let isLinkEnabled: Bool
    private var isHackyLinkButtonSelected: Bool = false

    private lazy var savedPaymentMethodManager: SavedPaymentMethodManager = {
       return SavedPaymentMethodManager(configuration: configuration)
    }()

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
            callToAction: callToAction,
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapAddButton()
            }
        )
        return button
    }()

    private var callToAction: ConfirmButton.CallToActionType {
        if let customCtaLabel = configuration.primaryButtonLabel {
            switch mode {
            case .selectingSaved:
                return .customWithLock(title: customCtaLabel)
            case .addingNew:
                return .custom(title: customCtaLabel)
            }
        }

        switch mode {
        case .selectingSaved:
            return .customWithLock(title: String.Localized.continue)
        case .addingNew:
            return .continue
        }
    }

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
        configuration: PaymentSheet.Configuration,
        loadResult: PaymentSheetLoader.LoadResult,
        previousPaymentOption: PaymentOption? = nil
    ) {
        self.intent = loadResult.intent
        self.isApplePayEnabled = loadResult.isApplePayEnabled
        self.isLinkEnabled = loadResult.isLinkEnabled
        self.configuration = configuration

        // Restore the customer's previous payment method. For saved PMs, this happens naturally already, so we just need to handle new payment methods.
        // Caveats:
        // - Only payment method details (including checkbox state) and billing details are restored
        // - Only restored if the previous input resulted in a completed form i.e. partial or invalid input is still discarded
        let previousConfirmParams: IntentConfirmParams? = {
            switch previousPaymentOption {
            case .applePay, .saved, .link, nil:
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
        self.mode = (previousConfirmParams == nil) && (loadResult.savedPaymentMethods.count > 0 || isApplePayEnabled || isLinkEnabled)
                ? .selectingSaved
                : .addingNew

        self.savedPaymentOptionsViewController = SavedPaymentOptionsViewController(
            savedPaymentMethods: loadResult.savedPaymentMethods,
            configuration: .init(
                customerID: configuration.customer?.id,
                showApplePay: isApplePayEnabled,
                showLink: isLinkEnabled,
                removeSavedPaymentMethodMessage: configuration.removeSavedPaymentMethodMessage,
                merchantDisplayName: configuration.merchantDisplayName,
                isCVCRecollectionEnabled: false,
                isTestMode: configuration.apiClient.isTestmode,
                allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
                allowsRemovalOfPaymentMethods: self.intent.elementsSession.allowsRemovalOfPaymentMethodsForPaymentSheet()
            ),
            paymentSheetConfiguration: configuration,
            intent: intent,
            appearance: configuration.appearance,
            cbcEligible: intent.cardBrandChoiceEligible
        )
        self.addPaymentMethodViewController = AddPaymentMethodViewController(
            intent: intent,
            configuration: configuration,
            previousCustomerInput: previousConfirmParams, // Restore the customer's previous new payment method input
            isLinkEnabled: isLinkEnabled
        )
        super.init(nibName: nil, bundle: nil)
        self.savedPaymentOptionsViewController.delegate = self
        self.addPaymentMethodViewController.delegate = self
    }

    // MARK: - UIViewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        configuration.style.configure(self)

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
            linkEnabled: isLinkEnabled,
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
                        ? .back(showAdditionalButton: false) : .close(showAdditionalButton: false)
                }
            }())
    }

    // state -> view
    private func updateUI() {
        configureNavBar()

        // Content header
        walletHeader.isHidden = !shouldShowWalletHeader
        walletHeader.showsCardPaymentMessage = (addPaymentMethodViewController.paymentMethodTypes == [.stripe(.card)])
        headerLabel.isHidden = shouldShowWalletHeader

        switch mode {
        case .selectingSaved:
            headerLabel.text = .Localized.select_your_payment_method
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
        errorLabel.text = error?.localizedDescription
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
            if selectedPaymentMethodType?.requiresMandateDisplayForSavedSelection ?? false {
                if confirmButton.isHidden {
                    confirmButton.alpha = 0
                    confirmButton.setHiddenIfNecessary(false)
                    UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                        self.confirmButton.alpha = 1
                        self.view.layoutIfNeeded()
                    }
                }
                confirmButton.update(state: savedPaymentOptionsViewController.isRemovingPaymentMethods ? .disabled : .enabled, callToAction: callToAction, animated: true)
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
                if addPaymentMethodViewController.paymentOption == nil {
                    // We don't have valid payment method params yet
                    return .disabled
                } else {
                    return .enabled
                }
            }()

            var callToAction: ConfirmButton.CallToActionType = callToAction
            if let overridePrimaryButtonState = addPaymentMethodViewController.overridePrimaryButtonState {
                callToAction = overridePrimaryButtonState.ctaType
                confirmButtonState = overridePrimaryButtonState.enabled ? .enabled : .disabled
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
            if selectedPaymentMethodType?.requiresMandateDisplayForSavedSelection ?? false {
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
        let paymentMethodType = selectedPaymentMethodType ?? .stripe(.unknown)
        STPAnalyticsClient.sharedClient.logPaymentSheetConfirmButtonTapped(paymentMethodTypeIdentifier: paymentMethodType.identifier)
        switch mode {
        case .selectingSaved:
            self.flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: false)
        case .addingNew:
            if addPaymentMethodViewController.overridePrimaryButtonState != nil {
                addPaymentMethodViewController.didTapCallToActionButton(from: self)
            } else {
                self.flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: false)
            }
        }
    }

    func didDismiss(didCancel: Bool) {
        // When we close the window, unset the hacky Link button. This will reset the PaymentOption to nil, if needed.
        isHackyLinkButtonSelected = false
        // If the customer was adding a new payment method and it's incomplete/invalid, return to the saved PM screen
        flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: didCancel)
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

    func didFinishAnimatingHeight() {
        // no-op
    }
}

// MARK: - SavedPaymentOptionsViewControllerDelegate
/// :nodoc:
extension PaymentSheetFlowControllerViewController: SavedPaymentOptionsViewControllerDelegate {
    enum PaymentSheetFlowControllerViewControllerError: Error {
        case didUpdateSelectionWithInvalidMode
        case sheetNavigationBarDidBack
    }

    func didUpdate(_ viewController: SavedPaymentOptionsViewController) {
        // no-op
    }
    func didSelectUpdate(viewController: SavedPaymentOptionsViewController,
                         paymentMethodSelection: SavedPaymentOptionsViewController.Selection,
                         updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        guard case .saved(let paymentMethod) = paymentMethodSelection,
              let ephemeralKey = configuration.customer?.ephemeralKeySecretBasedOn(intent: intent)
        else {
            throw PaymentSheetError.unknown(debugDescription: "Failed to read ephemeral key secret")
        }

        return try await savedPaymentMethodManager.update(paymentMethod: paymentMethod,
                                                          with: updateParams,
                                                          using: ephemeralKey)
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
            let errorAnalytic = ErrorAnalytic(event: .unexpectedFlowControllerViewControllerError,
                                              error: PaymentSheetFlowControllerViewControllerError.didUpdateSelectionWithInvalidMode,
                                              additionalNonPIIParams: [:])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return
        }
        switch paymentMethodSelection {
        case .add:
            mode = .addingNew
            error = nil // Clear any errors
            updateUI()
        case .applePay, .link, .saved:
            updateUI()
            if isDismissable, !(selectedPaymentMethodType?.requiresMandateDisplayForSavedSelection ?? false) {
                flowControllerDelegate?.flowControllerViewControllerShouldClose(self, didCancel: false)
            }
        }
    }

    func didSelectRemove(
        viewController: SavedPaymentOptionsViewController,
        paymentMethodSelection: SavedPaymentOptionsViewController.Selection
    ) {
        guard case .saved(let paymentMethod) = paymentMethodSelection,
              let ephemeralKey = configuration.customer?.ephemeralKeySecretBasedOn(intent: intent)
        else {
            return
        }

        savedPaymentMethodManager.detach(paymentMethod: paymentMethod, using: ephemeralKey)

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
        navigationBar.additionalButton.configureCommonEditButton(isEditingPaymentMethods: savedPaymentOptionsViewController.isRemovingPaymentMethods)
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
            let errorAnalytic = ErrorAnalytic(event: .unexpectedFlowControllerViewControllerError,
                                              error: PaymentSheetFlowControllerViewControllerError.sheetNavigationBarDidBack,
                                              additionalNonPIIParams: [:])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
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
