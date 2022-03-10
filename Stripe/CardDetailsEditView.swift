//
//  CardDetailsEditView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/11/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_CardDetailsEditView)
class CardDetailsEditView: UIView, STP_Internal_CardScanningViewDelegate {
    let paymentMethodType: STPPaymentMethodType = .card
    weak var delegate: ElementDelegate?

    let billingAddressCollection: PaymentSheet.BillingAddressCollectionLevel
    let merchantDisplayName: String
    let savePaymentMethodOptInBehavior: PaymentSheet.SavePaymentMethodOptInBehavior

    let checkboxText: String?
    let includeCardScanning: Bool
    let prefillDetails: STPCardFormView.PrefillDetails?
    let inputMode: STPCardNumberInputTextField.InputMode
    let appearance: PaymentSheet.Appearance
    private(set) var hasCompleteDetails: Bool = false
    
    var paymentMethodParams: STPPaymentMethodParams? {
        return formView.cardParams
    }

    var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation {
        didSet {
            if #available(iOS 13.0, macCatalyst 14.0, *) {
                cardScanningView?.deviceOrientation = deviceOrientation
            }
        }
    }

    func setErrorIfNecessary(for apiError: Error) -> Bool {
        return formView.markFormErrors(for: apiError)
    }

    lazy var formView: STPCardFormView = {
        let formView = STPCardFormView(billingAddressCollection: billingAddressCollection,
                                       includeCardScanning: includeCardScanning,
                                       postalCodeRequirement: .upe,
                                       prefillDetails: prefillDetails,
                                       inputMode: inputMode)
        
        formView.formViewInternalDelegate = self
        formView.delegate = self
        return formView
    }()

    lazy var checkboxView: CheckboxButton = {
        let saveThisCardCheckbox = CheckboxButton(
            text: checkboxText ?? "",
            appearance: appearance
        )
        saveThisCardCheckbox.isSelected = false
        return saveThisCardCheckbox
    }()

    // Card scanning
    @available(iOS 13, macCatalyst 14, *)
    func cardScanningView(
        _ cardScanningView: CardScanningView, didFinishWith cardParams: STPPaymentMethodCardParams?
    ) {
        if let button = self.lastScanButton {
            button.isUserInteractionEnabled = true
        }
        UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
            self.cardScanningView?.isHidden = true
            self.cardScanningView?.alpha = 0
            if let button = self.lastScanButton {
                button.alpha = 1
            }
        }

        if let params = cardParams {
            self.formView.cardParams = STPPaymentMethodParams.init(
                card: params, billingDetails: nil, metadata: nil)
            let _ = self.formView.nextFirstResponderField()?.becomeFirstResponder()
        }
    }

    @available(iOS 13, macCatalyst 14, *)
    lazy var cardScanningView: CardScanningView? = {
        if !STPCardScanner.cardScanningAvailable() {
            return nil  // Don't initialize the scanner
        }
        let scanningView = CardScanningView()
        scanningView.alpha = 0
        scanningView.isHidden = true
        return scanningView
    }()

    weak var lastScanButton: UIButton?
    @objc func scanButtonTapped(_ button: UIButton) {
        if #available(iOS 13.0, macCatalyst 14.0, *) {
            lastScanButton = button
            if let cardScanningView = cardScanningView {
                button.isUserInteractionEnabled = false
                UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration) {
                    button.alpha = 0
                    cardScanningView.isHidden = false
                    cardScanningView.alpha = 1
                }
                self.endEditing(true)
                cardScanningView.start()
            }
        }
    }

    init(
        checkboxText: String?,
        includeCardScanning: Bool,
        prefillDetails: STPCardFormView.PrefillDetails? = nil,
        inputMode: STPCardNumberInputTextField.InputMode = .standard,
        configuration: PaymentSheet.Configuration
    ) {
        self.billingAddressCollection = configuration.billingAddressCollectionLevel
        self.merchantDisplayName = configuration.merchantDisplayName
        self.savePaymentMethodOptInBehavior = configuration.savePaymentMethodOptInBehavior
        self.checkboxText = checkboxText
        self.includeCardScanning = includeCardScanning
        self.inputMode = inputMode
        self.prefillDetails = prefillDetails
        self.appearance = configuration.appearance
        
        super.init(frame: .zero)
        
        // Hack to set default postal code and country value
        if let ds = formView.countryField.dataSource as? STPCountryPickerInputField.CountryPickerDataSource,
           let countryIndex = ds.countries.firstIndex(where: {
               $0.code == configuration.defaultBillingDetails.address.country
           }) {
            formView.countryField.pickerView.selectRow(countryIndex, inComponent: 0, animated: false)
            formView.countryField.updateValue()
        }
        formView.postalCodeField.text = configuration.defaultBillingDetails.address.postalCode

        var cardScanningPlaceholderView = UIView()
        // Card scanning button
        if #available(iOS 13.0, macCatalyst 14.0, *) {
            if let cardScanningView = self.cardScanningView {
                cardScanningView.delegate = self
                cardScanningPlaceholderView = cardScanningView
            }
        }
        cardScanningPlaceholderView.isHidden = true

        // [] Save this card
        checkboxView.isHidden = !(checkboxText != nil)
        updateDefaultCheckboxStateIfNeeded()

        let contentView = UIStackView(arrangedSubviews: [
            formView, cardScanningPlaceholderView, checkboxView,
        ])
        contentView.axis = .vertical
        contentView.alignment = .fill
        contentView.spacing = 4
        contentView.distribution = .equalSpacing
        contentView.setCustomSpacing(8, after: formView)
        contentView.setCustomSpacing(16, after: cardScanningPlaceholderView)

        [contentView].forEach({
            addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            formView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    override var isUserInteractionEnabled: Bool {
        didSet {
            formView.isUserInteractionEnabled = isUserInteractionEnabled
        }
    }
    
    func updateDefaultCheckboxStateIfNeeded() {
        guard !checkboxView.hasReceivedTap else {
            return // Don't override what a user has already set
        }
        switch savePaymentMethodOptInBehavior {
            
        case .automatic:
            // only enable the save checkbox by default for US
            checkboxView.isSelected = formView.countryCode?.isUSCountryCode() ?? false

        case .requiresOptIn:
            checkboxView.isSelected = false
            
        case .requiresOptOut:
            checkboxView.isSelected = true
        }
    }
}
// MARK: - Events
/// :nodoc:
extension CardDetailsEditView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldDisableUserInteraction:
            checkboxView.isUserInteractionEnabled = false
            formView.isUserInteractionEnabled = false
            checkboxView.isEnabled = false
        case .shouldEnableUserInteraction:
            checkboxView.isUserInteractionEnabled = true
            formView.isUserInteractionEnabled = true
            checkboxView.isEnabled = true
        }
    }
}

