//
//  CustomerAddPaymentMethodViewController.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

protocol CustomerAddPaymentMethodViewControllerDelegate: AnyObject {
    func didUpdate(_ viewController: CustomerAddPaymentMethodViewController)
    func updateErrorLabel(for: Swift.Error?)
}

@objc(STP_Internal_CustomerAddPaymentMethodViewController)
class CustomerAddPaymentMethodViewController: UIViewController {
    enum Error: Swift.Error {
        case paymentMethodTypesEmpty
        case usBankAccountParamsMissing
    }

    let paymentMethodTypes: [PaymentSheet.PaymentMethodType]
    let cbcEligible: Bool
    let savePaymentMethodConsentBehavior: PaymentSheetFormFactory.SavePaymentMethodConsentBehavior

    // MARK: - Read-only Properties
    weak var delegate: CustomerAddPaymentMethodViewControllerDelegate?

    var selectedPaymentMethodType: PaymentSheet.PaymentMethodType {
        return paymentMethodTypesView.selected
    }
    var paymentOption: PaymentOption? {
        let params = IntentConfirmParams(type: selectedPaymentMethodType)
        params.setDefaultBillingDetailsIfNecessary(for: configuration)
        if let params = paymentMethodFormElement.updateParams(params: params) {
            return .new(confirmParams: params)
        }
        return nil
    }
    // MARK: - Writable Properties
    private let configuration: CustomerSheet.Configuration

    /// This caches forms for payment methods so that customers don't have to re-enter details
    /// This assumes the form generated for a given PM type _does not change_ at any point after load.
    let formCache = PaymentMethodFormCache()

    /// Reference to the AddressSectionElement in the form, if present
    private var addressSectionElement: AddressSectionElement?
    var overrideActionButtonBehavior: OverrideableBuyButtonBehavior? {
        if selectedPaymentMethodType == .stripe(.USBankAccount) {
            if let paymentOption = paymentOption,
               case .new = paymentOption {
                return nil // already have PaymentOption
            } else {
                return .LinkUSBankAccount
            }
        }
        return nil
    }

    var overrideCallToAction: ConfirmButton.CallToActionType? {
        return overrideActionButtonBehavior != nil
            ? ConfirmButton.CallToActionType.customWithLock(title: String.Localized.continue)
            : nil
    }
    var overrideCallToActionShouldEnable: Bool {
        guard let overrideBuyButtonBehavior = overrideActionButtonBehavior else {
            return false
        }
        switch overrideBuyButtonBehavior {
        case .LinkUSBankAccount:
            let usBankAccountFormElement = formCache[.stripe(.USBankAccount)] as? USBankAccountPaymentMethodElement
            return usBankAccountFormElement?.canLinkAccount ?? false
        case .instantDebits:
            return false // instant debits is not supported for customer sheet
        }
    }

    var bottomNoticeAttributedString: NSAttributedString? {
        if selectedPaymentMethodType == .stripe(.USBankAccount) {
            if let usBankPaymentMethodElement = paymentMethodFormElement as? USBankAccountPaymentMethodElement {
                return usBankPaymentMethodElement.mandateString
            }
        }
        return nil
    }

    lazy var paymentMethodFormElement: PaymentMethodElement = {
        if let cachedForm = formCache[selectedPaymentMethodType] {
            return cachedForm
        } else {
            let element = makeElement(for: selectedPaymentMethodType)
            formCache[selectedPaymentMethodType] = element
            return element
        }
    }()

