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
            delegate: self)
    }()

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
                autoSelectDefaultBehavior: shouldShowPaymentMethodCarousel ? .onlyIfMatched : .none
            ),
            appearance: configuration.appearance,
            delegate: self
        )
    }()
    private lazy var paymentContainerView: DynamicHeightContainerView = {
        return DynamicHeightContainerView()
    }()
    private lazy var actionButton: ConfirmButton = {
        let button = ConfirmButton(
            callToAction: self.callToAction(),
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

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        savedPaymentMethods: [STPPaymentMethod],
        selectedPaymentMethodOption: CustomerPaymentOption?,
        configuration: CustomerSheet.Configuration,
        customerAdapter: CustomerAdapter,
        isApplePayEnabled: Bool,
        csCompletion: CustomerSheet.CustomerSheetCompletion?,
        delegate: CustomerSavedPaymentMethodsViewControllerDelegate
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.selectedPaymentMethodOption = selectedPaymentMethodOption
        self.configuration = configuration
        self.customerAdapter = customerAdapter
        self.isApplePayEnabled = isApplePayEnabled
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

        switch mode {
        case .selectingSaved:
            if savedPaymentOptionsViewController.selectedPaymentOption != nil {
                showActionButton = savedPaymentOptionsViewController.didSelectDifferentPaymentMethod()
            } else {
                showActionButton = false
            }
        case .addingNewPaymentMethodAttachToCustomer, .addingNewWithSetupIntent:
            self.actionButton.setHiddenIfNecessary(false)
            actionButtonStatus = addPaymentMethodViewController.paymentOption == nil ? .disabled : .enabled
        }

        if processingInFlight {
            actionButtonStatus = .spinnerWithInteractionDisabled
        }

        self.actionButton.update(
            state: actionButtonStatus,
            style: .stripe,
            callToAction: callToAction(),
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
                    if self.savedPaymentOptionsViewController.hasRemovablePaymentMethods {
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

    private func callToAction() -> ConfirmButton.CallToActionType {
        switch mode {
        case .selectingSaved:
            return .custom(title: STPLocalizedString(
                "Confirm",
                "A button used to confirm selecting a saved payment method"
            ))
        case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
            return .custom(title: STPLocalizedString(
                "Save",
                "A button used for saving a new payment method"
            ))
        }
    }

    func fetchSetupIntent(clientSecret: String, completion: @escaping ((Result<STPSetupIntent, Error>) -> Void) ) {
        configuration.apiClient.retrieveSetupIntentWithPreferences(withClientSecret: clientSecret) { result in
            switch result {
            case .success(let setupIntent):
                completion(.success(setupIntent))
            case .failure(let error):
                completion(.failure(error))
            }

        }
    }

    private func didTapActionButton() {
        error = nil
        updateUI()

        switch mode {
        case .addingNewWithSetupIntent:
            guard let newPaymentOption = addPaymentMethodViewController.paymentOption else {
                return
            }
            addPaymentOption(paymentOption: newPaymentOption)
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

                case .saved(let paymentMethod):
                    let paymentOptionSelection = CustomerSheet.PaymentOptionSelection.savedPaymentMethod(paymentMethod)
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

    private func addPaymentOption(paymentOption: PaymentOption) {
        guard case .new = paymentOption, customerAdapter.canCreateSetupIntents else {
            STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
            return
        }
        self.processingInFlight = true
        updateUI(animated: false)

        Task {
            var clientSecret: String
            do {
                clientSecret = try await customerAdapter.setupIntentClientSecretForCustomerAttach()
            } catch {
                STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
                self.processingInFlight = false
                self.error = error
                self.updateUI()
                return
            }

            self.fetchSetupIntent(clientSecret: clientSecret) { result in
                switch result {
                case .success(let stpSetupIntent):
                    let setupIntent = Intent.setupIntent(stpSetupIntent)
                    self.confirm(intent: setupIntent, paymentOption: paymentOption)
                case .failure(let error):
                    STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
                    self.processingInFlight = false
                    self.error = error
                    self.updateUI()
                }
            }
        }
    }

    func confirm(intent: Intent?, paymentOption: PaymentOption) {
        self.delegate?.savedPaymentMethodsViewControllerShouldConfirm(intent, with: paymentOption, completion: { result in
            self.processingInFlight = false
            switch result {
            case .canceled:
                STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentCanceled()
                self.updateUI()
            case .failed(let error):
                STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
                self.error = error
                self.updateUI()
            case .completed(let intent):
                guard let intent = intent as? STPSetupIntent,
                      let paymentMethod = intent.paymentMethod else {
                    STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
                    self.processingInFlight = false
                    // Not ideal (but also very rare): If this fails, customers will need to know there is an error
                    // so that they can back out and try again
                    self.error = CustomerSheetError.unknown(debugDescription: "Unexpected error occured")
                    self.updateUI()
                    assertionFailure("addPaymentOption confirmation completed, but PaymentMethod is missing")
                    return
                }

                let paymentOptionSelection = CustomerSheet.PaymentOptionSelection.newPaymentMethod(paymentMethod)
                self.setSelectablePaymentMethod(paymentOptionSelection: paymentOptionSelection) { error in
                    STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentFailure()
                    self.processingInFlight = false
                    self.error = error
                    self.updateUI()
                } onSuccess: {
                    STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaSetupIntentSuccess()
                    self.processingInFlight = false
                    self.actionButton.update(state: .disabled, animated: true) {
                        self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                            self.csCompletion?(.selected(paymentOptionSelection))
                        }
                    }
                }
            }
        })
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
                    let paymentOptionSelection = CustomerSheet.PaymentOptionSelection.savedPaymentMethod(paymentMethod)
                    self.setSelectablePaymentMethod(paymentOptionSelection: paymentOptionSelection) { error in
                        self.processingInFlight = false
                        STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaCreateAttachFailure()
                        self.error = error
                        self.actionButton.update(state: .enabled, animated: true) {
                            self.updateUI()
                        }
                    } onSuccess: {
                        self.processingInFlight = false
                        STPAnalyticsClient.sharedClient.logCSAddPaymentMethodViaCreateAttachSuccess()
                        self.actionButton.update(state: .disabled, animated: true) {
                            self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                                self.csCompletion?(.selected(paymentOptionSelection))
                            }
                        }
                    }
                }
            }
        }
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
            }
        } else {
            let showActionButton = self.savedPaymentOptionsViewController.didSelectDifferentPaymentMethod()
            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                self.actionButton.setHiddenIfNecessary(!showActionButton)
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

    private func handleDismissSheet() {
        if savedPaymentOptionsViewController.originalSelectedSavedPaymentMethod != nil &&
            savedPaymentOptionsViewController.selectedPaymentOption == nil {
            delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                self.csCompletion?(.selected(nil))
            }
        } else {
            delegate?.savedPaymentMethodsViewControllerDidCancel(self) {
                self.csCompletion?(.canceled)
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

                if let originalPaymentMethodSelection = originalPaymentMethodSelection,
                   paymentMethodSelection == originalPaymentMethodSelection {
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
            }
        }
}
