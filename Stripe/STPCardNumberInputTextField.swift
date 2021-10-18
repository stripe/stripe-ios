//
//  STPCardNumberInputTextField.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

class STPCardNumberInputTextField: STPInputTextField {

    struct LayoutConstants {
        static let loadingIndicatorOffset: CGFloat = 4
    }

    public var cardBrand: STPCardBrand {
        return (validator as! STPCardNumberInputTextFieldValidator).cardBrand
    }

    public convenience init() {
        self.init(
            formatter: STPCardNumberInputTextFieldFormatter(),
            validator: STPCardNumberInputTextFieldValidator())
    }

    let brandImageView = CardBrandView()

    lazy var loadingIndicator: STPCardLoadingIndicator = {
        let loadingIndicator = STPCardLoadingIndicator()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        return loadingIndicator
    }()

    required init(formatter: STPInputTextFieldFormatter, validator: STPInputTextFieldValidator) {
        assert(formatter.isKind(of: STPCardNumberInputTextFieldFormatter.self))
        assert(validator.isKind(of: STPCardNumberInputTextFieldValidator.self))
        super.init(formatter: formatter, validator: validator)
        keyboardType = .asciiCapableNumberPad
        textContentType = .creditCardNumber
        addAccessoryViews([brandImageView])
        updateRightView()
    }

    required init?(coder: NSCoder) {
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
                        Int64(0.1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC),
                    execute: {
                        if case .processing = self.validator.validationState,
                            self.loadingIndicator.superview == nil
                        {
                            self.addSubview(self.loadingIndicator)
                            NSLayoutConstraint.activate(
                                [
                                    self.loadingIndicator.rightAnchor.constraint(
                                        equalTo: self.brandImageView.rightAnchor,
                                        constant: LayoutConstants.loadingIndicatorOffset),
                                    self.loadingIndicator.topAnchor.constraint(
                                        equalTo: self.brandImageView.topAnchor,
                                        constant: -LayoutConstants.loadingIndicatorOffset),
                                ]
                            )
                        }
                    })
            }
        }
    }

    override func validationDidUpdate(
        to state: STPValidatedInputState, from previousState: STPValidatedInputState,
        for unformattedInput: String?, in input: STPFormInput
    ) {
        super.validationDidUpdate(to: state, from: previousState, for: unformattedInput, in: input)
        updateRightView()
    }
}