    // MARK: - Views
    private lazy var paymentMethodDetailsView: UIView = {
        return paymentMethodFormElement.view
    }()
    lazy var paymentMethodTypesView: PaymentMethodTypeCollectionView = {
        let view = PaymentMethodTypeCollectionView(
            paymentMethodTypes: paymentMethodTypes,
            appearance: configuration.appearance,
            incentive: nil,
            delegate: self
        )
        return view
    }()
    private lazy var paymentMethodDetailsContainerView: DynamicHeightContainerView = {
        let view = DynamicHeightContainerView(pinnedDirection: .bottom)
        // if the carousel is hidden, then we have a singular card form that needs to apply top padding
        // otherwise, the superview will handle the top padding
        let isCarouselHidden = paymentMethodTypes == [.stripe(.card)]
        view.directionalLayoutMargins = .insets(
            top: isCarouselHidden ? configuration.appearance.formInsets.top : 0,
            leading: configuration.appearance.formInsets.leading,
            trailing: configuration.appearance.formInsets.trailing
        )
        view.addPinnedSubview(paymentMethodDetailsView)
        view.updateHeight()
        return view
    }()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        configuration: CustomerSheet.Configuration,
        paymentMethodTypes: [PaymentSheet.PaymentMethodType],
        cbcEligible: Bool,
        savePaymentMethodConsentBehavior: PaymentSheetFormFactory.SavePaymentMethodConsentBehavior,
        delegate: CustomerAddPaymentMethodViewControllerDelegate
    ) {
        self.configuration = configuration
        self.delegate = delegate
        if paymentMethodTypes.isEmpty {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedCustomerSheetError,
                                              error: Error.paymentMethodTypesEmpty)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
        }
        stpAssert(!paymentMethodTypes.isEmpty, "At least one payment method type must be available.")
        self.paymentMethodTypes = paymentMethodTypes
        self.cbcEligible = cbcEligible
        self.savePaymentMethodConsentBehavior = savePaymentMethodConsentBehavior
        super.init(nibName: nil, bundle: nil)
        self.view.backgroundColor = configuration.appearance.colors.background
    }

    // MARK: - UIViewController
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        STPAnalyticsClient.sharedClient.logCSAddPaymentMethodScreenPresented()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendEventToSubviews(.viewDidAppear, from: view)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let stackView = UIStackView(arrangedSubviews: [
            paymentMethodTypesView, paymentMethodDetailsContainerView,
        ])
        stackView.bringSubviewToFront(paymentMethodTypesView)
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        if paymentMethodTypes == [.stripe(.card)] {
            paymentMethodTypesView.isHidden = true
        } else {
            paymentMethodTypesView.isHidden = false
        }
        updateUI()
    }

    func shouldPreventDismissal() -> Bool {
        guard let usBankAccountPaymentMethodElement = self.paymentMethodFormElement as? USBankAccountPaymentMethodElement else {
            return false
        }
        let customerHasLinkedBankAccount = usBankAccountPaymentMethodElement.linkedBank != nil
        return customerHasLinkedBankAccount
    }

    private func updateUI() {
        // Swap out the input view if necessary
        if paymentMethodFormElement.view !== paymentMethodDetailsView {
            let oldView = paymentMethodDetailsView
            let newView = paymentMethodFormElement.view
            self.paymentMethodDetailsView = newView

            // Add the new one and lay it out so it doesn't animate from a zero size
            paymentMethodDetailsContainerView.addPinnedSubview(newView)
            paymentMethodDetailsContainerView.layoutIfNeeded()
            newView.alpha = 0

            #if !os(visionOS)
            UISelectionFeedbackGenerator().selectionChanged()
            #endif
            // Fade the new one in and the old one out
            animateHeightChange {
                self.paymentMethodDetailsContainerView.updateHeight()
                oldView.alpha = 0
                newView.alpha = 1
            } completion: { _ in
                // Remove the old one
                // This if check protects against a race condition where if you switch
                // between types with a re-used element (aka USBankAccountPaymentPaymentElement)
                // we swap the views before the animation completes
                if oldView !== self.paymentMethodDetailsView {
                    oldView.removeFromSuperview()
                }
            }
        }
    }
    private func updateFormElement() {
        if let cachedForm = formCache[selectedPaymentMethodType] {
            paymentMethodFormElement = cachedForm
        } else {
            let element = makeElement(for: selectedPaymentMethodType)
            formCache[selectedPaymentMethodType] = element
            paymentMethodFormElement = element
        }
        updateUI()
        sendEventToSubviews(.viewDidAppear, from: view)
    }
    private func makeElement(for type: PaymentSheet.PaymentMethodType) -> PaymentMethodElement {
        let configuration = PaymentSheetFormFactoryConfig.customerSheet(configuration)
        let formElement = PaymentSheetFormFactory(
            configuration: configuration,
            paymentMethod: type,
            previousCustomerInput: nil,
            addressSpecProvider: .shared,
            showLinkInlineCardSignup: false,
            linkAccount: nil,
            accountService: nil,
            cardBrandChoiceEligible: cbcEligible,
            isPaymentIntent: false,
            isSettingUp: true,
            countryCode: nil,
            savePaymentMethodConsentBehavior: savePaymentMethodConsentBehavior,
            analyticsHelper: nil,
            paymentMethodIncentive: nil
        ).make()
        formElement.delegate = self

        // Setup AddressSectionElement autocomplete callback after form creation
        setupAddressSectionAutocompleteCallback(for: formElement)

        return formElement
    }

    // MARK: - Autocomplete Methods

    /// Sets up the autocomplete button callback for any AddressSectionElement in the form
    /// TODO(porter) Make this more generic for when we have shipping address section in here too
    private func setupAddressSectionAutocompleteCallback(for formElement: PaymentMethodElement) {
        let unwrappedFormElement = (formElement as? PaymentMethodElementWrapper<FormElement>)?.element ?? formElement
        if let addressSection = unwrappedFormElement.getAllUnwrappedSubElements()
            .compactMap({ $0 as? AddressSectionElement }).first {
            // Store reference to the address section element
            self.addressSectionElement = addressSection
            addressSection.didTapAutocompleteButton = { [weak self] in
                self?.presentAutocomplete()
            }
        }
    }

    /// Presents the autocomplete view controller
    private func presentAutocomplete() {
        guard let addressSectionElement = addressSectionElement else {
            return
        }

        // Create a basic AddressViewController.Configuration for the autocomplete
        let addressConfiguration = AddressViewController.Configuration(
            appearance: configuration.appearance
        )

        let autoCompleteViewController = AutoCompleteViewController(
            configuration: addressConfiguration,
            initialLine1Text: addressSectionElement.line1?.text,
            addressSpecProvider: AddressSpecProvider.shared,
            verticalOffset: PaymentSheetUI.navBarPadding(appearance: configuration.appearance)
        )
        autoCompleteViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: autoCompleteViewController)
        present(navigationController, animated: true)
    }
}

