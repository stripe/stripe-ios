//
//  ShippingAddressViewController.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/24/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

protocol ShippingAddressViewControllerDelegate: AnyObject {
    func shouldClose(_ viewController: ShippingAddressViewController)
}

@objc(STP_Internal_ShippingAddressViewController)
class ShippingAddressViewController: UIViewController {
    let configuration: PaymentSheet.Configuration
    let addressSpecProvider: AddressSpecProvider
    weak var delegate: ShippingAddressViewControllerDelegate?
    /// Always a valid address or nil.
    var shippingAddressDetails: PaymentSheet.ShippingAddressDetails? {
        let a = addressSection
        guard case .valid = a.validationState else {
            return nil
        }
        let address = PaymentSheet.Address(
            city: a.city?.text.nonEmpty,
            country: a.selectedCountryCode,
            line1: a.line1?.text.nonEmpty,
            line2: a.line2?.text.nonEmpty,
            postalCode: a.postalCode?.text.nonEmpty,
            state: a.state?.text.nonEmpty
        )
        return .init(
            address: address,
            name: a.name?.text.nonEmpty,
            phone: a.phone?.phoneNumber?.string(as: .e164).nonEmpty
        )
    }
    
    private lazy var shouldDisplayAutoComplete: Bool = {
        // Only display auto complete if defaults are empty
        return AddressSectionElement.Defaults(from: configuration.shippingAddress.defaultValues) == .empty
    }()
    
    private var latestError: Error? {
        didSet {
            errorLabel.text = latestError?.localizedDescription
            errorLabel.isHidden = latestError == nil
        }
    }
    
    // MARK: - Views
    lazy var navigationBar: SheetNavigationBar = {
        let navBar = SheetNavigationBar(
            isTestMode: configuration.apiClient.isTestmode,
            appearance: configuration.appearance
        )
        navBar.delegate = self
        return navBar
    }()
    lazy var button: ConfirmButton = {
        let button = ConfirmButton(
            state: addressSection.validationState.isValid ? .enabled : .disabled,
            callToAction: .custom(title: .Localized.continue),
            appearance: configuration.appearance
        ) { [weak self] in
            self?.didContinue()
        }
        return button
    }()
    private lazy var headerLabel: UILabel = {
        let header = PaymentSheetUI.makeHeaderLabel(appearance: configuration.appearance)
        header.text = .Localized.shipping_address
        return header
    }()
    lazy var formView: UIView = {
        return formElement.view
    }()
    lazy var errorLabel: UILabel = {
        let label = ElementsUI.makeErrorLabel()
        label.isHidden = true
        return label
    }()
    
    // MARK: - Elements
    lazy var formElement: FormElement = {
        let formElement = FormElement(elements: [addressSection])
        formElement.delegate = self
        return formElement
    }()
    lazy var addressSection: AddressSectionElement = {
        let additionalFields = configuration.shippingAddress.additionalFields
        let defaultValues = configuration.shippingAddress.defaultValues
        let allowedCountries = configuration.shippingAddress.allowedCountries
        let address = AddressSectionElement(
            countries: allowedCountries.isEmpty ? nil : allowedCountries,
            addressSpecProvider: addressSpecProvider,
            defaults: .init(from: defaultValues),
            additionalFields: .init(from: additionalFields)
        )
        return address
    }()
    
    // MARK: - Initializers
    required init(
        addressSpecProvider: AddressSpecProvider = .shared,
        configuration: PaymentSheet.Configuration,
        delegate: ShippingAddressViewControllerDelegate
    ) {
        self.addressSpecProvider = addressSpecProvider
        self.configuration = configuration
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        
        // Set the current elements theme
        ElementsUITheme.current = configuration.appearance.asElementsTheme
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = configuration.appearance.colors.background
        
        let stackView = UIStackView(arrangedSubviews: [headerLabel, formView, errorLabel, button])
        stackView.directionalLayoutMargins = PaymentSheetUI.defaultMargins
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.spacing = PaymentSheetUI.defaultPadding
        stackView.axis = .vertical

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
        
    }
}

// MARK: - Internal methods
extension ShippingAddressViewController {
    func didContinue() {
        delegate?.shouldClose(self)
    }
}

