//
//  VerticalPaymentMethodListView.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/8/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol VerticalPaymentMethodListViewDelegate: AnyObject {
    /// - Returns: Whether or not the payment method row button should appear selected.
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool

    /// Called when the accessory button on the saved payment method row is tapped
    func didTapSavedPaymentMethodAccessoryButton()
}

enum VerticalPaymentMethodListSelection: Equatable {
    case new(paymentMethodType: PaymentSheet.PaymentMethodType)
    case saved(paymentMethod: STPPaymentMethod)
    case applePay
    case link

    var paymentMethodType: PaymentSheet.PaymentMethodType? {
        switch self {
        case .new(let paymentMethodType):
            return paymentMethodType
        case .saved, .applePay, .link:
            return nil
        }
    }
}

class VerticalPaymentMethodListView: UIView {
    let stackView: UIStackView
    weak var delegate: VerticalPaymentMethodListViewDelegate?
    /// Returns the currently selected payment option i.e. the one that appears selected
    var currentSelection: VerticalPaymentMethodListSelection?
    var rowButtons: [RowButton] {
        return stackView.arrangedSubviews.compactMap { $0 as? RowButton }
    }

    init(currentSelection: VerticalPaymentMethodListSelection?, savedPaymentMethod: STPPaymentMethod?, paymentMethodTypes: [PaymentSheet.PaymentMethodType], shouldShowApplePay: Bool, shouldShowLink: Bool, rightAccessoryType: RowButton.RightAccessoryButton.AccessoryType?, appearance: PaymentSheet.Appearance) {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12.0
        self.stackView = stackView
        super.init(frame: .zero)

        // Create stack view views after super.init so that we can reference `self`
        var views = [UIView]()
        // Saved payment methods:
        if let savedPaymentMethod {
            var accessoryButton: RowButton.RightAccessoryButton?
            if let rightAccessoryType {
                accessoryButton = RowButton.RightAccessoryButton(accessoryType: rightAccessoryType, appearance: appearance, didTap: didTapAccessoryButton)
            }
            let savedPaymentMethodButton = RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod,
                                                                               appearance: appearance,
                                                                               rightAccessoryView: accessoryButton)
            { [weak self] in
                self?.didTap(rowButton: $0, selection: .saved(paymentMethod: savedPaymentMethod))
            }

            // Selected saved payment method button if current selection is a saved payment method or if current selection is nil
            if case .saved(let paymentMethod) = currentSelection {
                savedPaymentMethodButton.isSelected = true
                self.currentSelection = .saved(paymentMethod: paymentMethod)
            } else if currentSelection == nil {
                savedPaymentMethodButton.isSelected = true
                self.currentSelection = .saved(paymentMethod: savedPaymentMethod)
            }

            views += [
                Self.makeSectionLabel(text: .Localized.saved, appearance: appearance),
                savedPaymentMethodButton,
                .makeSpacerView(height: 12),
                Self.makeSectionLabel(text: .Localized.new_payment_method, appearance: appearance),
            ]
        }

        // Apple Pay and Link:
        if shouldShowApplePay {
            let button = RowButton.makeForApplePay(appearance: appearance) { [weak self] in
                self?.didTap(rowButton: $0, selection: .applePay)
            }
            if case .applePay = currentSelection {
                button.isSelected = true
            }
            views.append(button)
        }
        if shouldShowLink {
            let button = RowButton.makeForLink(appearance: appearance) { [weak self] in
                self?.didTap(rowButton: $0, selection: .link)
            }
            if case .link = currentSelection {
                button.isSelected = true
            }
            views.append(button)
        }

        // All other payment methods:
        for paymentMethodType in paymentMethodTypes {
            let button = RowButton.makeForPaymentMethodType(paymentMethodType: paymentMethodType, appearance: appearance) { [weak self] in
                self?.didTap(rowButton: $0, selection: .new(paymentMethodType: paymentMethodType))
            }
            if paymentMethodType == currentSelection?.paymentMethodType {
                button.isSelected = true
            }
            views.append(button)
        }

        for view in views {
            stackView.addArrangedSubview(view)
        }
        backgroundColor = appearance.colors.background
        addAndPinSubview(stackView)
    }

    func didTap(rowButton: RowButton, selection: VerticalPaymentMethodListSelection) {
        guard let delegate else { return }
        let shouldSelect = delegate.didTapPaymentMethod(selection)
        if shouldSelect {
            // Deselect previous row
            rowButtons.forEach {
                $0.isSelected = false
            }
            // Select new row
            rowButton.isSelected = shouldSelect
            currentSelection = selection
        }
    }

    @objc func didTapAccessoryButton() {
        delegate?.didTapSavedPaymentMethodAccessoryButton()
    }

    static func makeSectionLabel(text: String, appearance: PaymentSheet.Appearance) -> UILabel {
        let label = UILabel()
        label.font = appearance.scaledFont(for: appearance.font.base.regular, style: .subheadline, maximumPointSize: 25)
        label.textColor = appearance.colors.text
        label.adjustsFontForContentSizeCategory = true
        label.text = text
        return label
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
