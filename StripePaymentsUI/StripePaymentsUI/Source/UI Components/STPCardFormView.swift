//
//  STPCardFormView.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

/// Options for configuring the display of an `STPCardFormView` instance.
@objc
public enum STPCardFormViewStyle: Int {
    /// Draws the form in a rounded rect with full separators between
    /// each input field.
    case standard

    /// Draws the form without an outer border and underlines under
    /// each input field.
    case borderless
}

/// `STPCardFormViewDelegate` defines the interface that should be adopted to receive
/// updates from `STPCardFormView` instances.
@objc
public protocol STPCardFormViewDelegate: NSObjectProtocol {
    /// Delegate method that is called when all of the form view's required inputs
    /// are complete or transition away from all being complete. These transitions
    /// correspond to `cardForView.cardParams` returning a nil value or not.
    func cardFormView(_ form: STPCardFormView, didChangeToStateComplete complete: Bool)
}

/// Internal only delegate methods for STPCardFormView
@_spi(STP) public protocol STPCardFormViewInternalDelegate {
    /// Delegate method that is called when the selected country is changed.
    func cardFormView(_ form: STPCardFormView, didUpdateSelectedCountry countryCode: String?)
}

/// `STPCardFormView` provides a multiline interface for users to input their
/// credit card details as well as billing postal code and provides an interface to access
/// the created `STPPaymentMethodParams`.
/// `STPCardFormView` includes both the input fields as well as an error label that
/// is displayed when invalid input is detected.
public class STPCardFormView: STPFormView {

    let numberField: STPCardNumberInputTextField
    let cvcField: STPCardCVCInputTextField
    let expiryField: STPCardExpiryInputTextField

    let billingAddressSubForm: BillingAddressSubForm
    let postalCodeRequirement: STPPostalCodeRequirement
    let inputMode: STPCardNumberInputTextField.InputMode

    @_spi(STP) public var countryField: STPCountryPickerInputField {
        return billingAddressSubForm.countryPickerField
    }

    @_spi(STP) public var postalCodeField: STPPostalCodeInputTextField {
        return billingAddressSubForm.postalCodeField
    }

    var stateField: STPGenericInputTextField? {
        return billingAddressSubForm.stateField
    }

    @_spi(STP) public var countryCode: String? {
        didSet {
            updateCountryCodeValues()
        }
    }

    private func updateCountryCodeValues() {
        postalCodeField.countryCode = countryCode
        set(
            textField: postalCodeField,
            isHidden: !STPPostalCodeValidator.postalCodeIsRequired(
                forCountryCode: countryCode,
                with: postalCodeRequirement
            ),
            animated: window != nil
        )
        stateField?.placeholder = StripeSharedStrings.localizedStateString(for: countryCode)
    }

    var hideShadow: Bool = false {
        didSet {
            sectionViews.forEach { (sectionView) in
                sectionView.stackView.hideShadow = hideShadow
            }
        }
    }

    /// The delegate to notify when the card form transitions to or from being complete.
    /// - seealso: STPCardFormViewDelegate
    @objc
    public weak var delegate: STPCardFormViewDelegate?

    internal var internalDelegate: STPCardFormViewInternalDelegate? {
        return delegate as? STPCardFormViewInternalDelegate
    }

    var _backgroundColor: UIColor?

    /// :nodoc:
    @objc
    public override var backgroundColor: UIColor? {
        get {
            switch style {

            case .standard:
                return sectionViews.first?.stackView.customBackgroundColor

            case .borderless:
                return _backgroundColor

            }
        }
        set {
            switch style {

            case .standard:
                super.backgroundColor = nil
                sectionViews.forEach({ $0.stackView.customBackgroundColor = newValue })

            case .borderless:
                _backgroundColor = newValue
                super.backgroundColor = backgroundColor

            }
        }
    }

    var _disabledBackgroundColor: UIColor?