/// :nodoc:
extension CardDetailsEditView: STPFormViewInternalDelegate {
    func formView(_ form: STPFormView, didChangeToStateComplete complete: Bool) {
        self.hasCompleteDetails = complete
        delegate?.didUpdate(element: self)
    }

    func formViewWillBecomeFirstResponder(_ form: STPFormView) {
        if #available(iOS 13, macCatalyst 14, *) {
            cardScanningView?.stop()
        }
    }

    func formView(_ form: STPFormView, didTapAccessoryButton button: UIButton) {
        self.scanButtonTapped(button)
    }
}

// MARK: - STPCardFormViewDelegate
/// :nodoc:
extension CardDetailsEditView: STPCardFormViewDelegate {
    func cardFormView(_ form: STPCardFormView, didChangeToStateComplete complete: Bool) {
        delegate?.didUpdate(element: self)
    }
}

// MARK: - STPCardFormViewInternalDelegate
/// :nodoc:
extension CardDetailsEditView: STPCardFormViewInternalDelegate {
    func cardFormView(_ form: STPCardFormView, didUpdateSelectedCountry countryCode: String?) {
        updateDefaultCheckboxStateIfNeeded()
    }
}

// MARK: - Element

/// :nodoc:
extension CardDetailsEditView: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if let paymentMethodParams = paymentMethodParams {
            params.paymentMethodParams.card = paymentMethodParams.card
            params.paymentMethodParams.billingDetails = paymentMethodParams.billingDetails
            if !checkboxView.isHidden {
                params.shouldSavePaymentMethod = checkboxView.isEnabled && checkboxView.isSelected
            }
            return params
        } else {
            return nil
        }
    }

    var view: UIView {
        return self
    }
}