extension CustomerAddPaymentMethodViewController {
    func didTapCallToActionButton(behavior: OverrideableBuyButtonBehavior,
                                  clientSecret: String,
                                  from viewController: UIViewController) {
        switch behavior {
        case .LinkUSBankAccount:
            handleCollectBankAccount(from: viewController, clientSecret: clientSecret)
        case .instantDebits:
            assertionFailure("instant debits is not supported for customer sheet")
        }
    }
    func handleCollectBankAccount(from viewController: UIViewController, clientSecret: String) {
        guard
            let usBankAccountPaymentMethodElement = self.paymentMethodFormElement as? USBankAccountPaymentMethodElement,
            let name = usBankAccountPaymentMethodElement.name,
            let email = usBankAccountPaymentMethodElement.email
        else {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedCustomerSheetError,
                                              error: Error.usBankAccountParamsMissing)
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
            stpAssertionFailure()
            return
        }

        let params = STPCollectBankAccountParams.collectUSBankAccountParams(
            with: name,
            email: email
        )
        let bankAccountCollectorStyle: STPBankAccountCollectorUserInterfaceStyle = {
            switch configuration.style {
            case .automatic: return .automatic
            case .alwaysLight: return .alwaysLight
            case .alwaysDark: return .alwaysDark
            }
        }()
        let client = STPBankAccountCollector(style: bankAccountCollectorStyle)
        let errorText = STPLocalizedString(
            "Something went wrong when linking your account.\nPlease try again later.",
            "Error message when an error case happens when linking your account"
        )
        let genericError = PaymentSheetError.unknown(debugDescription: errorText)

