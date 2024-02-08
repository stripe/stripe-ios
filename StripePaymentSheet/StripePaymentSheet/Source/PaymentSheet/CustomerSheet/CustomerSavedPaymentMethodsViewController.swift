//
//  CustomerSavedPaymentMethodsViewController.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

protocol CustomerSavedPaymentMethodsViewControllerDelegate: AnyObject {
    func savedPaymentMethodsViewControllerShouldConfirm(_ intent: Intent?,
                                                        with paymentOption: PaymentOption,
                                                        completion: @escaping(InternalCustomerSheetResult) -> Void)
    func savedPaymentMethodsViewControllerDidCancel(_ savedPaymentMethodsViewController: CustomerSavedPaymentMethodsViewController, completion: @escaping () -> Void)
    func savedPaymentMethodsViewControllerDidFinish(_ savedPaymentMethodsViewController: CustomerSavedPaymentMethodsViewController, completion: @escaping () -> Void)
}

@objc(STP_Internal_CustomerSavedPaymentMethodsViewController)
class CustomerSavedPaymentMethodsViewController: UIViewController {

    // MARK: - Read-only Properties
    let savedPaymentMethods: [STPPaymentMethod]
    let selectedPaymentMethodOption: CustomerPaymentOption?
    let isApplePayEnabled: Bool
    let configuration: CustomerSheet.Configuration
    let customerAdapter: CustomerAdapter
    let cbcEligible: Bool

    // MARK: - Writable Properties
    weak var delegate: CustomerSavedPaymentMethodsViewControllerDelegate?
    var csCompletion: CustomerSheet.CustomerSheetCompletion?
    private(set) var isDismissable: Bool = true
    enum Mode {
        case selectingSaved
        case addingNewWithSetupIntent
        case addingNewPaymentMethodAttachToCustomer
    }

    private var mode: Mode
    private(set) var error: Error?
    private var processingInFlight: Bool = false
    private(set) var intent: Intent?
    private lazy var addPaymentMethodViewController: CustomerAddPaymentMethodViewController = {
        return CustomerAddPaymentMethodViewController(
            configuration: configuration,
            paymentMethodTypes: paymentMethodTypes,
            cbcEligible: cbcEligible,
            delegate: self)
    }()
    private var cachedClientSecret: String?

    var paymentMethodTypes: [PaymentSheet.PaymentMethodType] {
        let paymentMethodTypes = merchantSupportedPaymentMethodTypes.customerSheetSupportedPaymentMethodTypesForAdd(customerAdapter: customerAdapter)
        return paymentMethodTypes.toPaymentSheetPaymentMethodTypes()
    }

    var selectedPaymentOption: PaymentOption? {
        switch mode {
        case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
            if let paymentOption = addPaymentMethodViewController.paymentOption {
                return paymentOption
            }
            return nil
        case .selectingSaved:
            return savedPaymentOptionsViewController.selectedPaymentOption
        }
    }
    let merchantSupportedPaymentMethodTypes: [STPPaymentMethodType]

