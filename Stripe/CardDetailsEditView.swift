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

class CardDetailsEditView: UIView, CardScanningViewDelegate {
    let paymentMethodType: STPPaymentMethodType = .card
    weak var delegate: ElementDelegate?

    let billingAddressCollection: PaymentSheet.BillingAddressCollectionLevel
    let merchantDisplayName: String

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
        let formView = STPCardFormView(billingAddressCollection: billingAddressCollection, postalCodeRequirement: .upe)
        formView.internalDelegate = self
        return formView
    }()

    lazy var saveThisCardCheckboxView: CheckboxButton = {
        let localized = STPLocalizedString(
            "Save this card for future %@ payments",
            "The label of a switch indicating whether to save the user's card for future payment"
        )
        let saveThisCardCheckbox = CheckboxButton(
            text: String(format: localized, merchantDisplayName)
        )
        saveThisCardCheckbox.isSelected = true
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
        shouldDisplaySaveThisPaymentMethodCheckbox: Bool,
        configuration: PaymentSheet.Configuration
    ) {
        self.billingAddressCollection = configuration.billingAddressCollectionLevel
        self.merchantDisplayName = configuration.merchantDisplayName
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
        saveThisCardCheckboxView.isHidden = !shouldDisplaySaveThisPaymentMethodCheckbox

        let contentView = UIStackView(arrangedSubviews: [
            formView, cardScanningPlaceholderView, saveThisCardCheckboxView,
        ])
        contentView.axis = .vertical
        contentView.alignment = .fill
        contentView.spacing = 4
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
}
// MARK: - Events
/// :nodoc:
extension CardDetailsEditView: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldDisableUserInteraction:
            saveThisCardCheckboxView.isUserInteractionEnabled = false
            formView.isUserInteractionEnabled = false
            saveThisCardCheckboxView.isEnabled = false
        case .shouldEnableUserInteraction:
            saveThisCardCheckboxView.isUserInteractionEnabled = true
            formView.isUserInteractionEnabled = true
            saveThisCardCheckboxView.isEnabled = true
        }
    }
}

/// :nodoc:
extension CardDetailsEditView: STPFormViewInternalDelegate {
    func formView(_ form: STPFormView, didChangeToStateComplete complete: Bool) {
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

// MARK: - Element

/// :nodoc:
extension CardDetailsEditView: PaymentMethodElement {
    func updateParams(params: IntentConfirmParams) -> IntentConfirmParams? {
        if let paymentMethodParams = paymentMethodParams {
            params.paymentMethodParams.card = paymentMethodParams.card
            params.paymentMethodParams.billingDetails = paymentMethodParams.billingDetails
            if !saveThisCardCheckboxView.isHidden {
                params.shouldSavePaymentMethod = saveThisCardCheckboxView.isEnabled && saveThisCardCheckboxView.isSelected
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