// MARK: - Private methods
@available(iOSApplicationExtension, unavailable)
extension ShippingAddressViewController {
    private func displayAutoCompleteIfNeeded() {
        // Only display auto complete if we haven't yet and line 1 is editing
        guard shouldDisplayAutoComplete, (addressSection.line1?.isEditing ?? false) else {
            return
        }
        
        // Only display auto complete if current country selected is enabled for auto complete
        guard AutoCompleteConstants.supportedCountries.contains(addressSection.selectedCountryCode) else {
            return
        }
        
        let autoCompleteViewController = AutoCompleteViewController(configuration: configuration)
        autoCompleteViewController.delegate = self
        
        let sheet = BottomSheetViewController(
            contentViewController: autoCompleteViewController,
            appearance: configuration.appearance,
            isTestMode: configuration.apiClient.isTestmode,
            didCancelNative3DS2: {
                // TODO(MOBILESDK-864): Refactor this out.
            }
        )
        
        // Workaround to silence a warning in the Catalyst target
        #if targetEnvironment(macCatalyst)
        self.configuration.style.configure(sheet)
        #else
        if #available(iOS 13.0, *) {
            self.configuration.style.configure(sheet)
        }
        #endif

        self.presentPanModal(sheet, appearance: configuration.appearance)
        shouldDisplayAutoComplete = false
    }
}

// MARK: - SheetNavigationBarDelegate
extension ShippingAddressViewController: SheetNavigationBarDelegate {
    func sheetNavigationBarDidClose(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.shouldClose(self)
    }
    
    func sheetNavigationBarDidBack(_ sheetNavigationBar: SheetNavigationBar) {
        delegate?.shouldClose(self)
    }
}

// MARK: - BottomSheetContentViewController
extension ShippingAddressViewController: BottomSheetContentViewController {
    var requiresFullScreen: Bool {
        false
    }
    
    func didTapOrSwipeToDismiss() {
        delegate?.shouldClose(self)
    }
}

// MARK: - ElementDelegate
@available(iOSApplicationExtension, unavailable)
extension ShippingAddressViewController: ElementDelegate {
    func didUpdate(element: Element) {
        self.latestError = nil // clear error on new input
        let enabled = addressSection.validationState.isValid
        button.update(state: enabled ? .enabled : .disabled, animated: true)
        displayAutoCompleteIfNeeded()
    }
    
    func continueToNextField(element: Element) {
        // no-op
    }
}

extension ShippingAddressViewController: AutoCompleteViewControllerDelegate {
    func didDismiss(with address: PaymentSheet.Address?) {
        guard let address = address else {
            return
        }
        
        guard let selectedCountryIndex = addressSection.country.items.firstIndex(where: {$0.pickerDisplayName == address.country}) else {
            // Merchant doesn't support shipping to selected country
            if let country = address.country {
                let errorMsg = String.Localized.does_not_support_shipping_to(merchantDisplayName: configuration.merchantDisplayName,
                                                                             country: country)
                latestError = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMsg])
                shouldDisplayAutoComplete = true // re-enable auto complete after this error
            }
            
            return
        }
        
        addressSection.country.select(index: selectedCountryIndex)
        addressSection.line1?.setText(address.line1 ?? "")
        addressSection.city?.setText(address.city ?? "")
        addressSection.postalCode?.setText(address.postalCode ?? "")
        addressSection.state?.setText(address.state ?? "")

        addressSection.line1?.endEditing(false, continueToNextField: false)
    }

}

// MARK: - PaymentSheet <-> AddressSectionElement Helpers
extension AddressSectionElement.Defaults {
    init(from shippingAddressDetails: PaymentSheet.ShippingAddressDetails) {
        self.init(
            name: shippingAddressDetails.name,
            phone: shippingAddressDetails.phone,
            city: shippingAddressDetails.address.city,
            country: shippingAddressDetails.address.country,
            line1: shippingAddressDetails.address.line1,
            line2: shippingAddressDetails.address.line2,
            postalCode: shippingAddressDetails.address.postalCode,
            state: shippingAddressDetails.address.state
        )
    }
}

extension AddressSectionElement.AdditionalFields {
    init(from additionalFields: PaymentSheet.ShippingAddressConfiguration.AdditionalFields) {
        func config(from fieldConfiguration: PaymentSheet.ShippingAddressConfiguration.AdditionalFields.FieldConfiguration) -> FieldConfiguration {
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
