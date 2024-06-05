//
//  STPCardNumberInputTextField.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeCore
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

    var cardBrandState: STPCBCController.BrandState {
        return (validator as! STPCardNumberInputTextFieldValidator).cardBrandState
    }

    var brandForCVC: STPCardBrand {
        return (validator as! STPCardNumberInputTextFieldValidator).cbcController.brandForCVC
    }

    var preferredNetworks: [STPCardBrand]? {
        get {
            return (validator as? STPCardNumberInputTextFieldValidator)?.cbcController.preferredNetworks
        }
        set {
            (validator as? STPCardNumberInputTextFieldValidator)?.cbcController.preferredNetworks = newValue
        }
    }

    open override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        let pointInBrandImageView = CGPoint(x: brandImageView.bounds.midX, y: brandImageView.bounds.maxY)
        return self.convert(pointInBrandImageView, from: brandImageView)
    }

    open override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let validator = (validator as? STPCardNumberInputTextFieldValidator), validator.cbcController.brandState.isCBC else {
            // Don't pop a menu if the CBC indicator isn't visible
            return nil
        }

        let targetPointInBrandView = brandImageView.convert(location, from: self)
        let targetRect = brandImageView.bounds
        if !targetRect.contains(targetPointInBrandView) {
            // Don't pop a menu outside the brand selector area
            return nil
        }
        return validator.cbcController.contextMenuConfiguration
    }

    @_spi(STP) public convenience init(
        inputMode: InputMode = .standard,
        prefillDetails: STPCardFormView.PrefillDetails? = nil,
        cbcEnabledOverride: Bool? = nil
    ) {
        let validator = STPCardNumberInputTextFieldValidator(
            inputMode: inputMode,
            cardBrand: prefillDetails?.cardBrand,
            cbcEnabledOverride: cbcEnabledOverride
        )
        // Don't format for panLocked input mode
        self.init(
            formatter: inputMode == .panLocked
                ? STPInputTextFieldFormatter() : STPCardNumberInputTextFieldFormatter(),
            validator: validator
        )
        validator.cbcController.updateHandler = { [weak self] in
            self?.updateRightView()
        }

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
        // Set up CBC menu interactions
        if #available(iOS 14.0, *) {
            self.showsMenuAsPrimaryAction = true
            self.isContextMenuInteractionEnabled = true
        }
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
            brandImageView.setCardBrand(cardBrandState, animated: true)
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
        if let cardValidator = validator as? STPCardNumberInputTextFieldValidator {
            let isCBC = cardValidator.cbcController.brandState.isCBC
            brandImageView.isShowingCBCIndicator = isCBC
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
