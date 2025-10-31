//
//  AddressViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// A delegate for `AddressViewController`
@MainActor @preconcurrency
public protocol AddressViewControllerDelegate: AnyObject {
    /// Called when the customer finishes entering their address or dismisses the view controller. Your implementation should dismiss the view controller.
    /// - Parameter address: A valid address or nil if the address information is incomplete or invalid.
    func addressViewControllerDidFinish(_ addressViewController: AddressViewController, with address: AddressViewController.AddressDetails?)
}

/// A view controller that collects a name and an address, with full localization and autocomplete.
/// - Note: It uses `navigationItem` and can push a view controller, so it must be shown inside a `UINavigationController`.
/// - Seealso: https://stripe.com/docs/elements/address-element?platform=ios
@objc(STPAddressViewController)
public class AddressViewController: UIViewController {
    // MARK: - Public properties
    /// Configuration containing e.g. appearance styling properties, default values, etc.
    public let configuration: Configuration
    /// A valid address or nil.
    private var addressDetails: AddressDetails? {
        guard let addressSection = addressSection else { return nil }

        guard case .valid = addressSection.validationState,
              let line1 = addressSection.line1?.text.nonEmpty
        else {
            return nil
        }
        let address = AddressDetails.Address(
            city: addressSection.city?.text.nonEmpty,
            country: addressSection.selectedCountryCode,
            line1: line1,
            line2: addressSection.line2?.text.nonEmpty,
            postalCode: addressSection.postalCode?.text.nonEmpty,
            state: addressSection.state?.rawData.nonEmpty
        )
        return .init(
            address: address,
            name: addressSection.name?.text.nonEmpty,
            phone: addressSection.phone?.phoneNumber?.string(as: .e164).nonEmpty,
            isCheckboxSelected: checkboxElement?.checkboxButton.isSelected
        )
    }
    /// The delegate, notified when the customer completes or cancels.
    public weak var delegate: AddressViewControllerDelegate?
    private var selectedAutoCompleteResult: PaymentSheet.Address?
    private var didLogAddressShow = false

    // MARK: - Internal properties
    let addressSpecProvider: AddressSpecProvider
    private var latestError: Error? {
        didSet {
            errorLabel.text = latestError?.localizedDescription
            errorLabel.isHidden = latestError == nil
        }
    }
    lazy var scrollViewBottomConstraint: NSLayoutConstraint = {
        return scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
    }()

