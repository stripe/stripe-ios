//
//  STPCardFormView.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit

class STPCardFormView: STPFormView {

    let numberField: STPCardNumberInputTextField
    let cvcField: STPCardCVCInputTextField
    let expiryField: STPCardExpiryInputTextField

    let billingAddressSubForm: BillingAddressSubForm

    var countryField: STPCountryPickerInputField {
        return billingAddressSubForm.countryPickerField
    }

    var postalCodeField: STPPostalCodeInputTextField {
        return billingAddressSubForm.postalCodeField
    }

    var stateField: STPGenericInputTextField? {
        return billingAddressSubForm.stateField
    }

    var cardParams: STPPaymentMethodParams? {
        get {
            guard case .valid = numberField.validator.validationState,
                let cardNumber = numberField.validator.inputValue,
                case .valid = cvcField.validator.validationState,
                let cvc = cvcField.validator.inputValue,
                case .valid = expiryField.validator.validationState,
                let expiryStrings = expiryField.expiryStrings,
                let monthInt = Int(expiryStrings.month),
                let yearInt = Int(expiryStrings.year),
                let billingDetails = billingAddressSubForm.billingDetails
            else {
                return nil
            }

            let cardParams = STPPaymentMethodCardParams()
            cardParams.number = cardNumber
            cardParams.cvc = cvc
            cardParams.expMonth = NSNumber(value: monthInt)
            cardParams.expYear = NSNumber(value: yearInt)

            return STPPaymentMethodParams(
                card: cardParams, billingDetails: billingDetails, metadata: nil)
        }
        set {
            if let card = newValue?.card {
                if let number = card.number {
                    numberField.text = number
                }
                if let expMonth = card.expMonth, let expYear = card.expYear {
                    let expText = String(
                        format: "%02lu%02lu", Int(truncating: expMonth),
                        Int(truncating: expYear) % 100)
                    expiryField.text = expText
                }
                if let cvc = card.cvc {
                    cvcField.text = cvc
                }
                if let postalCode = newValue?.billingDetails?.address?.postalCode {
                    postalCodeField.text = postalCode
                }
            }
        }
    }

    var countryCode: String? {
        didSet {
            postalCodeField.countryCode = countryCode
            set(
                textField: postalCodeField,
                isHidden: !STPPostalCodeValidator.postalCodeIsRequired(forCountryCode: countryCode),
                animated: window != nil)
            stateField?.placeholder = STPLocalizationUtils.localizedStateString(for: countryCode)
        }
    }

    convenience init(
        billingAddressCollection: PaymentSheet.BillingAddressCollectionLevel = .automatic
    ) {
        self.init(
            numberField: STPCardNumberInputTextField(),
            cvcField: STPCardCVCInputTextField(),
            expiryField: STPCardExpiryInputTextField(),
            billingAddressSubForm: BillingAddressSubForm(
                billingAddressCollection: billingAddressCollection))
    }

    required init(
        numberField: STPCardNumberInputTextField,
        cvcField: STPCardCVCInputTextField,
        expiryField: STPCardExpiryInputTextField,
        billingAddressSubForm: BillingAddressSubForm
    ) {
        self.numberField = numberField
        self.cvcField = cvcField
        self.expiryField = expiryField
        self.billingAddressSubForm = billingAddressSubForm

        var button: UIButton? = nil
        if #available(iOS 13.0, macCatalyst 14.0, *) {
            if STPCardScanner.cardScanningAvailable() {
                let scanButton = UIButton()
                scanButton.setTitle("Scan card", for: .normal)
                scanButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
                scanButton.imageView?.contentMode = .scaleAspectFit
                scanButton.setTitleColor(.systemBlue, for: .normal)
                let fontMetrics = UIFontMetrics(forTextStyle: .body)
                scanButton.titleLabel?.font = fontMetrics.scaledFont(
                    for: UIFont.systemFont(ofSize: 13, weight: .semibold))
                scanButton.setContentHuggingPriority(.defaultLow + 1, for: .horizontal)
                button = scanButton
            }
        }

        let cardParamsSection = STPFormView.Section(
            rows: [
                [numberField],
                [expiryField, cvcField],
            ],
            title: STPLocalizedString("Card information", "Card details entry form header title"),
            accessoryButton: button)

        super.init(sections: [cardParamsSection, billingAddressSubForm.formSection])
        numberField.addObserver(self)
        cvcField.addObserver(self)
        expiryField.addObserver(self)
        billingAddressSubForm.formSection.rows.forEach({ $0.forEach({ $0.addObserver(self) }) })
        button?.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
        countryCode = countryField.inputValue
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(sections: [Section]) {
        fatalError("init(sections:) has not been implemented")
    }

