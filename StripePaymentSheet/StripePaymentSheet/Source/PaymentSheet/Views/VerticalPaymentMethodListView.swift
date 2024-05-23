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
    func didSelectPaymentMethod(_ selection: VerticalPaymentMethodListView.Selection)
    func didSelectAccessoryButton(_ type: VerticalPaymentMethodListView.AccessoryButtonType)
    // TODO: didSelectEdit/ViewMore
}

class VerticalPaymentMethodListView: UIView {
    enum Selection: Equatable {
        case new(paymentMethodType: PaymentSheet.PaymentMethodType)
        case saved(paymentMethod: STPPaymentMethod)
        case applePay
        case link
    }
    
    enum AccessoryButtonType {
        case none
        case edit
        case viewMore
        
        var text: String? {
            switch self {
            case .none:
                return nil
            case .edit:
                return "Edit"
            case .viewMore:
                return "View more"
            }
        }
        
        var accessoryImage: UIImage? {
            switch self {
            case .none, .edit:
                return nil
            case .viewMore:
                let imageConfig = UIImage.SymbolConfiguration(scale: .small)
                return  UIImage(systemName: "chevron.right", withConfiguration: imageConfig)
            }
        }
    }

    let stackView: UIStackView
    let appearance: PaymentSheet.Appearance
    let accessoryButtonType: AccessoryButtonType
    weak var delegate: VerticalPaymentMethodListViewDelegate?
    
    init(savedPaymentMethod: STPPaymentMethod?, paymentMethodTypes: [PaymentSheet.PaymentMethodType], shouldShowApplePay: Bool, shouldShowLink: Bool, appearance: PaymentSheet.Appearance, accessoryButtonType: AccessoryButtonType, delegate: VerticalPaymentMethodListViewDelegate) {
        self.delegate = delegate
        // TODO: Add Apple Pay, Link
        var views = [UIView]()
        let accessoryButton = UIButton.makeAccessoryButton(type: accessoryButtonType, appearance: appearance)
        
        // Saved payment methods:
        if let savedPaymentMethod {
            // TODO accessibility
            views += [
                Self.makeSectionLabel(text: .Localized.saved, appearance: appearance),
                RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod, appearance: appearance, rightAccessoryView: accessoryButton) { [weak delegate] _ in
                    // TODO: If selectable (no form), set selected and deselect other
                    delegate?.didSelectPaymentMethod(.saved(paymentMethod: savedPaymentMethod))
                },
                .makeSpacerView(height: 12),
                Self.makeSectionLabel(text: .Localized.new_payment_method, appearance: appearance),
            ]
        }

        // Apple Pay and Link:
        if shouldShowApplePay {
            views.append(
                RowButton.makeForApplePay(appearance: appearance, didTap: { [weak delegate] _ in
                    delegate?.didSelectPaymentMethod(.applePay)
                })
            )
        }
        if shouldShowLink {
            views.append(
                RowButton.makeForLink(appearance: appearance, didTap: { [weak delegate] _ in
                    delegate?.didSelectPaymentMethod(.link)
                })
            )
        }

        // All other payment methods:
        for paymentMethodType in paymentMethodTypes {
            views.append(
                RowButton.makeForPaymentMethodType(paymentMethodType: paymentMethodType, appearance: appearance) { [weak delegate] _ in
                    // TODO: If selectable (no form), set selected and deselect other
                    delegate?.didSelectPaymentMethod(.new(paymentMethodType: paymentMethodType))
                }
            )
        }
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.spacing = 12.0
        self.stackView = stackView
        self.appearance = appearance
        self.accessoryButtonType = accessoryButtonType
        super.init(frame: .zero)
        backgroundColor = appearance.colors.background
        accessoryButton?.addTarget(self, action: #selector(didTapAccessoryButton), for: .touchUpInside)
        addAndPinSubview(stackView)
    }
    
    @objc func didTapAccessoryButton() {
        delegate?.didSelectAccessoryButton(accessoryButtonType)
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

extension UIButton {
    static func makeAccessoryButton(type: VerticalPaymentMethodListView.AccessoryButtonType, appearance: PaymentSheet.Appearance) -> UIButton? {
        guard type != .none else { return nil }
        
        let button = UIButton(type: .system)
        button.setTitle(type.text, for: .normal)
        button.setTitleColor(appearance.colors.primary, for: .normal) // TODO read secondary action color
        button.titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 20)
        button.setImage(type.accessoryImage, for: .normal)
        button.imageEdgeInsets = UIEdgeInsets(top: 2, left: 5, bottom: 0, right: 0)
        button.semanticContentAttribute = .forceRightToLeft // to put the image on the right side
        return button
    }
}