    // MARK: - Views
    internal lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(isTestMode: configuration.apiClient.isTestmode,
                                        appearance: configuration.appearance)
        navBar.delegate = self
        return navBar
    }()

    private lazy var savedPaymentOptionsViewController: CustomerSavedPaymentMethodsCollectionViewController = {
        let showApplePay = isApplePayEnabled
        return CustomerSavedPaymentMethodsCollectionViewController(
            savedPaymentMethods: savedPaymentMethods,
            selectedPaymentMethodOption: selectedPaymentMethodOption,
            savedPaymentMethodsConfiguration: self.configuration,
            customerAdapter: self.customerAdapter,
            configuration: .init(
                showApplePay: showApplePay,
                allowsRemovalOfLastSavedPaymentMethod: configuration.allowsRemovalOfLastSavedPaymentMethod,
                isTestMode: configuration.apiClient.isTestmode
            ),
            appearance: configuration.appearance,
            cbcEligible: cbcEligible,
            delegate: self
        )
    }()
    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()
    private lazy var actionButton: ConfirmButton = {
        let button = ConfirmButton(
            callToAction: self.defaultCallToAction(),
            applePayButtonType: .plain,
            appearance: configuration.appearance,
            didTap: { [weak self] in
                self?.didTapActionButton()
            }
        )
        return button
    }()
    private lazy var headerLabel: UILabel = {
        return PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
    }()
    private lazy var errorLabel: UILabel = {
        return ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
    }()
    private lazy var bottomNoticeTextField: UITextView = {
        return ElementsUI.makeNoticeTextField(theme: configuration.appearance.asElementsTheme)
    }()
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        savedPaymentMethods: [STPPaymentMethod],
        selectedPaymentMethodOption: CustomerPaymentOption?,
        merchantSupportedPaymentMethodTypes: [STPPaymentMethodType],
        configuration: CustomerSheet.Configuration,
        customerAdapter: CustomerAdapter,
        isApplePayEnabled: Bool,
        cbcEligible: Bool,
        csCompletion: CustomerSheet.CustomerSheetCompletion?,
        delegate: CustomerSavedPaymentMethodsViewControllerDelegate
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.selectedPaymentMethodOption = selectedPaymentMethodOption
        self.merchantSupportedPaymentMethodTypes = merchantSupportedPaymentMethodTypes
        self.configuration = configuration
        self.customerAdapter = customerAdapter
        self.isApplePayEnabled = isApplePayEnabled
        self.cbcEligible = cbcEligible
        self.csCompletion = csCompletion
        self.delegate = delegate
        if Self.shouldShowPaymentMethodCarousel(savedPaymentMethods: savedPaymentMethods, isApplePayEnabled: isApplePayEnabled) {
            self.mode = .selectingSaved
        } else {
            if customerAdapter.canCreateSetupIntents {
                self.mode = .addingNewWithSetupIntent
            } else {
                self.mode = .addingNewPaymentMethodAttachToCustomer
            }
        }
        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = configuration.appearance.colors.background
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
            paymentContainerView,
            errorLabel,
            actionButton,
            bottomNoticeTextField,
        ])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical
        stackView.bringSubviewToFront(headerLabel)
        stackView.setCustomSpacing(32, after: paymentContainerView)
        stackView.setCustomSpacing(0, after: actionButton)

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
                equalTo: view.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])

        updateUI(animated: false)
    }

    static func shouldShowPaymentMethodCarousel(savedPaymentMethods: [STPPaymentMethod], isApplePayEnabled: Bool) -> Bool {
        return !savedPaymentMethods.isEmpty || isApplePayEnabled
    }

    private var shouldShowPaymentMethodCarousel: Bool {
        return CustomerSavedPaymentMethodsViewController.shouldShowPaymentMethodCarousel(savedPaymentMethods: self.savedPaymentMethods, isApplePayEnabled: isApplePayEnabled)
    }

    // MARK: Private Methods
    private func updateUI(animated: Bool = true) {
        let shouldEnableUserInteraction = !processingInFlight
        if shouldEnableUserInteraction != view.isUserInteractionEnabled {
            sendEventToSubviews(shouldEnableUserInteraction
                                ? .shouldEnableUserInteraction
                                : .shouldDisableUserInteraction,
                                from: view)
        }
        view.isUserInteractionEnabled = shouldEnableUserInteraction
        isDismissable = !processingInFlight
        navigationBar.isUserInteractionEnabled = !processingInFlight

        // Update our views (starting from the top of the screen):
        configureNavBar()

        switch mode {
        case .selectingSaved:
            if let text = configuration.headerTextForSelectionScreen, !text.isEmpty {
                headerLabel.text = text
            } else {
                headerLabel.text = STPLocalizedString(
                    "Manage your payment methods",
                    "Title shown above a carousel containing the customer's payment methods")
            }

        case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
            actionButton.isHidden = false
            headerLabel.text = STPLocalizedString(
                "Save a new payment method",
                "Title shown above a form where the customer can enter payment information like credit card details, email, billing address, etc."
            )
        }

        guard let contentViewController = contentViewControllerFor(mode: mode) else {
            // TODO: if we return nil here, it means we didn't create a
            // view controller, and if this happens, it is most likely because didn't
            // properly create setupIntent -- how do we want to handlet his situation?
            return
        }

        switchContentIfNecessary(to: contentViewController, containerView: paymentContainerView)

        // Error
        errorLabel.text = error?.nonGenericDescription

        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.errorLabel.setHiddenIfNecessary(self.error == nil)
        }

        // Buy button
        var actionButtonStatus: ConfirmButton.Status = .enabled
        var showActionButton: Bool = true

        var callToAction = defaultCallToAction()

        switch mode {
        case .selectingSaved:
            if savedPaymentOptionsViewController.selectedPaymentOption != nil {
                showActionButton = savedPaymentOptionsViewController.didSelectDifferentPaymentMethod()
            } else {
                showActionButton = false
            }
        case .addingNewPaymentMethodAttachToCustomer, .addingNewWithSetupIntent:
            self.actionButton.setHiddenIfNecessary(false)
            if let overrideCallToAction = addPaymentMethodViewController.overrideCallToAction {
                callToAction = overrideCallToAction
                actionButtonStatus = addPaymentMethodViewController.overrideCallToActionShouldEnable ? .enabled : .disabled
            } else {
                actionButtonStatus = addPaymentMethodViewController.paymentOption == nil ? .disabled : .enabled
            }
        }

        if processingInFlight {
            actionButtonStatus = .spinnerWithInteractionDisabled
        }

        self.actionButton.update(
            state: actionButtonStatus,
            style: .stripe,
            callToAction: callToAction,
            animated: animated,
            completion: nil
        )

        let updateButtonVisibility = {
            self.actionButton.setHiddenIfNecessary(!showActionButton)
        }
        if animated {
            animateHeightChange(updateButtonVisibility)
        } else {
            updateButtonVisibility()
        }

        // Notice
        updateBottomNotice()
    }
    private func contentViewControllerFor(mode: Mode) -> UIViewController? {
        if mode == .addingNewWithSetupIntent || mode == .addingNewPaymentMethodAttachToCustomer {
            return addPaymentMethodViewController
        }
        return savedPaymentOptionsViewController
    }

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
                case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
                    self.navigationBar.additionalButton.removeTarget(
                        self, action: #selector(didSelectEditSavedPaymentMethodsButton),
                        for: .touchUpInside)
                    return shouldShowPaymentMethodCarousel ? .back : .close(showAdditionalButton: false)
                }
            }())

    }

    private func defaultCallToAction() -> ConfirmButton.CallToActionType {
        switch mode {
        case .selectingSaved:
            return .custom(title: STPLocalizedString(
                "Confirm",
                "A button used to confirm selecting a saved payment method"
            ))
        case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
            return .customWithLock(title: STPLocalizedString(
                "Save",
                "A button used for saving a new payment method"
            ))
        }
    }

    func updateBottomNotice() {
        var shouldHideNotice = false
        switch mode {
        case .selectingSaved:
            self.bottomNoticeTextField.attributedText = savedPaymentOptionsViewController.bottomNoticeAttributedString
            shouldHideNotice = self.actionButton.isHidden || self.bottomNoticeTextField.attributedText?.length == 0

        case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
            self.bottomNoticeTextField.attributedText = addPaymentMethodViewController.bottomNoticeAttributedString
            shouldHideNotice = self.bottomNoticeTextField.attributedText?.length == 0
        }
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.bottomNoticeTextField.setHiddenIfNecessary(shouldHideNotice)
        }
    }

    private func didTapActionButton() {
        error = nil
        updateUI()

        switch mode {
        case .addingNewWithSetupIntent:
            if let behavior = addPaymentMethodViewController.overrideActionButtonBehavior {
                handleOverrideAction(behavior: behavior)
            } else {
                guard let newPaymentOption = addPaymentMethodViewController.paymentOption else {
                    return
                }
                addPaymentOption(paymentOption: newPaymentOption)
            }
        case .addingNewPaymentMethodAttachToCustomer:
            guard let newPaymentOption = addPaymentMethodViewController.paymentOption else {
                return
            }
            addPaymentOptionToCustomer(paymentOption: newPaymentOption)
        case .selectingSaved:
            if let selectedPaymentOption = savedPaymentOptionsViewController.selectedPaymentOption {
                switch selectedPaymentOption {
                case .applePay:
                    let paymentOptionSelection = CustomerSheet.PaymentOptionSelection.applePay()
                    setSelectablePaymentMethodAnimateButton(paymentOptionSelection: paymentOptionSelection) { error in
                        STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(type: "apple_pay")
                        self.error = error
                        self.updateUI(animated: true)
                    } onSuccess: {
                        STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(type: "apple_pay")
                        self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                            self.csCompletion?(.selected(paymentOptionSelection))
                        }
                    }

                case .saved(let paymentMethod, _):
                    let paymentOptionSelection = CustomerSheet.PaymentOptionSelection.paymentMethod(paymentMethod)
                    let type = STPPaymentMethod.string(from: paymentMethod.type)
                    setSelectablePaymentMethodAnimateButton(paymentOptionSelection: paymentOptionSelection) { error in
                        STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenConfirmedSavedPMFailure(type: type)
                        self.error = error
                        self.updateUI(animated: true)
                    } onSuccess: {
                        STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenConfirmedSavedPMSuccess(type: type)
                        self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                            self.csCompletion?(.selected(paymentOptionSelection))
                        }
                    }
                default:
                    assertionFailure("Selected payment method was something other than a saved payment method or apple pay")
                }

            }
        }
    }

    private func handleOverrideAction(behavior: OverrideableBuyButtonBehavior) {
        self.processingInFlight = true
        updateUI(animated: false)
        Task {
            guard let clientSecret = await fetchClientSecret() else {
                self.processingInFlight = false
                self.updateUI()
                return
            }
            self.processingInFlight = false
            self.updateUI()
            addPaymentMethodViewController.didTapCallToActionButton(behavior: behavior, clientSecret: clientSecret, from: self)
        }
    }

    private func addPaymentOption(paymentOption: PaymentOption) {
        guard case .new = paymentOption, customerAdapter.canCreateSetupIntents else {
            STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
            return
        }
        self.processingInFlight = true
        updateUI(animated: false)

        Task {
            guard let clientSecret = await fetchClientSecret() else {
                self.processingInFlight = false
                self.updateUI()
                return
            }
            guard let (fetchedSetupIntent, fetchedElementsSession) = await fetchSetupIntent(clientSecret: clientSecret) else {
                self.processingInFlight = false
                self.updateUI()
                return
            }
            let setupIntent = Intent.setupIntent(elementsSession: fetchedElementsSession, setupIntent: fetchedSetupIntent)

            guard let setupIntent = await self.confirm(intent: setupIntent, paymentOption: paymentOption),
                  let paymentMethod = setupIntent.paymentMethod else {
                self.processingInFlight = false
                self.updateUI()
                return
            }
            self.processingInFlight = false
            if shouldDismissSheetOnConfirm(paymentMethod: paymentMethod, setupIntent: setupIntent) {
                self.handleDismissSheet(shouldDismissImmediately: true)
            } else {
                self.savedPaymentOptionsViewController.didAddSavedPaymentMethod(paymentMethod: paymentMethod)
                self.mode = .selectingSaved
                self.updateUI(animated: true)
                self.reinitAddPaymentMethodViewController()
            }
        }
    }

    private func shouldDismissSheetOnConfirm(paymentMethod: STPPaymentMethod, setupIntent: STPSetupIntent) -> Bool{
        return paymentMethod.type == .USBankAccount && setupIntent.nextAction?.type == .verifyWithMicrodeposits
    }

    private func fetchClientSecret() async -> String? {
        var clientSecret: String?
        do {
            if let cs = cachedClientSecret {
                clientSecret = cs
            } else {
                clientSecret = try await customerAdapter.setupIntentClientSecretForCustomerAttach()
                cachedClientSecret = clientSecret
            }
        } catch {
            STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
            self.error = error
        }
        return clientSecret
    }

    private func fetchSetupIntent(clientSecret: String) async -> (STPSetupIntent, STPElementsSession)? {
        do {
            return try await configuration.apiClient.retrieveElementsSession(setupIntentClientSecret: clientSecret, configuration: .init())
        } catch {
            STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
            self.error = error
        }
        return nil
    }

    func confirm(intent: Intent?, paymentOption: PaymentOption) async -> STPSetupIntent? {
        var setupIntent: STPSetupIntent?
        do {
            setupIntent = try await withCheckedThrowingContinuation { continuation in
                self.delegate?.savedPaymentMethodsViewControllerShouldConfirm(intent, with: paymentOption, completion: { result in
                    switch result {
                    case .canceled:
                        STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentCanceled()
                        continuation.resume(with: .success(nil))
                    case .failed(let error):
                        STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
                        continuation.resume(throwing: error)
                    case .completed(let intent):
                        guard let intent = intent as? STPSetupIntent else {
                            STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
                            // Not ideal (but also very rare): If this fails, customers will need to know there is an error
                            // so that they can back out and try again
                            self.error = CustomerSheetError.unknown(debugDescription: "Unexpected error occured")
                            assertionFailure("addPaymentOption confirmation completed, but PaymentMethod is missing")
                            continuation.resume(throwing: CustomerSheetError.unknown(debugDescription: "Unexpected error occured"))
                            return
                        }
                        continuation.resume(with: .success(intent))
                    }
                })
            }
        } catch {
            self.error = error
        }
        return setupIntent
    }

    private func addPaymentOptionToCustomer(paymentOption: PaymentOption) {
        self.processingInFlight = true
        updateUI(animated: false)
        if case .new(let confirmParams) = paymentOption  {
            configuration.apiClient.createPaymentMethod(with: confirmParams.paymentMethodParams) { paymentMethod, error in
                if let error = error {
                    self.error = error
                    self.processingInFlight = false
                    STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaCreateAttachFailure()
                    self.actionButton.update(state: .enabled, animated: true) {
                        self.updateUI()
                    }
                    return
                }
                guard let paymentMethod = paymentMethod else {
                    self.error = CustomerSheetError.unknown(debugDescription: "Error on payment method creation")
                    self.processingInFlight = false
                    STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaCreateAttachFailure()
                    self.actionButton.update(state: .enabled, animated: true) {
                        self.updateUI()
                    }
                    return
                }
                Task {
                    do {
                        try await self.customerAdapter.attachPaymentMethod(paymentMethod.stripeId)
                    } catch {
                        self.error = error
                        self.processingInFlight = false
                        STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaCreateAttachFailure()
                        self.actionButton.update(state: .enabled, animated: true) {
                            self.updateUI()
                        }
                        return
                    }
                    self.processingInFlight = false
                    self.savedPaymentOptionsViewController.didAddSavedPaymentMethod(paymentMethod: paymentMethod)
                    self.mode = .selectingSaved
                    self.updateUI(animated: true)
                    self.reinitAddPaymentMethodViewController()
                }
            }
        }
    }

    // Called after adding a new payment method to clear out any text
    // that was entered as part of adding a new payment method.
    private func reinitAddPaymentMethodViewController() {
        self.addPaymentMethodViewController = CustomerAddPaymentMethodViewController(
            configuration: configuration,
            paymentMethodTypes: paymentMethodTypes,
            cbcEligible: cbcEligible,
            delegate: self)
        cachedClientSecret = nil
    }

    private func set(error: Error?) {
        self.error = error
        self.errorLabel.text = error?.nonGenericDescription
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.errorLabel.setHiddenIfNecessary(self.error == nil)
        }
    }

    // MARK: Helpers
    func configureEditSavedPaymentMethodsButton() {
        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            navigationBar.additionalButton.setTitle(UIButton.doneButtonTitle, for: .normal)
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.actionButton.setHiddenIfNecessary(true)
                self.updateBottomNotice()
            }
        } else {
            let showActionButton = self.savedPaymentOptionsViewController.didSelectDifferentPaymentMethod()
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.actionButton.setHiddenIfNecessary(!showActionButton)
                self.updateBottomNotice()
            }
            navigationBar.additionalButton.setTitle(UIButton.editButtonTitle, for: .normal)
        }
        navigationBar.additionalButton.accessibilityIdentifier = "edit_saved_button"
        navigationBar.additionalButton.titleLabel?.adjustsFontForContentSizeCategory = true
        navigationBar.additionalButton.addTarget(
            self, action: #selector(didSelectEditSavedPaymentMethodsButton), for: .touchUpInside)
    }

    private func setSelectablePaymentMethodAnimateButton(paymentOptionSelection: CustomerSheet.PaymentOptionSelection,
                                                         onError: @escaping (Error) -> Void,
                                                         onSuccess: @escaping () -> Void) {
        self.processingInFlight = true
        updateUI()
        self.setSelectablePaymentMethod(paymentOptionSelection: paymentOptionSelection) { error in
            self.processingInFlight = false
            self.updateUI()
            onError(error)
        } onSuccess: {
            self.actionButton.update(state: .disabled, animated: true) {
                onSuccess()
            }
        }
    }

    private func setSelectablePaymentMethod(paymentOptionSelection: CustomerSheet.PaymentOptionSelection,
                                            onError: @escaping (Error) -> Void,
                                            onSuccess: @escaping () -> Void) {
        Task {
            let customerPaymentMethodOption = paymentOptionSelection.customerPaymentMethodOption()
            do {
                try await customerAdapter.setSelectedPaymentOption(paymentOption: customerPaymentMethodOption)
                onSuccess()
            } catch {
                onError(error)
            }
        }
    }

    private func handleDismissSheet(shouldDismissImmediately: Bool = false) {
        guard !shouldDismissImmediately else {
            self.handleDismissSheet_completion()
            return
        }
        if mode == .selectingSaved && !self.savedPaymentOptionsViewController.unsyncedSavedPaymentMethods.isEmpty {
            if let selectedPaymentOption = self.savedPaymentOptionsViewController.selectedPaymentOption,
               case .saved(let selectedPaymentMethod, _) = selectedPaymentOption,
               self.savedPaymentOptionsViewController.unsyncedSavedPaymentMethods.first?.stripeId == selectedPaymentMethod.stripeId {
                didTapActionButton()
            } else {
                self.handleDismissSheet_completion()
            }
        } else if mode == .addingNewWithSetupIntent && self.addPaymentMethodViewController.shouldPreventDismissal() {
            let alertController = UIAlertController(title: String.Localized.closeFormTitle,
                                                    message: String.Localized.paymentInfoWontBeSaved,
                                                    preferredStyle: .alert)
            let dismissAction = UIAlertAction(title: String.Localized.close, style: .destructive) { (_) in
                alertController.dismiss(animated: true) {
                    self.handleDismissSheet_completion()
                }
            }
            alertController.addAction(UIAlertAction(title: String.Localized.cancel, style: .cancel))
            alertController.addAction(dismissAction)
            present(alertController, animated: true, completion: nil)
        } else {
            self.handleDismissSheet_completion()
        }
    }

    // This method should ONLY be called from handleDismissSheet()
    private func handleDismissSheet_completion() {
        if let originalSelectedPaymentMethod = savedPaymentOptionsViewController.originalSelectedSavedPaymentMethod {
            switch originalSelectedPaymentMethod {
            case .applePay:
                let paymentOptionSelection = CustomerSheet.PaymentOptionSelection.applePay()
                self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                    self.csCompletion?(.canceled(paymentOptionSelection))
                }
            case .stripeId(let paymentMethodId):
                if let paymentMethod = self.savedPaymentOptionsViewController.savedPaymentMethods.first(where: { $0.stripeId == paymentMethodId }) {
                    let paymentOptionSelection = CustomerSheet.PaymentOptionSelection.paymentMethod(paymentMethod)
                    self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                        self.csCompletion?(.canceled(paymentOptionSelection))
                    }
                } else {
                    self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                        self.csCompletion?(.canceled(nil))
                    }
                }
            default:
                assertionFailure("Selected payment method was something other than a saved payment method or apple pay")
            }

        } else {
            self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                self.csCompletion?(.canceled(nil))
            }
        }
    }

    @objc
    func didSelectEditSavedPaymentMethodsButton() {
        self.error = nil
        updateUI(animated: true)
        savedPaymentOptionsViewController.isRemovingPaymentMethods.toggle()
        configureEditSavedPaymentMethodsButton()
    }
}

