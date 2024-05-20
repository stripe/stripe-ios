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
    // TODO: didSelectEdit/ViewMore
}

class VerticalPaymentMethodListView: UIView {
    enum Selection: Equatable {
        case new(paymentMethodType: PaymentSheet.PaymentMethodType)
        case saved(paymentMethod: STPPaymentMethod)
        case applePay
        case link
    }

    let stackView: UIStackView
    weak var delegate: VerticalPaymentMethodListViewDelegate?

    init(savedPaymentMethod: STPPaymentMethod?, paymentMethodTypes: [PaymentSheet.PaymentMethodType], shouldShowApplePay: Bool, shouldShowLink: Bool, appearance: PaymentSheet.Appearance, delegate: VerticalPaymentMethodListViewDelegate) {
        self.delegate = delegate
        // TODO: Add Apple Pay, Link
        var views = [UIView]()
        // Saved payment methods:
        if let savedPaymentMethod {
            views += [
                Self.makeSectionLabel(text: .Localized.saved, appearance: appearance),
                RowButton.makeForSavedPaymentMethod(paymentMethod: savedPaymentMethod, appearance: appearance) { [weak delegate] _ in
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
        super.init(frame: .zero)
        backgroundColor = appearance.colors.background
        addAndPinSubview(stackView)
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
