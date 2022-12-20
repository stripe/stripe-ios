//
//  STPCardNumberInputTextField.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

@_spi(STP) public class STPCardNumberInputTextField: STPInputTextField {

    /// Describes which input fields can take input
    @_spi(STP) public enum InputMode {
        /// All input fields can be edited
        case standard
        // PAN field is locked, all others are editable
        case panLocked
    }

    struct LayoutConstants {
        static let loadingIndicatorOffset: CGFloat = 4
    }

    @_spi(STP) public var cardBrand: STPCardBrand {
        return (validator as! STPCardNumberInputTextFieldValidator).cardBrand
    }

    @_spi(STP) public convenience init(
        inputMode: InputMode = .standard,
        prefillDetails: STPCardFormView.PrefillDetails? = nil
    ) {
        // Don't format for panLocked input mode
        self.init(
            formatter: inputMode == .panLocked
                ? STPInputTextFieldFormatter() : STPCardNumberInputTextFieldFormatter(),
            validator: STPCardNumberInputTextFieldValidator(
                inputMode: inputMode,
                cardBrand: prefillDetails?.cardBrand
            )
        )

        self.text = prefillDetails?.formattedLast4  // pre-fill last 4 if available
    }

    let brandImageView = CardBrandView()

    lazy var loadingIndicator: STPCardLoadingIndicator = {
        let loadingIndicator = STPCardLoadingIndicator()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        return loadingIndicator
    }()

    required init(
        formatter: STPInputTextFieldFormatter,
        validator: STPInputTextFieldValidator
    ) {
        assert(validator.isKind(of: STPCardNumberInputTextFieldValidator.self))
        super.init(formatter: formatter, validator: validator)
        keyboardType = .asciiCapableNumberPad
        textContentType = .creditCardNumber
        addAccessoryViews([brandImageView])
        updateRightView()
    }

    required init?(
        coder: NSCoder
    ) {
        super.init(coder: coder)
    }

    override func setupSubviews() {
        super.setupSubviews()
        accessibilityIdentifier = "Card number"
        placeholder = STPLocalizedString("Card number", "Label for card number entry text field")
    }

    func updateRightView() {
        switch validator.validationState {

        case .unknown:
            loadingIndicator.removeFromSuperview()
            brandImageView.setCardBrand(.unknown, animated: true)
        case .valid, .incomplete:
            loadingIndicator.removeFromSuperview()
            brandImageView.setCardBrand(cardBrand, animated: true)
        case .invalid:
            loadingIndicator.removeFromSuperview()
            brandImageView.setCardBrand(.unknown, animated: true)
        case .processing:
            if loadingIndicator.superview == nil {
                brandImageView.setCardBrand(.unknown, animated: true)
                // delay a bit before showing loading indicator because the response may come quickly
                DispatchQueue.main.asyncAfter(
                    deadline: DispatchTime.now() + Double(
                        Int64(0.1 * Double(NSEC_PER_SEC))
                    ) / Double(NSEC_PER_SEC),
                    execute: {
                        if case .processing = self.validator.validationState,
                            self.loadingIndicator.superview == nil
                        {
                            self.addSubview(self.loadingIndicator)
                            NSLayoutConstraint.activate(
                                [
                                    self.loadingIndicator.rightAnchor.constraint(
                                        equalTo: self.brandImageView.rightAnchor,
                                        constant: LayoutConstants.loadingIndicatorOffset
                                    ),
                                    self.loadingIndicator.topAnchor.constraint(
                                        equalTo: self.brandImageView.topAnchor,
                                        constant: -LayoutConstants.loadingIndicatorOffset
                                    ),
                                ]
                            )
                        }
                    }
                )
            }
        }
    }

    override func validationDidUpdate(
        to state: STPValidatedInputState,
        from previousState: STPValidatedInputState,
        for unformattedInput: String?,
        in input: STPFormInput
    ) {
        super.validationDidUpdate(to: state, from: previousState, for: unformattedInput, in: input)
        updateRightView()
    }
}
