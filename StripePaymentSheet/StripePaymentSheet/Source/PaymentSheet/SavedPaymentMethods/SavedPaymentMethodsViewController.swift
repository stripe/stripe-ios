//
//  SavedPaymentMethodsViewController.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) @_spi(PrivateBetaSavedPaymentMethodsSheet) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol SavedPaymentMethodsViewControllerDelegate: AnyObject {
    func savedPaymentMethodsViewControllerShouldConfirm(_ intent: Intent?,
                                                        with paymentOption: PaymentOption,
                                                        completion: @escaping(SavedPaymentMethodsSheetResult) -> Void)
    func savedPaymentMethodsViewControllerDidCancel(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController, completion: @escaping () -> Void)
    func savedPaymentMethodsViewControllerDidFinish(_ savedPaymentMethodsViewController: SavedPaymentMethodsViewController, completion: @escaping () -> Void)
}

@objc(STP_Internal_SavedPaymentMethodsViewController)
class SavedPaymentMethodsViewController: UIViewController {

    // MARK: - Read-only Properties
    let savedPaymentMethods: [STPPaymentMethod]
    let isApplePayEnabled: Bool
    let configuration: SavedPaymentMethodsSheet.Configuration

    // MARK: - Writable Properties
    weak var delegate: SavedPaymentMethodsViewControllerDelegate?
    weak var savedPaymentMethodsSheetDelegate: SavedPaymentMethodsSheetDelegate?
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
    private lazy var addPaymentMethodViewController: SavedPaymentMethodsAddPaymentMethodViewController = {
        return SavedPaymentMethodsAddPaymentMethodViewController(
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

    private lazy var savedPaymentOptionsViewController: SavedPaymentMethodsCollectionViewController = {
        let showApplePay = isApplePayEnabled
        return SavedPaymentMethodsCollectionViewController(
            savedPaymentMethods: savedPaymentMethods,
            savedPaymentMethodsConfiguration: self.configuration,
            configuration: .init(
                showApplePay: showApplePay,
                autoSelectDefaultBehavior: savedPaymentMethods.isEmpty ? .none : .onlyIfMatched
            ),
            appearance: configuration.appearance,
            savedPaymentMethodsSheetDelegate: savedPaymentMethodsSheetDelegate,
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
        configuration: SavedPaymentMethodsSheet.Configuration,
        isApplePayEnabled: Bool,
        savedPaymentMethodsSheetDelegate: SavedPaymentMethodsSheetDelegate?,
        delegate: SavedPaymentMethodsViewControllerDelegate
    ) {
        self.savedPaymentMethods = savedPaymentMethods
        self.configuration = configuration
        self.isApplePayEnabled = isApplePayEnabled
        self.savedPaymentMethodsSheetDelegate = savedPaymentMethodsSheetDelegate
        self.delegate = delegate
        if savedPaymentMethods.isEmpty {
            if configuration.createSetupIntentHandler != nil {
                self.mode = .addingNewWithSetupIntent
            } else {
                self.mode = .addingNewPaymentMethodAttachToCustomer
            }
        } else {
            self.mode = .selectingSaved
        }
        super.init(nibName: nil, bundle: nil)

        self.view.backgroundColor = configuration.appearance.colors.background
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        let stackView = UIStackView(arrangedSubviews: [
            headerLabel,
            paymentContainerView,
            actionButton,
            errorLabel,
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
                    "Select your payment method",
                    "Title shown above a carousel containing the customer's payment methods")
            }

        case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
            actionButton.isHidden = false
            headerLabel.text = STPLocalizedString(
                "Add your payment information",
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
        switch mode {
        case .addingNewWithSetupIntent, .addingNewPaymentMethodAttachToCustomer:
            // TODO: Test that this works
            errorLabel.text = error?.localizedDescription
        case .selectingSaved:
            errorLabel.text = error?.nonGenericDescription
        }
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
            self.actionButton.isHidden = false
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
            self.actionButton.isHidden = !showActionButton
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
                    return savedPaymentMethods.isEmpty ? .close(showAdditionalButton: false) : .back
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
                "Add",
                "A button used for adding a new payment method"
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
                    let paymentOptionSelection = SavedPaymentMethodsSheet.PaymentOptionSelection.applePay()
                    setSelectablePaymentMethodAnimateButton(paymentOptionSelection: paymentOptionSelection) { error in
                        self.savedPaymentMethodsSheetDelegate?.didFail(with: .setSelectedPaymentMethodOption(error))
                    } onSuccess: {
                        self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                            self.savedPaymentMethodsSheetDelegate?.didFinish(with: paymentOptionSelection)
                        }
                    }

                case .saved(let paymentMethod):
                    let paymentOptionSelection = SavedPaymentMethodsSheet.PaymentOptionSelection.savedPaymentMethod(paymentMethod)
                    setSelectablePaymentMethodAnimateButton(paymentOptionSelection: paymentOptionSelection) { error in
                        self.savedPaymentMethodsSheetDelegate?.didFail(with: .setSelectedPaymentMethodOption(error))
                    } onSuccess: {
                        self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                            self.savedPaymentMethodsSheetDelegate?.didFinish(with: paymentOptionSelection)
                        }
                    }
                default:
                    assertionFailure("Selected payment method was something other than a saved payment method or apple pay")
                }

            }
        }
    }

    private func addPaymentOption(paymentOption: PaymentOption) {
        guard case .new = paymentOption,
        let createSetupIntentHandler = self.configuration.createSetupIntentHandler else {
            return
        }
        self.processingInFlight = true
        updateUI(animated: false)

        createSetupIntentHandler({ result in
            guard let clientSecret = result else {
                self.processingInFlight = false
                self.updateUI()
                self.savedPaymentMethodsSheetDelegate?.didFail(with: .setupIntentClientSecretInvalid)
                return
            }
            self.fetchSetupIntent(clientSecret: clientSecret) { result in
                switch result {
                case .success(let stpSetupIntent):
                    let setupIntent = Intent.setupIntent(stpSetupIntent)
                    self.confirm(intent: setupIntent, paymentOption: paymentOption)
                case .failure(let error):
                    self.processingInFlight = false
                    self.updateUI()
                    self.savedPaymentMethodsSheetDelegate?.didFail(with: .setupIntentFetchError(error))
                }
            }
        })
    }

    func confirm(intent: Intent?, paymentOption: PaymentOption) {
        self.delegate?.savedPaymentMethodsViewControllerShouldConfirm(intent, with: paymentOption, completion: { result in
            self.processingInFlight = false
            switch result {
            case .canceled:
                self.updateUI()
            case .failed(let error):
                self.error = error
                self.updateUI()
            case .completed(let intent):
                guard let intent = intent as? STPSetupIntent,
                      let paymentMethod = intent.paymentMethod else {
                    self.processingInFlight = false
                    self.updateUI()
                    self.savedPaymentMethodsSheetDelegate?.didFail(with: .unknown(debugDescription: "addPaymentOption completed without SI/PM"))
                    return
                }

                let paymentOptionSelection = SavedPaymentMethodsSheet.PaymentOptionSelection.newPaymentMethod(paymentMethod)
                self.setSelectablePaymentMethod(paymentOptionSelection: paymentOptionSelection) { error in
                    self.processingInFlight = false
                    self.savedPaymentMethodsSheetDelegate?.didFail(with: .setSelectedPaymentMethodOption(error))
                    self.updateUI()
                } onSuccess: {
                    self.processingInFlight = false
                    self.actionButton.update(state: .disabled, animated: true) {
                        self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                            self.savedPaymentMethodsSheetDelegate?.didFinish(with: paymentOptionSelection)
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
                    self.updateUI()
                    self.processingInFlight = false
                    self.savedPaymentMethodsSheetDelegate?.didFail(with: .createPaymentMethod(error))
                    return
                }
                guard let paymentMethod = paymentMethod else {
                    self.processingInFlight = false
                    self.savedPaymentMethodsSheetDelegate?.didFail(with: .unknown(debugDescription: "No payment method available"))
                    return
                }
                self.configuration.customerContext.attachPaymentMethod(toCustomer: paymentMethod) { error in
                    if let error = error {
                        self.error = error
                        self.updateUI()
                        self.processingInFlight = false
                        self.savedPaymentMethodsSheetDelegate?.didFail(with: .attachPaymentMethod(error))
                        return
                    }
                    let paymentOptionSelection = SavedPaymentMethodsSheet.PaymentOptionSelection.savedPaymentMethod(paymentMethod)
                    self.setSelectablePaymentMethod(paymentOptionSelection: paymentOptionSelection) { error in
                        self.processingInFlight = false
                        self.savedPaymentMethodsSheetDelegate?.didFail(with: .setSelectedPaymentMethodOption(error))
                    } onSuccess: {
                        self.processingInFlight = false
                        self.actionButton.update(state: .disabled, animated: true) {
                            self.delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                                self.savedPaymentMethodsSheetDelegate?.didFinish(with: paymentOptionSelection)
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
            actionButton.update(state: .disabled)
        } else {
            actionButton.update(state: .enabled)
            navigationBar.additionalButton.setTitle(UIButton.editButtonTitle, for: .normal)
        }
        navigationBar.additionalButton.accessibilityIdentifier = "edit_saved_button"
        navigationBar.additionalButton.titleLabel?.adjustsFontForContentSizeCategory = true
        navigationBar.additionalButton.addTarget(
            self, action: #selector(didSelectEditSavedPaymentMethodsButton), for: .touchUpInside)
    }

    private func setSelectablePaymentMethodAnimateButton(paymentOptionSelection: SavedPaymentMethodsSheet.PaymentOptionSelection,
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

    private func setSelectablePaymentMethod(paymentOptionSelection: SavedPaymentMethodsSheet.PaymentOptionSelection,
                                            onError: @escaping (Error) -> Void,
                                            onSuccess: @escaping () -> Void) {
        if let setSelectedPaymentMethodOption = self.configuration.customerContext.setSelectedPaymentMethodOption {
            let persistablePaymentOption = paymentOptionSelection.persistablePaymentMethodOption()
            setSelectedPaymentMethodOption(persistablePaymentOption) { error in
                if let error = error {
                    onError(error)
                } else {
                    onSuccess()
                }
            }
        } else {
            onSuccess()
        }
    }

    private func handleDismissSheet() {
        if savedPaymentOptionsViewController.originalSelectedSavedPaymentMethod != nil &&
            savedPaymentOptionsViewController.selectedPaymentOption == nil {
            delegate?.savedPaymentMethodsViewControllerDidFinish(self) {
                self.savedPaymentMethodsSheetDelegate?.didFinish(with: nil)
            }
        } else {
            delegate?.savedPaymentMethodsViewControllerDidCancel(self) {
                self.savedPaymentMethodsSheetDelegate?.didCancel()
            }
        }
    }

    @objc
    func didSelectEditSavedPaymentMethodsButton() {
        savedPaymentOptionsViewController.isRemovingPaymentMethods.toggle()
        configureEditSavedPaymentMethodsButton()
    }
}

extension SavedPaymentMethodsViewController: BottomSheetContentViewController {
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
extension SavedPaymentMethodsViewController: SheetNavigationBarDelegate {
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
extension SavedPaymentMethodsViewController: SavedPaymentMethodsAddPaymentMethodViewControllerDelegate {
    func didUpdate(_ viewController: SavedPaymentMethodsAddPaymentMethodViewController) {
        error = nil
        updateUI()
    }
}

extension SavedPaymentMethodsViewController: SavedPaymentMethodsCollectionViewControllerDelegate {
    func didUpdateSelection(
        viewController: SavedPaymentMethodsCollectionViewController,
        paymentMethodSelection: SavedPaymentMethodsCollectionViewController.Selection) {
            switch paymentMethodSelection {
            case .add:
                error = nil
                if self.configuration.createSetupIntentHandler != nil {
                    mode =  .addingNewWithSetupIntent
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
        viewController: SavedPaymentMethodsCollectionViewController,
        paymentMethodSelection: SavedPaymentMethodsCollectionViewController.Selection) {
            guard case .saved(let paymentMethod) = paymentMethodSelection else {
                return
            }
            configuration.customerContext.detachPaymentMethod?(fromCustomer: paymentMethod, completion: { error in
                if let error = error {
                    self.savedPaymentMethodsSheetDelegate?.didFail(with: .detachPaymentMethod(error))
                    self.set(error: error)
                    return
                }
                self.configuration.customerContext.setSelectedPaymentMethodOption?(paymentOption: nil, completion: { error in
                    if let error = error {
                        self.savedPaymentMethodsSheetDelegate?.didFail(with: .setSelectedPaymentMethodOption(error))
                        // We are unable to persist the selectedPaymentMethodOption -- if we attempt to re-call
                        // a payment method that is no longer there, the UI should be able to handle not selecting it.
                    }
                })
            })
        }
}