    override func shouldAutoAdvance(
        for input: STPInputTextField, with validationState: STPValidatedInputState,
        from previousState: STPValidatedInputState
    ) -> Bool {
        if input == numberField {
            if case .valid = validationState {
                if case .processing = previousState {
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
        } else if input == postalCodeField {
            if case .valid = validationState {
                if countryCode == "US" {
                    return true
                }
            } else {
                return false
            }
        } else if input == cvcField{
            if case .valid = validationState {
                return (input.validator.inputValue?.count ?? 0) >= STPCardValidator.maxCVCLength(for: cvcField.cardBrand)
            } else {
                return false
            }
        } else if billingAddressSubForm.formSection.contains(input) {
            return false
        }
        return super.shouldAutoAdvance(for: input, with: validationState, from: previousState)
    }

    override func validationDidUpdate(
        to state: STPValidatedInputState, from previousState: STPValidatedInputState,
        for unformattedInput: String?, in input: STPFormInput
    ) {
        guard let textField = input as? STPInputTextField else {
            return
        }

        if textField == numberField {
            cvcField.cardBrand = numberField.cardBrand
        } else if textField == countryField {
            countryCode = countryField.inputValue
        }
        super.validationDidUpdate(
            to: state, from: previousState, for: unformattedInput, in: textField)
        if case .valid = state, state != previousState {
            if cardParams != nil {
                // we transitioned to complete
                delegate?.formView(self, didChangeToStateComplete: true)
            }
        } else if case .valid = previousState, state != previousState {
            delegate?.formView(self, didChangeToStateComplete: false)
        }
    }

    @objc func scanButtonTapped(sender: UIButton) {
        self.delegate?.formView(self, didTapAccessoryButton: sender)
    }

    /// Returns true iff the form can mark the error to one of its fields
    func markFormErrors(for apiError: Error) -> Bool {
        let error = apiError as NSError
        guard let errorCode = error.userInfo[STPError.stripeErrorCodeKey] as? String else {
            return false
        }
        switch errorCode {
        case "incorrect_number", "invalid_number":
            numberField.validator.validationState = .invalid(
                errorMessage: error.userInfo[NSLocalizedDescriptionKey] as? String
                    ?? numberField.validator.defaultErrorMessage)
            return true

        case "invalid_expiry_month", "invalid_expiry_year", "expired_card":
            expiryField.validator.validationState = .invalid(
                errorMessage: error.userInfo[NSLocalizedDescriptionKey] as? String
                    ?? expiryField.validator.defaultErrorMessage)
            return true

        case "invalid_cvc", "incorrect_cvc":
            cvcField.validator.validationState = .invalid(
                errorMessage: error.userInfo[NSLocalizedDescriptionKey] as? String
                    ?? cvcField.validator.defaultErrorMessage)
            return true

        case "incorrect_zip":
            postalCodeField.validator.validationState = .invalid(
                errorMessage: error.userInfo[NSLocalizedDescriptionKey] as? String
                    ?? postalCodeField.validator.defaultErrorMessage)
            return true

        default:
            return false
        }
    }
}

/// :nodoc:
extension STPCardFormView {
    class BillingAddressSubForm: NSObject {
        let formSection: STPFormView.Section

        let postalCodeField: STPPostalCodeInputTextField = STPPostalCodeInputTextField()
        let countryPickerField: STPCountryPickerInputField = STPCountryPickerInputField()
        let stateField: STPGenericInputTextField?

        let line1Field: STPGenericInputTextField?
        let line2Field: STPGenericInputTextField?
        let cityField: STPGenericInputTextField?

        var billingDetails: STPPaymentMethodBillingDetails? {
            let billingDetails = STPPaymentMethodBillingDetails()
            let address = STPPaymentMethodAddress()

            if !postalCodeField.isHidden {
                if case .valid = postalCodeField.validationState {
                    address.postalCode = postalCodeField.postalCode
                } else {
                    return nil
                }
            }

            if case .valid = countryPickerField.validationState {
                address.country = countryPickerField.inputValue
            } else {
                return nil
            }

            if let stateField = stateField {
                if case .valid = stateField.validationState {
                    address.state = stateField.inputValue
                } else {
                    return nil
                }
            }

            if let line1Field = line1Field {
                if case .valid = line1Field.validationState {
                    address.line1 = line1Field.inputValue
                } else {
                    return nil
                }
            }
            if let line2Field = line2Field {
                if case .valid = line2Field.validationState {
                    address.line2 = line2Field.inputValue
                } else {
                    return nil
                }
            }

            if let cityField = cityField {
                if case .valid = cityField.validationState {
                    address.city = cityField.inputValue
                } else {
                    return nil
                }
            }

            billingDetails.address = address
            return billingDetails
        }

        required init(billingAddressCollection: PaymentSheet.BillingAddressCollectionLevel) {
            let rows: [[STPInputTextField]]
            let title: String
            switch billingAddressCollection {

            case .automatic:
                stateField = nil
                line1Field = nil
                line2Field = nil
                cityField = nil
                rows = [
                    [countryPickerField],
                    [postalCodeField],
                ]
                title = STPLocalizedString(
                    "Country or region", "Country selector and postal code entry form header title")

            case .required:
                stateField = STPGenericInputTextField(
                    placeholder: STPLocalizationUtils.localizedStateString(
                        for: Locale.autoupdatingCurrent.regionCode), textContentType: .addressState)
                line1Field = STPGenericInputTextField(
                    placeholder: STPLocalizedString(
                        "Address line 1", "Address line 1 placeholder for billing address form."),
                    textContentType: .streetAddressLine1, keyboardType: .numbersAndPunctuation)
                line2Field = STPGenericInputTextField(
                    placeholder: STPLocalizedString(
                        "Address line 2 (optional)",
                        "Address line 2 placeholder for billing address form."),
                    textContentType: .streetAddressLine2, keyboardType: .numbersAndPunctuation,
                    optional: true)
                cityField = STPGenericInputTextField(
                    placeholder: STPLocalizationUtils.localizedCityString(),
                    textContentType: .addressCity)
                rows = [
                    // Country selector
                    [countryPickerField],
                    // Address line 1
                    [line1Field!],
                    // Address line 2
                    [line2Field!],
                    // City, Postal code
                    [cityField!, postalCodeField],
                    // State
                    [stateField!],
                ]
                title = STPLocalizedString(
                    "Billing address", "Billing address section title for card form entry.")
            }

            formSection = STPFormView.Section(rows: rows, title: title, accessoryButton: nil)
        }

    }
}