    /// The background color that is automatically applied to the input fields when  `isUserInteractionEnabled` is set to `false.
    /// @note `STPCardFormView` uses text colors, most of which are iOS system colors, that are designed to be as
    /// accessible as possible, so any customization should avoid decreasing contrast between the text and background.
    @objc
    public var disabledBackgroundColor: UIColor? {
        get {
            switch style {

            case .standard:
                return sectionViews.first?.stackView.customBackgroundDisabledColor

            case .borderless:
                return _disabledBackgroundColor

            }
        }
        set {
            switch style {

            case .standard:
                sectionViews.forEach({ $0.stackView.customBackgroundDisabledColor = newValue })

            case .borderless:
                _disabledBackgroundColor = disabledBackgroundColor
            }
        }
    }

    /// A configured `STPPaymentMethodParams` with the entered card number, expiration date, cvc, and
    /// postal code (if applicable). If any field is invalid or incomplete then this property will return `nil`.
    /// You can monitor when `STPCardFormView` has complete details by implementing
    /// `STPFormViewDelegate` and setting the `STPCardFormView's` `delegate`
    /// property.
    @objc
    public internal(set) var cardParams: STPPaymentMethodParams? {
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

            if let bindedPaymentMethodParams = _bindedPaymentMethodParams {
                updateBindedPaymentMethodParams()
                return bindedPaymentMethodParams
            }

            let cardParams = STPPaymentMethodCardParams()
            cardParams.number = cardNumber
            cardParams.cvc = cvc
            cardParams.expMonth = NSNumber(value: monthInt)
            cardParams.expYear = NSNumber(value: yearInt)

            // If CBC is enabled, set the selected card brand
            if let cardValidator = (numberField.validator as? STPCardNumberInputTextFieldValidator),
                let selectedBrand = cardValidator.cbcController.selectedBrand {
                cardParams.networks = STPPaymentMethodCardNetworksParams(preferred: STPCardBrandUtilities.apiValue(from: selectedBrand))
            }

            return STPPaymentMethodParams(
                card: cardParams,
                billingDetails: billingDetails,
                metadata: nil
            )
        }
        set {
            if let card = newValue?.card {
                if let number = card.number {
                    numberField.text = number
                }
                if let expMonth = card.expMonth, let expYear = card.expYear {
                    let expText = String(
                        format: "%02lu%02lu",
                        Int(truncating: expMonth),
                        Int(truncating: expYear) % 100
                    )
                    expiryField.text = expText
                }
                if let cvc = card.cvc {
                    cvcField.text = cvc
                }
                // If a card brand is explicitly selected, retain that information
                if let preferredBrandString = card.networks?.preferred,
                   let cardValidator = (numberField.validator as? STPCardNumberInputTextFieldValidator)
                    {
                    cardValidator.cbcController.selectedBrand = STPCard.brand(from: preferredBrandString)
                }
            }

            billingAddressSubForm.billingDetails = newValue?.billingDetails
            // MUST be called after setting field values
            _bindedPaymentMethodParams = newValue
        }
    }

    @_spi(STP) public func _stpinternal_setCardParams(_ params: STPPaymentMethodParams?) {
        self.cardParams = params
    }

    var _bindedPaymentMethodParams: STPPaymentMethodParams? {
        didSet {
            updateBindedPaymentMethodParams()
        }
    }

    func updateBindedPaymentMethodParams() {
        guard let bindedPaymentMethodParams = _bindedPaymentMethodParams else {
            return
        }

        let cardParams = bindedPaymentMethodParams.card ?? STPPaymentMethodCardParams()
        bindedPaymentMethodParams.card = cardParams
        cardParams.number = numberField.inputValue
        cardParams.cvc = cvcField.inputValue
        if let expiryStrings = expiryField.expiryStrings,
            let monthInt = Int(expiryStrings.month),
            let yearInt = Int(expiryStrings.year)
        {
            cardParams.expMonth = NSNumber(value: monthInt)
            cardParams.expYear = NSNumber(value: yearInt)
        } else {
            cardParams.expMonth = nil
            cardParams.expYear = nil
        }

        let billingDetails =
            bindedPaymentMethodParams.billingDetails ?? STPPaymentMethodBillingDetails()
        bindedPaymentMethodParams.billingDetails = billingDetails
        billingAddressSubForm.updateBindedBillingDetails(billingDetails)
    }

    func updateCurrentBackgroundColor() {
        switch style {

        case .standard:
            break  // no-op, switching background color is handled at the section view layer

        case .borderless:
            // if there's a backgroundColor set but no disabledBackgroundColor
            // assume no color change for disabled state
            super.backgroundColor =
                isUserInteractionEnabled
                ? backgroundColor : (disabledBackgroundColor ?? backgroundColor)
        }
    }

    @objc
    public override var isUserInteractionEnabled: Bool {
        didSet {
            updateCurrentBackgroundColor()
            if inputMode == .panLocked {
                self.numberField.isUserInteractionEnabled = false
            }
        }
    }

    let style: STPCardFormViewStyle

    /// Public initializer for `STPCardFormView`.
    /// @param style The visual style to use for this instance. @see STPCardFormViewStyle
    @objc
    public convenience init(
        style: STPCardFormViewStyle = .standard
    ) {
        self.init(
            billingAddressCollection: .automatic,
            style: style,
            prefillDetails: nil
        )
    }

    @_spi(STP) public convenience init(
        billingAddressCollection: BillingAddressCollectionLevel,
        style: STPCardFormViewStyle = .standard,
        postalCodeRequirement: STPPostalCodeRequirement = .standard,
        prefillDetails: PrefillDetails? = nil,
        inputMode: STPCardNumberInputTextField.InputMode = .standard,
        cbcEnabledOverride: Bool? = nil
    ) {
        self.init(
            numberField: STPCardNumberInputTextField(
                inputMode: inputMode,
                prefillDetails: prefillDetails,
                cbcEnabledOverride: cbcEnabledOverride
            ),
            cvcField: STPCardCVCInputTextField(prefillDetails: prefillDetails),
            expiryField: STPCardExpiryInputTextField(prefillDetails: prefillDetails),
            billingAddressSubForm: BillingAddressSubForm(
                billingAddressCollection: billingAddressCollection,
                postalCodeRequirement: postalCodeRequirement
            ),
            style: style,
            postalCodeRequirement: postalCodeRequirement,
            prefillDetails: prefillDetails,
            inputMode: inputMode
        )
    }

    required init(
        numberField: STPCardNumberInputTextField,
        cvcField: STPCardCVCInputTextField,
        expiryField: STPCardExpiryInputTextField,
        billingAddressSubForm: BillingAddressSubForm,
        style: STPCardFormViewStyle = .standard,
        postalCodeRequirement: STPPostalCodeRequirement = .standard,
        prefillDetails: PrefillDetails? = nil,
        inputMode: STPCardNumberInputTextField.InputMode = .standard
    ) {
        self.numberField = numberField
        self.cvcField = cvcField
        self.expiryField = expiryField
        self.billingAddressSubForm = billingAddressSubForm
        self.style = style
        self.postalCodeRequirement = postalCodeRequirement
        self.inputMode = inputMode

        if inputMode == .panLocked {
            self.numberField.isUserInteractionEnabled = false
        }

        var rows: [[STPFormInput]] = [
            [numberField],
            [expiryField, cvcField],
        ]
        rows.append(contentsOf: billingAddressSubForm.formSection.rows)

        let cardParamsSection = STPFormView.Section(
            rows: rows,
            title: nil,
            accessoryButton: nil
        )

        super.init(
            sections: [cardParamsSection]
        )
        numberField.addObserver(self)
        cvcField.addObserver(self)
        expiryField.addObserver(self)
        billingAddressSubForm.formSection.rows.forEach({ $0.forEach({ $0.addObserver(self) }) })
        countryCode = countryField.inputValue
        updateCountryCodeValues()

        switch style {

        case .standard:
            break

        case .borderless:
            sectionViews.forEach { (sectionView) in
                sectionView.stackView.separatorStyle = .partial
                sectionView.stackView.drawBorder = false
                sectionView.insetFooterLabel = true
            }
        }

        hideShadow = true
        // manually call the didSet behavior of hideShadow since that's not triggered in initializers
        sectionViews.forEach { (sectionView) in
            sectionView.stackView.hideShadow = hideShadow
            // remove default background coloring
            sectionView.stackView.customBackgroundColor = nil
        }

        STPAnalyticsClient.sharedClient.addClass(toProductUsageIfNecessary: STPCardFormView.self)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(
        sections: [Section]
    ) {
        fatalError("init(sections:) has not been implemented")
    }

    override func shouldAutoAdvance(
        for input: STPInputTextField,
        with validationState: STPValidatedInputState,
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
        } else if input == cvcField {
            if case .valid = validationState {
                return (input.validator.inputValue?.count ?? 0)
                    >= STPCardValidator.maxCVCLength(for: cvcField.cardBrand)
            } else {
                return false
            }
        } else if billingAddressSubForm.formSection.contains(input) {
            return false
        }
        return super.shouldAutoAdvance(for: input, with: validationState, from: previousState)
    }

    override func validationDidUpdate(
        to state: STPValidatedInputState,
        from previousState: STPValidatedInputState,
        for unformattedInput: String?,
        in input: STPFormInput
    ) {
        guard let textField = input as? STPInputTextField else {
            return
        }

        if textField == numberField {
            cvcField.cardBrand = numberField.brandForCVC
        } else if textField == countryField {
            let countryChanged = textField.inputValue != countryCode

            countryCode = countryField.inputValue

            let shouldFocusOnPostalCode =
                countryChanged
                && STPPostalCodeValidator.postalCodeIsRequired(
                    forCountryCode: countryCode,
                    with: postalCodeRequirement
                )

            if shouldFocusOnPostalCode {
                _ = postalCodeField.becomeFirstResponder()
            }

            if countryChanged {
                self.internalDelegate?.cardFormView(self, didUpdateSelectedCountry: countryCode)
            }
        }
        super.validationDidUpdate(
            to: state,
            from: previousState,
            for: unformattedInput,
            in: textField
        )
        if case .valid = state, state != previousState {
            if cardParams != nil {
                // we transitioned to complete
                delegate?.cardFormView(self, didChangeToStateComplete: true)
                formViewInternalDelegate?.formView(self, didChangeToStateComplete: true)
            }
        } else if case .valid = previousState, state != previousState {
            delegate?.cardFormView(self, didChangeToStateComplete: false)
            formViewInternalDelegate?.formView(self, didChangeToStateComplete: false)
        }

        updateBindedPaymentMethodParams()
    }

    @objc func scanButtonTapped(sender: UIButton) {
        self.formViewInternalDelegate?.formView(self, didTapAccessoryButton: sender)
    }

    /// Returns true iff the form can mark the error to one of its fields
    @_spi(STP) public func markFormErrors(for apiError: Error) -> Bool {
        let error = apiError as NSError
        guard let errorCode = error.userInfo[STPError.stripeErrorCodeKey] as? String else {
            return false
        }
        switch errorCode {
        case "incorrect_number", "invalid_number":
            numberField.validator.validationState = .invalid(
                errorMessage: error.userInfo[NSLocalizedDescriptionKey] as? String
                    ?? numberField.validator.defaultErrorMessage
            )
            return true

        case "invalid_expiry_month", "invalid_expiry_year", "expired_card":
            expiryField.validator.validationState = .invalid(
                errorMessage: error.userInfo[NSLocalizedDescriptionKey] as? String
                    ?? expiryField.validator.defaultErrorMessage
            )
            return true

        case "invalid_cvc", "incorrect_cvc":
            cvcField.validator.validationState = .invalid(
                errorMessage: error.userInfo[NSLocalizedDescriptionKey] as? String
                    ?? cvcField.validator.defaultErrorMessage
            )
            return true

        case "incorrect_zip":
            postalCodeField.validator.validationState = .invalid(
                errorMessage: error.userInfo[NSLocalizedDescriptionKey] as? String
                    ?? postalCodeField.validator.defaultErrorMessage
            )
            return true

        default:
            return false
        }
    }

    // MARK: CBC
    /// The list of preferred networks that should be used to process
    /// payments made with a co-branded card if your user hasn't selected a
    /// network themselves.
    ///
    /// The first preferred network that matches any available network will
    /// be offered to the customer. If no preferred network is applicable, the
    /// customer will select the network.
    open var preferredNetworks: [STPCardBrand]? {
        get {
            numberField.preferredNetworks
        }
        set {
            numberField.preferredNetworks = newValue
        }
    }

    /// The list of preferred networks that should be used to process
    /// payments made with a co-branded card if your user hasn't selected a
    /// network themselves.
    ///
    /// The first preferred network that matches any available network will
    /// be offered to the customer. If no preferred network is applicable, the
    /// customer will select the network.
    ///
    /// In Objective-C, this is an array of NSNumbers representing STPCardBrands.
    /// For example:
    /// [textField setPreferredNetworks:@[[NSNumber numberWithInt:STPCardBrandVisa]]];
    @available(swift, obsoleted: 1.0)
    @objc(preferredNetworks) open func preferredNetworks_objc() -> [NSNumber]? {
        guard let preferredNetworks = self.preferredNetworks else {
            return nil
        }
        return preferredNetworks.map { NSNumber(value: $0.rawValue) }
    }

    /// The list of preferred networks that should be used to process
    /// payments made with a co-branded card if your user hasn't selected a
    /// network themselves.
    ///
    /// The first preferred network that matches any available network will
    /// be offered to the customer. If no preferred network is applicable, the
    /// customer will select the network.
    ///
    /// In Objective-C, this is an array of NSNumbers representing STPCardBrands.
    /// For example:
    /// [textField setPreferredNetworks:@[[NSNumber numberWithInt:STPCardBrandVisa]]];
    @available(swift, obsoleted: 1.0)
    @objc(setPreferredNetworks:) open func setPreferredNetworks_objc(preferredNetworks: [NSNumber]?) {
        guard let preferredNetworks = preferredNetworks else {
            self.preferredNetworks = nil
            return
        }
        self.preferredNetworks = preferredNetworks.map { STPCardBrand(rawValue: $0.intValue) ?? .unknown }
    }

    /// The account (if any) for which the funds of the intent are intended.
    /// The Stripe account ID (if any) which is the business of record.
    /// See [use cases](https://docs.stripe.com/connect/charges#on_behalf_of) to determine if this option is relevant for your integration.
    /// This should match the [on_behalf_of](https://docs.stripe.com/api/payment_intents/create#create_payment_intent-on_behalf_of)
    /// provided on the Intent used when confirming payment.
    public var onBehalfOf: String? {
        didSet {
            if let cardValidator = (numberField.validator as? STPCardNumberInputTextFieldValidator) {
                cardValidator.cbcController.onBehalfOf = onBehalfOf
            }
        }
    }
}

