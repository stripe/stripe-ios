//
//  STPPaymentOptionTableViewCell.swift
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import UIKit

class STPPaymentOptionTableViewCell: UITableViewCell {
    @objc(configureForNewCardRowWithTheme:) func configureForNewCardRow(with theme: STPTheme) {
        paymentOption = nil
        self.theme = theme

        backgroundColor = theme.secondaryBackgroundColor

        // Left icon
        leftIcon.image = STPImageLibrary.addIcon()
        leftIcon.tintColor = theme.accentColor

        // Title label
        titleLabel.font = theme.font
        titleLabel.textColor = theme.accentColor
        titleLabel.text = STPLocalizedString("Add New Card…", "Button to add a new credit card.")

        // Checkmark icon
        checkmarkIcon.isHidden = true

        setNeedsLayout()
    }

    @objc(configureWithPaymentOption:theme:selected:) func configure(
        with paymentOption: STPPaymentOption?, theme: STPTheme, selected: Bool
    ) {
        self.paymentOption = paymentOption
        self.theme = theme

        backgroundColor = theme.secondaryBackgroundColor

        // Left icon
        leftIcon.image = paymentOption?.templateImage
        leftIcon.tintColor = primaryColorForPaymentOption(withSelected: selected)

        // Title label
        titleLabel.font = theme.font
        titleLabel.attributedText = buildAttributedString(with: paymentOption, selected: selected)

        // Checkmark icon
        checkmarkIcon.tintColor = theme.accentColor
        checkmarkIcon.isHidden = !selected

        // Accessibility
        if selected {
            accessibilityTraits.insert(.selected)
        } else {
            accessibilityTraits.remove(.selected)
        }

        setNeedsLayout()
    }

    @objc(configureForFPXRowWithTheme:) func configureForFPXRow(with theme: STPTheme) {
        paymentOption = nil
        self.theme = theme

        backgroundColor = theme.secondaryBackgroundColor

        // Left icon
        leftIcon.image = STPImageLibrary.bankIcon()
        leftIcon.tintColor = primaryColorForPaymentOption(withSelected: false)

        // Title label
        titleLabel.font = theme.font
        titleLabel.textColor = self.theme.primaryForegroundColor
        titleLabel.text = STPLocalizedString(
            "Online Banking (FPX)", "Button to pay with a Bank Account (using FPX).")

        // Checkmark icon
        checkmarkIcon.isHidden = true
        accessoryType = .disclosureIndicator
        setNeedsLayout()
    }

    private var paymentOption: STPPaymentOption?
    private var theme: STPTheme = .defaultTheme
    private var leftIcon = UIImageView()
    private var titleLabel = UILabel()
    private var checkmarkIcon = UIImageView(image: STPImageLibrary.checkmarkIcon())

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Left icon
        leftIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(leftIcon)

        // Title label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)

        // Checkmark icon
        checkmarkIcon.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(checkmarkIcon)

