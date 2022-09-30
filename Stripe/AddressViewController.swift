//
//  AddressViewController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// 🏗 Under construction
/// A delegate for `AddressViewController`
@_spi(STP) public protocol AddressViewControllerDelegate: AnyObject {
    /// Called when the customer finishes entering their address or cancels. Your implemententation should dismiss the view controller.
    /// - Parameter address: A valid address or nil if the customer cancels the flow.
    func addressViewControllerDidFinish(_ addressViewController: AddressViewController, with address: AddressViewController.AddressDetails?)
}

/// 🏗 Under construction
/// A view controller that collects a name and an address, with full localization and autocomplete.
/// - Note: It uses `navigationItem` and can push a view controller, so it must be shown inside a `UINavigationController`.
@objc(STP_Internal_AddressViewController)
@_spi(STP) public class AddressViewController: UIViewController {
    // MARK: - Public properties
    /// Configuration containing e.g. appearance styling properties, default values, etc.
    public let configuration: Configuration
    /// A valid address or nil.
    public var addressDetails: AddressDetails? {
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
            state: addressSection.validationState.isValid ? .enabled : .disabled,
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
        return UIScrollView()
    }()
    lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel(theme: configuration.appearance.asElementsTheme)
        label.isHidden = true
        return label
    }()

    // MARK: - Elements
    lazy var formElement: FormElement = {
        let formElement = FormElement(elements: [addressSection, checkboxElement], theme: configuration.appearance.asElementsTheme)
        formElement.delegate = self
        return formElement
    }()
    lazy var addressSection: AddressSectionElement = {
        let additionalFields = configuration.additionalFields
        let defaultValues = configuration.defaultValues
        let allowedCountries = configuration.allowedCountries
        let address = AddressSectionElement(
            countries: allowedCountries.isEmpty ? nil : allowedCountries,
            addressSpecProvider: addressSpecProvider,
            defaults: .init(from: defaultValues),
            collectionMode: configuration.defaultValues.address != .init() ? .all : .autoCompletable,
            additionalFields: .init(from: additionalFields),
            theme: configuration.appearance.asElementsTheme
        )
        return address
    }()
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
    fileprivate lazy var closeButton: UIButton = {
        let button = SheetNavigationButton.makeCloseButton(appearance: configuration.appearance)
        button.addTarget(self, action: #selector(didTapCloseButton), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Initializers
    /// Initializes an `AddressViewController`.
    /// - Note: Make sure you put this in a `UINavigationController` before presenting or pushing it.
    /// - Parameter configuration: The configuration for this `AddressViewController` e.g., to style the appearance.
    /// - Parameter delegate: This is called after the customer completes entering their address or cancels the sheet.
    @_spi(STP) public convenience init(
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

        let stackView = UIStackView(arrangedSubviews: [headerLabel, formElement.view, errorLabel])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
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
            
            button.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: PaymentSheetUI.defaultSheetMargins.leading),
            button.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -PaymentSheetUI.defaultSheetMargins.leading),
            button.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -PaymentSheetUI.defaultSheetMargins.bottom),
        ])
    }
    
    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerForKeyboardNotifications()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        addressSection.beginEditing()
        if !didLogAddressShow {
            STPAnalyticsClient.sharedClient.logAddressShow(defaultCountryCode: addressSection.selectedCountryCode, apiClient: configuration.apiClient)
            didLogAddressShow = true
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Keyboard handling
extension AddressViewController {
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
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
    private func logAddressCompleted() {
        var editDistance: Int? = nil
        if let selectedAddress = addressDetails?.address, let autoCompleteAddress = selectedAutoCompleteResult {
            editDistance = PaymentSheet.Address(from: selectedAddress).editDistance(from: autoCompleteAddress)
        }
        
        STPAnalyticsClient.sharedClient.logAddressCompleted(
            addressCountyCode: addressSection.selectedCountryCode,
            autoCompleteResultedSelected: selectedAutoCompleteResult != nil,
            editDistance: editDistance,
            apiClient: configuration.apiClient
        )
    }
    
    func didContinue() {
        logAddressCompleted()
        delegate?.addressViewControllerDidFinish(self, with: addressDetails)
    }
    
    @objc func didTapBackground() {
        view.endEditing(false)
    }
    
    @objc func didTapAutoCompleteLine() {
        assert(navigationController != nil)
        let autoCompleteViewController = AutoCompleteViewController(configuration: configuration)
        autoCompleteViewController.delegate = self
        navigationController?.pushViewController(autoCompleteViewController, animated: true)
    }
    
    @objc func didTapCloseButton() {
        delegate?.addressViewControllerDidFinish(self, with: addressDetails)
    }
}

// MARK: - Private methods
extension AddressViewController {
    /// Expands the address section element and begin editing if the current country selection does not support auto copmlete
    private func expandAddressSectionIfNeeded() {
        // If we're in autocomplete mode and the country is not supported by autocomplete, switch to normal address collection
        if addressSection.collectionMode == .autoCompletable,
            !AutoCompleteConstants.supportedCountries.contains(addressSection.selectedCountryCode) {
            addressSection.collectionMode = .all
        }
    }
}

// MARK: - ElementDelegate
 extension AddressViewController: ElementDelegate {
     @_spi(STP) public func didUpdate(element: Element) {
         self.latestError = nil // clear error on new input
         let enabled = addressSection.validationState.isValid
         button.update(state: enabled ? .enabled : .disabled, animated: true)
         addressSection.autoCompleteLine?.didTap = { [weak self] in
             self?.didTapAutoCompleteLine()
         }
         expandAddressSectionIfNeeded()
     }
     
     @_spi(STP) public func continueToNextField(element: Element) {
        // no-op
    }
}

// MARK: AutoCompleteViewControllerDelegate

extension AddressViewController: AutoCompleteViewControllerDelegate {
    func didSelectManualEntry(_ line1: String) {
        navigationController?.popViewController(animated: true)
        addressSection.collectionMode = .all
        addressSection.line1?.setText(line1)
    }
    
    func didSelectAddress(_ address: PaymentSheet.Address?) {
        navigationController?.popViewController(animated: true)
        // Disable auto complete after address is selected
        addressSection.collectionMode = .all
        guard let address = address else {
            return
        }

        let autocompleteCountryIndex = addressSection.countryCodes.firstIndex(where: {$0 == address.country})
        
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
        addressSection.state?.setRawData(address.state ?? "")
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
            name: config(from: additionalFields.name),
            phone: config(from: additionalFields.phone)
        )
    }
}

@_spi(STP) extension AddressViewController: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "PaymentSheet.AddressController"
}