    // MARK: - Views
    lazy var button: ConfirmButton = {
        let button = ConfirmButton(
            state: (addressSection?.validationState.isValid ?? false) ? .enabled : .disabled,
            callToAction: .custom(title: configuration.buttonTitle),
            appearance: configuration.appearance
        ) { [weak self] in
            self?.didContinue()
        }
        return button
    }()
    private lazy var headerLabel: UILabel = {
        let header = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        header.text = configuration.title
        return header
    }()
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        #if !os(visionOS)
        scrollView.keyboardDismissMode = .onDrag
        #endif
        return scrollView
    }()
    lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
        label.isHidden = true
        return label
    }()

    // MARK: - Elements
    lazy var formElement: FormElement = {
        var customSpacing: [(Element, CGFloat)] = []

        // Add padding under the shipping equals billing checkbox if it exists
        if let shippingCheckbox = shippingEqualsBillingCheckbox {
            // Default spacing is a bit too tight for what we want, scale the appearance value a bit
            customSpacing.append((shippingCheckbox, configuration.appearance.sectionSpacing * 1.6))
        }

        let formElement = FormElement(
            elements: [shippingEqualsBillingCheckbox, addressSection, checkboxElement],
            theme: configuration.appearance.asElementsTheme,
            customSpacing: customSpacing
        )
        formElement.delegate = self
        return formElement
    }()
    var addressSection: AddressSectionElement?
    lazy var checkboxElement: CheckboxElement? = {
        guard let checkboxLabel = configuration.additionalFields.checkboxLabel  else { return nil }
        let element = CheckboxElement(
            theme: configuration.appearance.asElementsTheme,
            label: checkboxLabel,
            isSelectedByDefault: configuration.defaultValues.isCheckboxSelected ?? false,
            didToggle: nil
        )

        return element
    }()

    /// Returns the shipping address if it is compatible with allowed countries, otherwise returns the billing address if compatible.
    private var compatibleDefaultValues: AddressViewController.Configuration.DefaultAddressDetails? {
        // Try shipping address (defaultValues) first
        if !configuration.defaultValues.address.isEmpty {
            if isAddressCompatible(configuration.defaultValues) {
                return configuration.defaultValues
            }
        } else if configuration.defaultValues.name?.isEmpty == false {
            return configuration.defaultValues
        }

        // Fall back to billing address
        if let billingAddress = configuration.billingAddress {
            if isAddressCompatible(billingAddress) {
                return billingAddress
            }
        }

        return nil
    }

    /// Checks if an address is compatible with the allowed countries configuration.
    private func isAddressCompatible(_ addressDetails: AddressViewController.Configuration.DefaultAddressDetails) -> Bool {
        // No default address provided, early exit
        guard !addressDetails.address.isEmpty else { return false }

        // No blocked countries, allow all default addresses
        guard !configuration.allowedCountries.isEmpty else { return true }

        // Default address has no country specified, allow it
        guard let defaultCountry = addressDetails.address.country else { return true }

        // Only allow default addresses with allowed countries
        return configuration.allowedCountries.contains(defaultCountry)
    }

    private lazy var shippingEqualsBillingCheckbox: CheckboxElement? = {
        // Show checkbox when billing address is provided and is compatible with allowed countries
        guard let billingAddress = configuration.billingAddress else { return nil }

        // Check if billing address is compatible with allowed countries
        let isCompatible: Bool = {
            // No blocked countries, allow all billing addresses
            guard !configuration.allowedCountries.isEmpty else { return true }

            // Billing address has no country specified, allow it
            guard let billingCountry = billingAddress.address.country else { return true }

            // Only show checkbox for billing addresses with allowed countries
            return configuration.allowedCountries.contains(billingCountry)
        }()

        guard isCompatible else { return nil }

        // Only show checkbox if billing address has at least line1
        guard billingAddress.address.line1?.nonEmpty != nil else { return nil }

        // Default to checked if shipping address (defaultValues) is empty
        let isSelectedByDefault = configuration.defaultValues.address.isEmpty

        return CheckboxElement(
            theme: configuration.appearance.asElementsTheme,
            label: String.Localized.use_billing_address_for_shipping,
            isSelectedByDefault: isSelectedByDefault,
            didToggle: { [weak self] isSelected in
                self?.handleShippingEqualsBillingToggle(isSelected: isSelected)
            }
        )
    }()

    fileprivate lazy var closeButton: UIButton = {
        let button = SheetNavigationButton.makeCloseButton(appearance: configuration.appearance)
        button.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        return button
    }()

    private lazy var activityIndicator = UIActivityIndicatorView(style: .medium)

    private var hasLoadedSpecs = false

    // MARK: - Initializers
    /// Initializes an `AddressViewController`.
    /// - Note: Make sure you put this in a `UINavigationController` before presenting or pushing it.
    /// - Parameter configuration: The configuration for this `AddressViewController` e.g., to style the appearance.
    /// - Parameter delegate: This is called after the customer completes entering their address or cancels the sheet.
    public convenience init(
        configuration: Configuration,
        delegate: AddressViewControllerDelegate
    ) {
        self.init(addressSpecProvider: .shared, configuration: configuration, delegate: delegate)
    }

    init(
        addressSpecProvider: AddressSpecProvider,
        configuration: Configuration,
        delegate: AddressViewControllerDelegate
    ) {
        self.addressSpecProvider = addressSpecProvider
        self.configuration = configuration
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: closeButton)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Overrides
    override public func viewDidLoad() {
        super.viewDidLoad()
        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: AddressViewController.self)

        view.backgroundColor = configuration.appearance.colors.background
        // Tapping on the background view should dismiss the keyboard
        let hideKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(didTapBackground))
        hideKeyboardGesture.cancelsTouchesInView = false
        hideKeyboardGesture.delegate = self
        view.addGestureRecognizer(hideKeyboardGesture)

        activityIndicator.color = configuration.appearance.colors.background.contrastingColor
        [activityIndicator].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])

        loadSpecsIfNeeded()
        registerForKeyboardNotifications()
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if !didLogAddressShow {
            STPAnalyticsClient.sharedClient.logAddressShow(defaultCountryCode: addressSection?.selectedCountryCode ?? "", apiClient: configuration.apiClient)
            didLogAddressShow = true
        }
        // Ensure we receive dismissal callbacks even when presented modally inside a UINavigationController
        navigationController?.presentationController?.delegate = self
        addressSection?.beginEditing()
    }
}