/// :nodoc:
extension STPCardFormView {
    class BillingAddressSubForm: NSObject {
        let formSection: STPFormView.Section

        let postalCodeField: STPPostalCodeInputTextField
        let countryPickerField: STPCountryPickerInputField = STPCountryPickerInputField()
        let stateField: STPGenericInputTextField?

        let line1Field: STPGenericInputTextField?
        let line2Field: STPGenericInputTextField?
        let cityField: STPGenericInputTextField?

        var billingDetails: STPPaymentMethodBillingDetails? {
            get {
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

                billingDetails.address = address
                return billingDetails
            }

            set {
                let address = newValue?.address

                // MUST set country code before postal code
                if let countryCode = address?.country {
                    countryPickerField.select(countryCode: countryCode)
                }

                postalCodeField.text = address?.postalCode

                if let stateField = stateField {
                    stateField.text = address?.state
                }

                if let line1Field = line1Field {
                    line1Field.text = address?.line1
                }

                if let line2Field = line2Field {
                    line2Field.text = address?.line2
                }

                if let cityField = cityField {
                    cityField.text = address?.city
                }
            }
        }

        func updateBindedBillingDetails(_ billingDetails: STPPaymentMethodBillingDetails) {
            let address = billingDetails.address ?? STPPaymentMethodAddress()

            if !postalCodeField.isHidden {
                address.postalCode = postalCodeField.postalCode
            } else {
                address.postalCode = nil
            }

            address.country = countryPickerField.inputValue

            if let stateField = stateField {
                address.state = stateField.inputValue
            }

            if let line1Field = line1Field {
                address.line1 = line1Field.inputValue
            }

            if let line2Field = line2Field {
                address.line2 = line2Field.inputValue
            }

            if let cityField = cityField {
                address.city = cityField.inputValue
            }

            billingDetails.address = address
        }