extension CustomerSavedPaymentMethodsViewController: BottomSheetContentViewController {
    var allowsDragToDismiss: Bool {
        return isDismissable
    }

    func didTapOrSwipeToDismiss() {
        if isDismissable {
            handleDismissSheet()
        }
    }

    var requiresFullScreen: Bool {
        return false
    }
}

// MARK: - SheetNavigationBarDelegate
/// :nodoc:
extension CustomerSavedPaymentMethodsViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        handleDismissSheet()

        if savedPaymentOptionsViewController.isRemovingPaymentMethods {
            savedPaymentOptionsViewController.isRemovingPaymentMethods = false
            configureEditSavedPaymentMethodsButton()
        }

    }

    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        switch mode {
        case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
            error = nil
            mode = .selectingSaved
            updateUI()
        default:
            assertionFailure()
        }
    }
}
extension CustomerSavedPaymentMethodsViewController: CustomerAddPaymentMethodViewControllerDelegate {
    func didUpdate(_ viewController: CustomerAddPaymentMethodViewController) {
        error = nil
        updateUI()
    }
    func updateErrorLabel(for error: Error?) {
        set(error: error)
    }
}

extension CustomerSavedPaymentMethodsViewController: CustomerSavedPaymentMethodsCollectionViewControllerDelegate {

