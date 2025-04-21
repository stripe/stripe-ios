//
//  STPCardCVCInputTextField.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

@_spi(STP) public class STPCardCVCInputTextField: STPInputTextField {

    @_spi(STP) public var cardBrand: STPCardBrand = .unknown {
        didSet {
            cvcFormatter.cardBrand = cardBrand
            cvcValidator.cardBrand = cardBrand
            updateCVCImageAndPlaceholder()
            truncateTextIfNeeded()
        }
    }

    var cvcFormatter: STPCardCVCInputTextFieldFormatter {
        return formatter as! STPCardCVCInputTextFieldFormatter
    }

    var cvcValidator: STPCardCVCInputTextFieldValidator {
        return validator as! STPCardCVCInputTextFieldValidator
    }

    let cvcHintView = CardBrandView(showCVC: true)

    public convenience init(
        prefillDetails: STPCardFormView.PrefillDetails? = nil
    ) {
        self.init(
            formatter: STPCardCVCInputTextFieldFormatter(),
            validator: STPCardCVCInputTextFieldValidator()
        )

        // set card brand in a defer to ensure didSet is called updating the formatter & validator
        // swiftlint:disable:next inert_defer
        defer {
            self.cardBrand = prefillDetails?.cardBrand ?? .unknown
        }
    }

    required init(
        formatter: STPInputTextFieldFormatter,
        validator: STPInputTextFieldValidator
    ) {
        assert(formatter.isKind(of: STPCardCVCInputTextFieldFormatter.self))
        assert(validator.isKind(of: STPCardCVCInputTextFieldValidator.self))
        super.init(formatter: formatter, validator: validator)
        keyboardType = .asciiCapableNumberPad
    }

    required init?(
        coder: NSCoder
    ) {
        super.init(coder: coder)
    }

    override func setupSubviews() {
        super.setupSubviews()
        accessibilityIdentifier = "CVC"
        addAccessoryViews([cvcHintView])
        updateCVCImageAndPlaceholder()
    }

    func updateCVCImageAndPlaceholder() {
        cvcHintView.setCardBrand(.brand(cardBrand), animated: true)

        placeholder = String.Localized.cvc
    }

    func truncateTextIfNeeded() {
        guard let text = self.text else {
            return
        }

        let maxLength = Int(STPCardValidator.maxCVCLength(for: cardBrand))
        if text.count > maxLength {
            self.text = text.stp_safeSubstring(to: maxLength)
        }
    }
}
