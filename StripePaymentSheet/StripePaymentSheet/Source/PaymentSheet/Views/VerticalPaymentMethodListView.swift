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
    /// Called when a row is tapped, before `didTapPaymentMethod` is called.
    /// - Returns: Whether or not the payment method row button should appear selected.
    func shouldSelectPaymentMethod(_ selection: VerticalPaymentMethodListSelection) -> Bool

    /// Called after a row is tapped and after `shouldSelectPaymentMethod` is called
    func didTapPaymentMethod(_ selection: VerticalPaymentMethodListSelection)

    /// Called when the accessory button on the saved payment method row is tapped
    func didTapSavedPaymentMethodAccessoryButton()
}

enum VerticalPaymentMethodListSelection: Equatable {
    case new(paymentMethodType: PaymentSheet.PaymentMethodType)
    case saved(paymentMethod: STPPaymentMethod)
    case applePay
    case link

    static func == (lhs: VerticalPaymentMethodListSelection, rhs: VerticalPaymentMethodListSelection) -> Bool {
        switch (lhs, rhs) {
        case (.link, .link):
            return true
        case (.applePay, .applePay):
            return true
        case let (.new(lhsPMType), .new(rhsPMType)):
            return lhsPMType == rhsPMType
        case let (.saved(lhsPM), .saved(rhsPM)):
            return lhsPM.stripeId == rhsPM.stripeId
        default:
            return false
        }
    }
}

class VerticalPaymentMethodListView: UIView {
    let stackView: UIStackView
    weak var delegate: VerticalPaymentMethodListViewDelegate?
    /// Returns the currently selected payment option i.e. the one that appears selected
    private(set) var currentSelection: VerticalPaymentMethodListSelection?
    var rowButtons: [RowButton] {
        return stackView.arrangedSubviews.compactMap { $0 as? RowButton }
    }

    init(initialSelection: VerticalPaymentMethodListSelection?, savedPaymentMethod: STPPaymentMethod?, paymentMethodTypes: [PaymentSheet.PaymentMethodType], shouldShowApplePay: Bool, shouldShowLink: Bool, savedPaymentMethodAccessoryType: RowButton.RightAccessoryButton.AccessoryType?, appearance: PaymentSheet.Appearance) {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 12.0
        self.stackView = stackView
        self.currentSelection = initialSelection
        super.init(frame: .zero)

        // Create stack view views after super.init so that we can reference `self`
        var views = [UIView]()
        // Saved payment methods:
        if let savedPaymentMethod {
            let selection = VerticalPaymentMethodListSelection.saved(paymentMethod: savedPaymentMethod)
            let accessoryButton: RowButton.RightAccessoryButton? = {
                if let savedPaymentMethodAccessoryType {
                    return RowButton.RightAccessoryButton(accessoryType: savedPaymentMethodAccessoryType, appearance: appearance, didTap: didTapAccessoryButton)
                } else {
                    return nil
                }
            }()

            let savedPaymentMethodButton = RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod, appearance: appearance, rightAccessoryView: accessoryButton) { [weak self] in
                self?.didTap(rowButton: $0, selection: selection)
            }
            if initialSelection == selection {
                savedPaymentMethodButton.isSelected = true
                currentSelection = selection
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
            let selection = VerticalPaymentMethodListSelection.applePay
            let rowButton = RowButton.makeForApplePay(appearance: appearance) { [weak self] in
                self?.didTap(rowButton: $0, selection: .applePay)
            }
            views.append(rowButton)
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
        }
        if shouldShowLink {
            let selection = VerticalPaymentMethodListSelection.link
            let rowButton = RowButton.makeForLink(appearance: appearance) { [weak self] in
                self?.didTap(rowButton: $0, selection: .link)
            }
            views.append(rowButton)
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
        }

        // All other payment methods:
        for paymentMethodType in paymentMethodTypes {
            let selection = VerticalPaymentMethodListSelection.new(paymentMethodType: paymentMethodType)
            let rowButton = RowButton.makeForPaymentMethodType(paymentMethodType: paymentMethodType, appearance: appearance) { [weak self] in
                self?.didTap(rowButton: $0, selection: selection)
            }
            views.append(rowButton)
            if initialSelection == selection {
                rowButton.isSelected = true
                currentSelection = selection
            }
        }

        for view in views {
            stackView.addArrangedSubview(view)
        }
        backgroundColor = appearance.colors.background
        addAndPinSubview(stackView)
    }

    func didTap(rowButton: RowButton, selection: VerticalPaymentMethodListSelection) {
        guard let delegate else { return }
        let shouldSelect = delegate.shouldSelectPaymentMethod(selection)
        if shouldSelect {
            // Deselect previous row
            rowButtons.forEach {
                $0.isSelected = false
            }
            // Select new row
            rowButton.isSelected = shouldSelect
            currentSelection = selection
        }
        delegate.didTapPaymentMethod(selection)
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
