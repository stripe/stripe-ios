//
//  STPShippingMethodTableViewCell.swift
//  Stripe
//
//  Created by Ben Guo on 8/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import PassKit
import UIKit

class STPShippingMethodTableViewCell: UITableViewCell {
    private var _theme: STPTheme?
    var theme: STPTheme? {
        get {
            _theme
        }
        set(theme) {
            _theme = theme
            updateAppearance()
        }
    }

    func setShippingMethod(_ method: PKShippingMethod, currency: String) {
        shippingMethod = method
        titleLabel?.text = method.label
        subtitleLabel?.text = method.detail
        var localeInfo = [
            NSLocale.Key.currencyCode.rawValue: currency
        ]
        localeInfo[NSLocale.Key.languageCode.rawValue] = NSLocale.preferredLanguages.first ?? ""
        let localeID = NSLocale.localeIdentifier(fromComponents: localeInfo)
        let locale = NSLocale(localeIdentifier: localeID)
        numberFormatter?.locale = locale as Locale
        let amount = method.amount.stp_amount(withCurrency: currency)
        if amount == 0 {
            amountLabel?.text = STPLocalizedString("Free", "Label for free shipping method")
        } else {
            let number = NSDecimalNumber.stp_decimalNumber(
                withAmount: amount,
                currency: currency)
            amountLabel?.text = numberFormatter?.string(from: number)
        }
        setNeedsLayout()
    }

    private weak var titleLabel: UILabel?
    private weak var subtitleLabel: UILabel?
    private weak var amountLabel: UILabel?
    private weak var checkmarkIcon: UIImageView?
    private var shippingMethod: PKShippingMethod?
    private var numberFormatter: NumberFormatter?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        theme = STPTheme()
        let titleLabel = UILabel()
        self.titleLabel = titleLabel
        let subtitleLabel = UILabel()
        self.subtitleLabel = subtitleLabel
        let amountLabel = UILabel()
        self.amountLabel = amountLabel
        let checkmarkIcon = UIImageView(image: STPImageLibrary.checkmarkIcon())
        self.checkmarkIcon = checkmarkIcon
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.usesGroupingSeparator = true
        numberFormatter = formatter
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(checkmarkIcon)
        updateAppearance()
    }

    override var isSelected: Bool {
        get {
            return super.isSelected
        }
        set(selected) {
            super.isSelected = selected
            updateAppearance()
        }
    }

    @objc func updateAppearance() {
        contentView.backgroundColor = theme?.secondaryBackgroundColor
        backgroundColor = UIColor.clear
        titleLabel?.font = theme?.font
        subtitleLabel?.font = theme?.smallFont
        amountLabel?.font = theme?.font
        titleLabel?.textColor = isSelected ? theme?.accentColor : theme?.primaryForegroundColor
        amountLabel?.textColor = titleLabel?.textColor
        var subduedAccentColor: UIColor?
        if #available(iOS 13.0, *) {
            subduedAccentColor = UIColor(dynamicProvider: { _ in
                return self.theme?.accentColor.withAlphaComponent(0.6) ?? UIColor.clear
            })
        } else {
            subduedAccentColor = theme?.accentColor.withAlphaComponent(0.6)
        }
        subtitleLabel?.textColor = isSelected ? subduedAccentColor : theme?.secondaryForegroundColor
        checkmarkIcon?.tintColor = theme?.accentColor
        checkmarkIcon?.isHidden = !isSelected
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let midY = bounds.midY
        checkmarkIcon?.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
        checkmarkIcon?.center = CGPoint(
            x: bounds.width - 15 - (checkmarkIcon?.bounds.midX ?? 0.0), y: midY)
        amountLabel?.sizeToFit()
        amountLabel?.center = CGPoint(
            x: (checkmarkIcon?.frame.minX ?? 0.0) - 15 - (amountLabel?.bounds.midX ?? 0.0), y: midY)
        let labelWidth = (amountLabel?.frame.minX ?? 0.0) - 30
        titleLabel?.sizeToFit()
        titleLabel?.frame = CGRect(
            x: 15, y: 8, width: labelWidth, height: titleLabel?.frame.size.height ?? 0.0)
        subtitleLabel?.sizeToFit()
        subtitleLabel?.frame = CGRect(
            x: 15, y: bounds.size.height - 8 - (subtitleLabel?.frame.size.height ?? 0.0),
            width: labelWidth, height: subtitleLabel?.frame.size.height ?? 0.0)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