// MARK: - Keyboard handling
extension AddressViewController {
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func adjustForKeyboard(notification: Notification) {
        guard
            let keyboardScreenEndFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else {
            return
        }

        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        let keyboardInViewHeight = view.safeAreaLayoutGuide.layoutFrame.intersection(keyboardViewEndFrame).height
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollViewBottomConstraint.constant = 0
        } else {
            scrollViewBottomConstraint.constant = -keyboardInViewHeight
        }

        // Animate the scrollView above the keyboard
        view.setNeedsLayout()
        UIView.animateAlongsideKeyboard(notification) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - Internal methods
extension AddressViewController {

    func didContinue() {
        logAddressCompleted()
        delegate?.addressViewControllerDidFinish(self, with: addressDetails)
    }

    @objc func didTapBackground() {
        view.endEditing(false)
    }

    @objc func presentAutocomplete() {
        assert(navigationController != nil)
        let autoCompleteViewController = AutoCompleteViewController(configuration: configuration, initialLine1Text: addressSection?.line1?.text, addressSpecProvider: addressSpecProvider)
        autoCompleteViewController.delegate = self
        navigationController?.pushViewController(autoCompleteViewController, animated: true)
    }

    @objc func didTapCloseButton() {
        didContinue()
    }

    func handleShippingEqualsBillingToggle(isSelected: Bool) {
        if isSelected {
            // Populate with billing address when checked
            if let billingAddress = configuration.billingAddress, isAddressCompatible(billingAddress) {
                populateAddressSection(with: .init(from: billingAddress))
            }
        } else {
            // Always clear when unchecked first
            clearAddressSection()

            // Then optionally populate with shipping address (defaultValues) if they exist and are different from billing
            if !configuration.defaultValues.address.isEmpty && isAddressCompatible(configuration.defaultValues) {
                // Only populate with default values if they're different from billing address
                if let billingAddress = configuration.billingAddress,
                   configuration.defaultValues.address != billingAddress.address {
                    populateAddressSection(with: .init(from: configuration.defaultValues))
                }
            }
        }
    }

    private func populateAddressSection(with addressDetails: AddressSectionElement.AddressDetails) {
        guard let addressSection = addressSection else { return }

        // Set country first as it affects available fields
        if let countryIndex = addressSection.countryCodes.firstIndex(where: { $0 == addressDetails.address.country }) {
            addressSection.country.select(index: countryIndex)
        }

        // Populate address fields
        addressSection.line1?.setText(addressDetails.address.line1 ?? "")
        addressSection.line2?.setText(addressDetails.address.line2 ?? "")
        addressSection.city?.setText(addressDetails.address.city ?? "")
        addressSection.postalCode?.setText(addressDetails.address.postalCode ?? "")
        addressSection.state?.setRawData(addressDetails.address.state ?? "", shouldAutoAdvance: false)

        // Populate name and phone if available
        addressSection.name?.setText(addressDetails.name ?? "")
        if let phone = addressDetails.phone {
            // Check if phone number is in E.164 format and parse it properly
            if let parsedPhone = PhoneNumber.fromE164(phone) {
                // Use parsed country code and local number for E.164 format
                addressSection.phone?.setSelectedCountryCode(parsedPhone.countryCode, shouldUpdateDefaultNumber: false)
                addressSection.phone?.setPhoneNumber(parsedPhone.number)
            } else {
                // Fall back to original logic for non-E.164 numbers
                addressSection.phone?.setPhoneNumber(phone)
                if let phoneCountry = addressDetails.address.country {
                    addressSection.phone?.setSelectedCountryCode(phoneCountry, shouldUpdateDefaultNumber: false)
                }
            }
        }
    }

