//
//  RowButton.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 5/13/24.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

class RowButton: UIView {
    private let shadowRoundedRect: ShadowedRoundedRectangle
    let didTap: (RowButton) -> Void
    var isSelected: Bool = false {
        didSet {
            shadowRoundedRect.isSelected = isSelected
        }
    }

    init(appearance: PaymentSheet.Appearance, imageView: UIImageView, text: String, subtext: String? = nil, rightAccessoryView: UIView? = nil, didTap: @escaping (RowButton) -> Void) {
        self.didTap = didTap
        self.shadowRoundedRect = ShadowedRoundedRectangle(appearance: appearance)
        super.init(frame: .zero)

        // Label and sublabel
        let labelsStackView = UIStackView(arrangedSubviews: [
            UILabel.makeVerticalRowButtonLabel(text: text, appearance: appearance),
        ])
        if let subtext {
            let sublabel = UILabel()
            sublabel.font = appearance.scaledFont(for: appearance.font.base.regular, style: .caption1, maximumPointSize: 20)
            sublabel.numberOfLines = 1
            sublabel.adjustsFontSizeToFitWidth = true
            sublabel.adjustsFontForContentSizeCategory = true
            sublabel.text = subtext
            sublabel.textColor = appearance.colors.componentPlaceholderText
            labelsStackView.addArrangedSubview(sublabel)
        }
        labelsStackView.axis = .vertical
        labelsStackView.alignment = .leading

        // TODO: Accessory view

        addAndPinSubview(shadowRoundedRect)
        for view in [imageView, labelsStackView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        // Resolve ambiguous height warning by setting these constraints w/ low priority
        let imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: topAnchor, constant: 12)
        imageViewTopConstraint.priority = .defaultLow
        let imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        imageViewBottomConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 12),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -12),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            imageView.widthAnchor.constraint(equalToConstant: 24),

            labelsStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 12),
            labelsStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            labelsStackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            labelsStackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor, constant: 4),
            labelsStackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -4),

            imageViewBottomConstraint,
            imageViewTopConstraint,
        ])

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func handleTap() {
        didTap(self)
    }
}

// MARK: - Helpers
extension RowButton {
    static func makeForPaymentMethodType(paymentMethodType: PaymentSheet.PaymentMethodType, appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        let imageView = PaymentMethodTypeImageView(paymentMethodType: paymentMethodType, backgroundColor: appearance.colors.componentBackground)
        imageView.contentMode = .scaleAspectFit
        let subtext: String? = {
            switch paymentMethodType {
            case .stripe(.klarna):
                return String.Localized.buy_now_or_pay_later_with_klarna
            default:
                // TODO: Add Afterpay
                return nil
            }
        }()
        return RowButton(appearance: appearance, imageView: imageView, text: paymentMethodType.displayName, subtext: subtext, didTap: didTap)
    }

    static func makeForApplePay(appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        // Apple Pay logo has built-in padding and ends up looking too small; compensate with insets
        let applePayLogo = Image.apple_pay_mark.makeImage().withAlignmentRectInsets(UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8))
        let imageView = UIImageView(image: applePayLogo)
        imageView.contentMode = .scaleAspectFit
        return RowButton(appearance: appearance, imageView: imageView, text: String.Localized.apple_pay, didTap: didTap)
    }

    static func makeForLink(appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        let imageView = UIImageView(image: Image.link_icon.makeImage())
        imageView.contentMode = .scaleAspectFit
        // TODO: Add Link subtext
        return RowButton(appearance: appearance, imageView: imageView, text: STPPaymentMethodType.link.displayName, didTap: didTap)
    }

    static func makeForSavedPaymentMethod(paymentMethod: STPPaymentMethod, appearance: PaymentSheet.Appearance, didTap: @escaping (RowButton) -> Void) -> RowButton {
        let imageView = UIImageView(image: paymentMethod.makeSavedPaymentMethodRowImage())
        imageView.contentMode = .scaleAspectFit
        return RowButton(appearance: appearance, imageView: imageView, text: paymentMethod.paymentSheetLabel, didTap: didTap)
    }
}