    func didUpdateSelection(
        viewController: CustomerSavedPaymentMethodsCollectionViewController,
        paymentMethodSelection: CustomerSavedPaymentMethodsCollectionViewController.Selection) {
            error = nil
            switch paymentMethodSelection {
            case .add:
                if customerAdapter.canCreateSetupIntents {
                    mode = .addingNewWithSetupIntent
                } else {
                    mode = .addingNewPaymentMethodAttachToCustomer
                }
                self.updateUI()
            case .saved:
                updateUI(animated: true)
            case .applePay:
                updateUI(animated: true)
            }
        }

    func didSelectRemove(
        viewController: CustomerSavedPaymentMethodsCollectionViewController,
        paymentMethodSelection: CustomerSavedPaymentMethodsCollectionViewController.Selection,
        originalPaymentMethodSelection: CustomerPaymentOption?) {
            guard case .saved(let paymentMethod) = paymentMethodSelection else {
                return
            }
            Task {
                do {
                    try await customerAdapter.detachPaymentMethod(paymentMethodId: paymentMethod.stripeId)
                } catch {
                    // Communicate error to consumer
                    self.set(error: error)
                    STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenRemovePMFailure()
                    return
                }

                if let originalPaymentMethodSelection, paymentMethodSelection == originalPaymentMethodSelection {
                    do {
                        try await self.customerAdapter.setSelectedPaymentOption(paymentOption: nil)
                    } catch {
                        // We are unable to persist the selectedPaymentMethodOption -- if we attempt to re-call
                        // a payment method that is no longer there, the UI should be able to handle not selecting it.
                        // Communicate error to consumer
                        self.set(error: error)
                        STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenRemovePMFailure()
                        return
                    }
                    STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenRemovePMSuccess()
                } else {
                    STPAnalyticsClient.sharedClient.logCSSelectPaymentMethodScreenRemovePMSuccess()
                }

                // If the customer can't edit anything anymore...
                if !savedPaymentOptionsViewController.canEditPaymentMethods {
                    // ...kick them out of edit mode. We'll do that by acting as if they tapped the "Done" button
                    didSelectEditSavedPaymentMethodsButton()
                } else {
                    updateBottomNotice()
                }
            }
        }

    func didSelectUpdate(viewController: CustomerSavedPaymentMethodsCollectionViewController,
                         paymentMethodSelection: CustomerSavedPaymentMethodsCollectionViewController.Selection,
                         updateParams: STPPaymentMethodUpdateParams) async throws -> STPPaymentMethod {
        guard case .saved(let paymentMethod) = paymentMethodSelection
        else {
            throw CustomerSheetError.unknown(debugDescription: "Failed to read payment method")
        }

        return try await customerAdapter.updatePaymentMethod(paymentMethodId: paymentMethod.stripeId, paymentMethodUpdateParams: updateParams)
    }
}