    private func clearAddressSection() {
        guard let addressSection = addressSection else { return }

        // Clear all text fields
        addressSection.line1?.setText("")
        addressSection.line2?.setText("")
        addressSection.city?.setText("")
        addressSection.postalCode?.setText("")
        addressSection.state?.setRawData("", shouldAutoAdvance: false)
        addressSection.name?.setText("")
        addressSection.phone?.clearPhoneNumber()

        // Reset to default country if needed (first in allowed countries or US)
        let defaultCountryCode = configuration.allowedCountries.first ?? "US"
        if let defaultCountryIndex = addressSection.countryCodes.firstIndex(where: { $0 == defaultCountryCode }) {
            addressSection.country.select(index: defaultCountryIndex)
        }
    }
}

// MARK: - Private methods
extension AddressViewController {
    /// Expands the address section element and begin editing if the current country selection does not support auto complete
    private func expandAddressSectionIfNeeded() {
        // If we're in autocomplete mode and the country is not supported by autocomplete, switch to normal address collection
        if let addressSection = addressSection, addressSection.collectionMode == .autoCompletable,
           !configuration.autocompleteCountries.caseInsensitiveContains(addressSection.selectedCountryCode) {
            addressSection.collectionMode = .all(autocompletableCountries: configuration.autocompleteCountries)
        }
    }

    private func makeDefaultAddressSection() -> AddressSectionElement? {
        guard hasLoadedSpecs else { return nil }

        let defaultValues = compatibleDefaultValues ?? .init()
        let showFullForm = compatibleDefaultValues?.address.line1?.isEmpty == false

        return AddressSectionElement(
            countries: configuration.allowedCountries.isEmpty ? nil : configuration.allowedCountries,
            addressSpecProvider: addressSpecProvider,
            defaults: .init(from: defaultValues),
            collectionMode: showFullForm ? .all(autocompletableCountries: configuration.autocompleteCountries) : .autoCompletable,
            additionalFields: .init(from: configuration.additionalFields),
            theme: configuration.appearance.asElementsTheme,
            presentAutoComplete: { [weak self] in
                self?.presentAutocomplete()
            }
        )
    }

    private func loadUI() {
        self.addressSection = makeDefaultAddressSection()

        let stackView = UIStackView(arrangedSubviews: [headerLabel, formElement.view, errorLabel])
        stackView.directionalLayoutMargins = configuration.appearance.topFormInsets
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical

        [scrollView, stackView, button].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        scrollView.addSubview(button)

        NSLayoutConstraint.activate([
            scrollViewBottomConstraint,
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.frameLayoutGuide.widthAnchor.constraint(equalTo: scrollView.contentLayoutGuide.widthAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: button.topAnchor, constant: -PaymentSheetUI.defaultPadding),

            button.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: configuration.appearance.formInsets.leading),
            button.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -configuration.appearance.formInsets.trailing),
            button.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -configuration.appearance.formInsets.bottom),
        ])
    }

    private func loadSpecsIfNeeded() {
        if addressSpecProvider.countries.isEmpty {
            activityIndicator.startAnimating()

            // Load address specs
            self.addressSpecProvider.loadAddressSpecs {
                DispatchQueue.main.async {
                    self.hasLoadedSpecs = true
                    self.activityIndicator.stopAnimating()
                    self.loadUI()
                }
            }
        } else {
            self.hasLoadedSpecs = true
            self.loadUI()
        }
    }

    private func logAddressCompleted() {
        var editDistance: Int?
        if let selectedAddress = addressDetails?.address, let autoCompleteAddress = selectedAutoCompleteResult {
            editDistance = PaymentSheet.Address(from: selectedAddress).editDistance(from: autoCompleteAddress)
        }

        STPAnalyticsClient.sharedClient.logAddressCompleted(
            addressCountyCode: addressSection?.selectedCountryCode ?? "",
            autoCompleteResultedSelected: selectedAutoCompleteResult != nil,
            editDistance: editDistance,
            apiClient: configuration.apiClient
        )
    }
}

// MARK: - ElementDelegate
 @_spi(STP) extension AddressViewController: ElementDelegate {
     @_spi(STP) public func didUpdate(element: Element) {
         guard let addressSection = addressSection else { assertionFailure(); return }
         self.latestError = nil // clear error on new input
         let enabled = addressSection.validationState.isValid
         button.update(state: enabled ? .enabled : .disabled, animated: true)
         expandAddressSectionIfNeeded()

         // Automatically update the "shipping equals billing" checkbox based on current form state
         updateShippingEqualsBillingCheckboxState()
     }

     @_spi(STP) public func continueToNextField(element: Element) {
        // no-op
    }
}