        NSLayoutConstraint.activate(
            [
                self.leftIcon.centerXAnchor.constraint(
                    equalTo: contentView.leadingAnchor, constant: kPadding + 0.5 * kDefaultIconWidth
                ),
                self.leftIcon.centerYAnchor.constraint(
                    lessThanOrEqualTo: contentView.centerYAnchor),
                self.checkmarkIcon.widthAnchor.constraint(equalToConstant: kCheckmarkWidth),
                self.checkmarkIcon.heightAnchor.constraint(
                    equalTo: self.checkmarkIcon.widthAnchor, multiplier: 1.0),
                self.checkmarkIcon.centerXAnchor.constraint(
                    equalTo: contentView.trailingAnchor, constant: -kPadding),
                self.checkmarkIcon.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
                // Constrain label to leadingAnchor with the default
                // icon width so that the text always aligns vertically
                // even if the icond widths differ
                self.titleLabel.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor, constant: 2.0 * kPadding + kDefaultIconWidth
                ),
                self.titleLabel.trailingAnchor.constraint(
                    equalTo: self.checkmarkIcon.leadingAnchor, constant: -kPadding),
                self.titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ])
        accessibilityTraits.insert(.button)
        isAccessibilityElement = true
    }

    func primaryColorForPaymentOption(withSelected selected: Bool) -> UIColor {
        let fadedColor: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor(dynamicProvider: { _ in
                    return self.theme.primaryForegroundColor.withAlphaComponent(0.6)
                })
            } else {
                return theme.primaryForegroundColor.withAlphaComponent(0.6)
            }
        }()

        return (selected ? theme.accentColor : fadedColor)
    }

    func buildAttributedString(with paymentOption: STPPaymentOption?, selected: Bool)
        -> NSAttributedString
    {
        if let paymentOption = paymentOption as? STPCard {
            return buildAttributedString(with: paymentOption, selected: selected)
        } else if let source = paymentOption as? STPSource {
            if source.type == .card && source.cardDetails != nil {
                return buildAttributedString(withCardSource: source, selected: selected)
            }
        } else if let paymentMethod = paymentOption as? STPPaymentMethod {
            if paymentMethod.type == .card && paymentMethod.card != nil {
                return buildAttributedString(
                    withCardPaymentMethod: paymentMethod, selected: selected)
            }
            if paymentMethod.type == .FPX && paymentMethod.fpx != nil {
                return buildAttributedString(
                    with: STPFPXBank.brandFrom(paymentMethod.fpx?.bankIdentifierCode),
                    selected: selected)
            }
        } else if paymentOption is STPApplePayPaymentOption {
            let label = STPLocalizedString("Apple Pay", "Text for Apple Pay payment method")
            let primaryColor = primaryColorForPaymentOption(withSelected: selected)
            return NSAttributedString(
                string: label,
                attributes: [
                    NSAttributedString.Key.foregroundColor: primaryColor
                ])
        } else if let paymentMethodParams = paymentOption as? STPPaymentMethodParams {
            if paymentMethodParams.type == .card && paymentMethodParams.card != nil {
                return buildAttributedString(
                    withCardPaymentMethodParams: paymentMethodParams, selected: selected)
            }
            if paymentMethodParams.type == .FPX && paymentMethodParams.fpx != nil {
                return buildAttributedString(
                    with: paymentMethodParams.fpx?.bank ?? STPFPXBankBrand.unknown,
                    selected: selected)
            }
        }

        // Unrecognized payment method
        return NSAttributedString(string: "")
    }

    func buildAttributedString(with card: STPCard, selected: Bool) -> NSAttributedString {
        return buildAttributedString(
            with: card.brand,
            last4: card.last4,
            selected: selected)
    }

    func buildAttributedString(withCardSource card: STPSource, selected: Bool) -> NSAttributedString
    {
        return buildAttributedString(
            with: card.cardDetails?.brand ?? .unknown,
            last4: card.cardDetails?.last4 ?? "",
            selected: selected)
    }

    func buildAttributedString(
        withCardPaymentMethod paymentMethod: STPPaymentMethod, selected: Bool
    )
        -> NSAttributedString
    {
        return buildAttributedString(
            with: paymentMethod.card?.brand ?? .unknown,
            last4: paymentMethod.card?.last4 ?? "",
            selected: selected)
    }

    func buildAttributedString(
        withCardPaymentMethodParams paymentMethodParams: STPPaymentMethodParams, selected: Bool
    ) -> NSAttributedString {
        let brand = STPCardValidator.brand(forNumber: paymentMethodParams.card?.number ?? "")
        return buildAttributedString(
            with: brand,
            last4: paymentMethodParams.card?.last4 ?? "",
            selected: selected)
    }

    func buildAttributedString(with bankBrand: STPFPXBankBrand, selected: Bool)
        -> NSAttributedString
    {
        let label = (STPFPXBank.stringFrom(bankBrand) ?? "") + " (FPX)"
        let primaryColor = primaryColorForPaymentOption(withSelected: selected)
        return NSAttributedString(
            string: label,
            attributes: [
                NSAttributedString.Key.foregroundColor: primaryColor
            ])
    }

    func buildAttributedString(
        with brand: STPCardBrand,
        last4: String,
        selected: Bool
    ) -> NSAttributedString {
        let format = STPLocalizedString(
            "%1$@ ending in %2$@",
            "Details of a saved card. '{card brand} ending in {last 4}' e.g. 'VISA ending in 4242'"
        )
        let brandString = STPCard.string(from: brand)
        let label = String(format: format, brandString, last4)

        let primaryColor = selected ? theme.accentColor : theme.primaryForegroundColor

        let secondaryColor: UIColor = {
            if #available(iOS 13.0, *) {
                return UIColor(dynamicProvider: { _ in
                    return primaryColor.withAlphaComponent(0.6)
                })
            } else {
                return primaryColor.withAlphaComponent(0.6)
            }
        }()

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: secondaryColor,
            NSAttributedString.Key.font: self.theme.font,
        ]

        let attributedString = NSMutableAttributedString(
            string: label, attributes: attributes as [NSAttributedString.Key: Any])
        attributedString.addAttribute(
            .foregroundColor, value: primaryColor, range: (label as NSString).range(of: brandString)
        )
        attributedString.addAttribute(
            .foregroundColor, value: primaryColor, range: (label as NSString).range(of: last4))
        attributedString.addAttribute(
            .font, value: theme.emphasisFont, range: (label as NSString).range(of: brandString))
        attributedString.addAttribute(
            .font, value: theme.emphasisFont, range: (label as NSString).range(of: last4))

        return attributedString
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

private let kDefaultIconWidth: CGFloat = 26.0
private let kPadding: CGFloat = 15.0
private let kCheckmarkWidth: CGFloat = 14.0
