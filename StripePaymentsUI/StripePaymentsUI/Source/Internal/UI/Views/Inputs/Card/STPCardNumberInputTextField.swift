//
//  STPCardNumberInputTextField.swift
//  StripePaymentsUI
//
//  Created by Cameron Sabol on 10/22/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore
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
    
    var preferredNetworks: [STPCardBrand]? {
        get {
            return (validator as! STPCardNumberInputTextFieldValidator).preferredNetworks
        }
        set {
            (validator as! STPCardNumberInputTextFieldValidator).preferredNetworks = newValue
        }
    }
    
    var isShowingCBCIndicator: Bool {
//      Set this up
        return true
//        // The brand state is CBC
//        return self.viewModel.brandState.isCBC &&
//        // And the card is not valid (we're not showing an error image)
//        STPCardValidator.validationState(
//            forNumber: viewModel.cardNumber ?? "",
//            validatingCardBrand: true
//        ) != .invalid
    }

    open override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        let pointInBrandImageView = CGPoint(x: brandImageView.bounds.midX, y: brandImageView.bounds.maxY)
        return self.convert(pointInBrandImageView, from: brandImageView)
    }

    open override func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        if !isShowingCBCIndicator {
            // Don't pop a menu if the CBC indicator isn't visible
            return nil
        }

        let targetPointInBrandView = brandImageView.convert(location, from: self)
        let targetRect = brandImageView.bounds
        if !targetRect.contains(targetPointInBrandView) {
            // Don't pop a menu outside the brand selector area
            return nil
        }

        return UIContextMenuConfiguration(actionProvider: { _ in
            let action = { (action: UIAction) -> Void in
                let brand = STPCard.brand(from: action.identifier.rawValue)
                // Set the selected brand if a brand is selected
                self.selectedBrand = brand != .unknown ? brand : nil
                //                TODO: This
//                self.updateImage(for: .number)
            }
            let placeholderAction = UIAction(title: String.Localized.card_brand_dropdown_placeholder, attributes: .disabled, handler: action)
            let menu = UIMenu(children:
                  [placeholderAction] +
                  self.cardBrands.enumerated().map { (_, brand) in
                        let brandString = STPCard.string(from: brand)
                        return UIAction(title: brandString, image: STPImageLibrary.unpaddedCardBrandImage(for: brand), identifier: .init(rawValue: brandString), state: self.selectedBrand == brand ? .on : .off, handler: action)
                }
            )
            return menu
        })
    }

    @_spi(STP) public convenience init(
        inputMode: InputMode = .standard,
        prefillDetails: STPCardFormView.PrefillDetails? = nil,
        cbcEnabledOverride: Bool? = nil
    ) {
        // Don't format for panLocked input mode
        self.init(
            formatter: inputMode == .panLocked
                ? STPInputTextFieldFormatter() : STPCardNumberInputTextFieldFormatter(),
            validator: STPCardNumberInputTextFieldValidator(
                inputMode: inputMode,
                cardBrand: prefillDetails?.cardBrand,
                cbcEnabledOverride: cbcEnabledOverride
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
    
    var selectedBrand: STPCardBrand?

    var cardBrands = Set<STPCardBrand>() {
        didSet {
            // If the selected brand does not exist in the current list of brands, reset it
            if let selectedBrand = selectedBrand, !cardBrands.contains(selectedBrand) {
                self.selectedBrand = nil
            }
            // If the selected brand is nil and our preferred brand exists, set that as the selected brand
            if let preferredNetworks = preferredNetworks,
               selectedBrand == nil,
               let preferredBrand = preferredNetworks.first(where: { cardBrands.contains($0) }) {
                self.selectedBrand = preferredBrand
            }
        }
    }
    func updateCardBrandsIfNeeded() {
//        TODO: This
//        guard formatter.cbcEnabled else {
//            // Do nothing, CBC is not initializaed
//            return
//        }
        self.fetchCardBrands { [weak self] cardBrands in
//            do something with the updated brands
//            self?.updateImage(for: .number)
            
            self?.brandImageView.showCBC = !cardBrands.isEmpty
        }
    }

    func fetchCardBrands(handler: @escaping (Set<STPCardBrand>) -> Void) {
        // Only fetch card brands if we have at least 8 digits in the pan
        guard let cardNumber = self.inputValue,
              cardNumber.count >= 8 else {
            // Clear any previously fetched card brands from the dropdown
            if self.cardBrands != Set<STPCardBrand>() {
                self.cardBrands = Set<STPCardBrand>()
                handler(cardBrands)
            }
            return
        }

        var fetchedCardBrands = Set<STPCardBrand>()
        STPCardValidator.possibleBrands(forNumber: cardNumber) { [weak self] result in
            switch result {
            case .success(let brands):
                fetchedCardBrands = brands
            case .failure:
                // If we fail to fetch card brands fall back to normal card brand detection
                fetchedCardBrands = Set<STPCardBrand>()
            }

            if self?.cardBrands != fetchedCardBrands {
                self?.cardBrands = fetchedCardBrands
                handler(fetchedCardBrands)
            }
        }
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
        updateCardBrandsIfNeeded()
    }
}