// MARK: AutoCompleteViewControllerDelegate

extension AddressViewController: AutoCompleteViewControllerDelegate {
    func didSelectManualEntry(_ line1: String) {
        guard let addressSection = addressSection else { assertionFailure(); return }
        navigationController?.popViewController(animated: true)
        addressSection.collectionMode = .all(autocompletableCountries: configuration.autocompleteCountries)
        addressSection.line1?.setText(line1)
    }

    func didSelectAddress(_ address: PaymentSheet.Address?) {
        guard let addressSection = addressSection else { assertionFailure(); return }
        navigationController?.popViewController(animated: true)
        // Disable auto complete after address is selected
        addressSection.collectionMode = .all(autocompletableCountries: configuration.autocompleteCountries)
        guard let address = address else {
            return
        }

        let autocompleteCountryIndex = addressSection.countryCodes.firstIndex(where: { $0 == address.country })

        if let country = address.country, autocompleteCountryIndex == nil {
            // Merchant doesn't support shipping to selected country
            let errorMsg = String.Localized.does_not_support_shipping_to(countryCode: country)
            latestError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
            return
        }

        if let autocompleteCountryIndex = autocompleteCountryIndex {
            addressSection.country.select(index: autocompleteCountryIndex)
        }
        addressSection.line1?.setText(address.line1 ?? "")
        addressSection.city?.setText(address.city ?? "")
        addressSection.postalCode?.setText(address.postalCode ?? "")
        addressSection.state?.setRawData(address.state ?? "", shouldAutoAdvance: false)
        addressSection.state?.view.resignFirstResponder()

        self.selectedAutoCompleteResult = address
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AddressViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view is UIControl) // Without this, the UIControl (e.g. button) doesn't get the touch
    }
}

// MARK: - PaymentSheet <-> AddressSectionElement Helpers
extension AddressSectionElement.AddressDetails {
    init(from addressDetails: AddressViewController.Configuration.DefaultAddressDetails) {
        self.init(
            name: addressDetails.name,
            phone: addressDetails.phone,
            address: .init(
                city: addressDetails.address.city,
                country: addressDetails.address.country,
                line1: addressDetails.address.line1,
                line2: addressDetails.address.line2,
                postalCode: addressDetails.address.postalCode,
                state: addressDetails.address.state
            )
        )
    }
}

extension AddressSectionElement.AdditionalFields {
    init(from additionalFields: AddressViewController.Configuration.AdditionalFields) {
        func config(from fieldConfiguration: AddressViewController.Configuration.AdditionalFields.FieldConfiguration) -> FieldConfiguration {
            switch fieldConfiguration {
            case .hidden:
                return .disabled
            case .optional:
                return .enabled(isOptional: true)
            case .required:
                return .enabled(isOptional: false)
            }
        }

        self.init(
            name: config(from: .required),
            phone: config(from: additionalFields.phone)
        )
    }
}

@_spi(STP) extension AddressViewController: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "PaymentSheet.AddressController"
}

extension AddressViewController {
    /// Updates the checkbox state based on whether the current form matches the billing address
    private func updateShippingEqualsBillingCheckboxState() {
        guard let checkbox = shippingEqualsBillingCheckbox,
              let currentAddressSection = addressSection,
              let billingAddress = configuration.billingAddress else { return }

        // Create a temporary AddressSection with the billing address to get normalized data
        let billingAddressSection = AddressSectionElement(
            countries: configuration.allowedCountries.isEmpty ? nil : configuration.allowedCountries,
            addressSpecProvider: addressSpecProvider,
            defaults: .init(from: billingAddress),
            collectionMode: .all(autocompletableCountries: configuration.autocompleteCountries),
            additionalFields: .init(from: configuration.additionalFields),
            theme: configuration.appearance.asElementsTheme,
            presentAutoComplete: { /* no-op for comparison */ }
        )

        let currentAddressDetails = currentAddressSection.addressDetails
        let normalizedBillingAddressDetails = billingAddressSection.addressDetails

        // Check the checkbox if current form matches normalized billing address, uncheck otherwise
        checkbox.isSelected = (currentAddressDetails == normalizedBillingAddressDetails)
    }
}

extension PaymentSheet.Address {
    var isEmpty: Bool {
        return self == .init()
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension AddressViewController: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        didContinue()
    }
}