        required init(
            billingAddressCollection: BillingAddressCollectionLevel,
            postalCodeRequirement: STPPostalCodeRequirement
        ) {
            postalCodeField = STPPostalCodeInputTextField(
                postalCodeRequirement: postalCodeRequirement
            )

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
                title = String.Localized.country_or_region

            case .required:
                stateField = STPGenericInputTextField(
                    placeholder: StripeSharedStrings.localizedStateString(
                        for: Locale.autoupdatingCurrent.stp_regionCode
                    ),
                    textContentType: .addressState
                )
                line1Field = STPGenericInputTextField(
                    placeholder: String.Localized.address_line1,
                    textContentType: .streetAddressLine1,
                    keyboardType: .numbersAndPunctuation
                )
                line2Field = STPGenericInputTextField(
                    placeholder: STPLocalizedString(
                        "Address line 2 (optional)",
                        "Address line 2 placeholder for billing address form."
                    ),
                    textContentType: .streetAddressLine2,
                    keyboardType: .numbersAndPunctuation,
                    optional: true
                )
                cityField = STPGenericInputTextField(
                    placeholder: String.Localized.city,
                    textContentType: .addressCity
                )
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
                title = String.Localized.billing_address_lowercase
            }

            formSection = STPFormView.Section(rows: rows, title: title, accessoryButton: nil)
        }

    }
}

/// :nodoc:
@_spi(STP) extension STPCardFormView: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier: String = "STPCardFormView"
}

extension STPCardFormView {

    @_spi(STP) public struct PrefillDetails {
        @_spi(STP) public let last4: String
        @_spi(STP) public let expiryMonth: Int
        @_spi(STP) public let expiryYear: Int
        @_spi(STP) public let cardBrand: STPCardBrand

        @_spi(STP) public var formattedLast4: String {
            return "•••• \(last4)"
        }

        @_spi(STP) public var formattedExpiry: String {
            let paddedZero = expiryMonth < 10
            return "\(paddedZero ? "0" : "")\(expiryMonth)/\(expiryYear)"
        }

        @_spi(STP) public init(
            last4: String,
            expiryMonth: Int,
            expiryYear: Int,
            cardBrand: STPCardBrand
        ) {
            self.last4 = last4
            self.expiryMonth = expiryMonth
            self.expiryYear = expiryYear
            self.cardBrand = cardBrand
        }
    }
}

/// Billing address collection modes for PaymentSheet
@_spi(STP) public enum BillingAddressCollectionLevel {
    /// (Default) PaymentSheet will only collect the necessary billing address information
    case automatic

    /// PaymentSheet will always collect full billing address details
    case required
}