        let financialConnectionsCompletion: (FinancialConnectionsSDKResult?, LinkAccountSession?, NSError?) -> Void = {
            result,
            _,
            error in
            if let error = error {
                let errorToUse = PaymentSheetError.unknown(debugDescription: error.nonGenericDescription)
                self.delegate?.updateErrorLabel(for: errorToUse)
                return
            }
            guard let financialConnectionsResult = result else {
                self.delegate?.updateErrorLabel(for: genericError)
                return
            }

            switch financialConnectionsResult {
            case .cancelled:
                break
            case .completed(let completedResult):
                if case .financialConnections(let linkedBank) = completedResult {
                    usBankAccountPaymentMethodElement.linkedBank = linkedBank
                } else {
                    self.delegate?.updateErrorLabel(for: genericError)
                }
            case .failed:
                self.delegate?.updateErrorLabel(for: genericError)
            }
        }

        let additionalParameters: [String: Any] = [
            "hosted_surface": "customer_sheet",
        ]
        client.collectBankAccountForSetup(
            clientSecret: clientSecret,
            returnURL: configuration.returnURL,
            additionalParameters: additionalParameters,
            onEvent: nil,
            params: params,
            from: viewController,
            financialConnectionsCompletion: financialConnectionsCompletion
        )
    }
}
extension CustomerAddPaymentMethodViewController: ElementDelegate {
    func continueToNextField(element: Element) {
        delegate?.didUpdate(self)
    }

    func didUpdate(element: Element) {
        delegate?.didUpdate(self)
        animateHeightChange()
    }
}

extension CustomerAddPaymentMethodViewController: PaymentMethodTypeCollectionViewDelegate {
    func didUpdateSelection(_ paymentMethodTypeCollectionView: PaymentMethodTypeCollectionView) {
        updateFormElement()
        delegate?.didUpdate(self)
    }
}

extension CustomerAddPaymentMethodViewController: PresentingViewControllerDelegate {
    func presentViewController(viewController: UIViewController, completion: (() -> Void)?) {
        self.present(viewController, animated: true, completion: completion)
    }
}

// MARK: - AutoCompleteViewControllerDelegate

extension CustomerAddPaymentMethodViewController: AutoCompleteViewControllerDelegate {
    func didSelectManualEntry(_ line1: String) {
        guard let addressSectionElement = addressSectionElement else { return }

        // Dismiss the autocomplete view controller
        presentedViewController?.dismiss(animated: true) {
            // Switch to manual entry mode and set the line1 text
            addressSectionElement.collectionMode = .allWithAutocomplete
            addressSectionElement.line1?.setText(line1)
            addressSectionElement.line1?.beginEditing()
        }
    }

    func didSelectAddress(_ address: PaymentSheet.Address?) {
        guard let addressSectionElement = addressSectionElement else { return }

        // Dismiss the autocomplete view controller
        presentedViewController?.dismiss(animated: true) {
            // Switch to manual entry mode after address selection
            addressSectionElement.collectionMode = .allWithAutocomplete

            guard let address = address else {
                return
            }

            // Set the country if it's supported
            let autocompleteCountryIndex = addressSectionElement.countryCodes.firstIndex(where: { $0 == address.country })
            if let autocompleteCountryIndex = autocompleteCountryIndex {
                addressSectionElement.country.select(index: autocompleteCountryIndex, shouldAutoAdvance: false)
            }

            // Populate the address fields
            addressSectionElement.line1?.setText(address.line1 ?? "")
            addressSectionElement.line2?.setText(address.line2 ?? "")
            addressSectionElement.city?.setText(address.city ?? "")
            addressSectionElement.postalCode?.setText(address.postalCode ?? "")
            addressSectionElement.state?.setRawData(address.state ?? "", shouldAutoAdvance: false)
        }
    }
}
