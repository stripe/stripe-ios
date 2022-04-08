//
//  BankAccountInfoView.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

protocol BankAccountInfoViewDelegate {
    func didTapXIcon()
}

/// For internal SDK use only
@objc(STP_Internal_BankAccountInfoView)
class BankAccountInfoView: UIView {
    struct Constants {
        static let spacing: CGFloat = 12
    }

    lazy var bankNameLabel: UILabel = {
        let label = UILabel()
        label.font = ElementsUITheme.current.fonts.subheadline
        label.textColor = ElementsUITheme.current.colors.bodyText
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = false
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    lazy var bankAccountNumberLabel: UILabel = {
        let label = UILabel()
        label.font = ElementsUITheme.current.fonts.subheadline
        label.textColor = ElementsUITheme.current.colors.bodyText
        label.numberOfLines = 0
        return label
    }()

    lazy var bankIconImageView: UIImageView = {
        // TODO: MOBILESDK-770: Do lookup based on bank name
        let bankIcon = STPImageLibrary.bankIcon(for: nil)
        return UIImageView(image: bankIcon)
    }()

    lazy var xIcon: UIImageView = {
        let xIcon = UIImageView(image: Image.icon_x_standalone.makeImage())
        xIcon.isUserInteractionEnabled = true
        return xIcon
    }()

    lazy var xIconTappableArea: UIView = {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = true
        return view
    }()

    var delegate: BankAccountInfoViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addViewComponents()
        addTouchCallbackForX()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func addViewComponents() {
        bankIconImageView.translatesAutoresizingMaskIntoConstraints = false
        bankNameLabel.translatesAutoresizingMaskIntoConstraints = false
        bankAccountNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        xIcon.translatesAutoresizingMaskIntoConstraints = false
        xIconTappableArea.translatesAutoresizingMaskIntoConstraints = false

        addSubview(bankIconImageView)
        addSubview(bankNameLabel)
        addSubview(bankAccountNumberLabel)
        xIconTappableArea.addSubview(xIcon)
        addSubview(xIconTappableArea)

        NSLayoutConstraint.activate([
            bankIconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            bankIconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.spacing),

            bankNameLabel.leadingAnchor.constraint(equalTo: bankIconImageView.trailingAnchor, constant: Constants.spacing),
            bankNameLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.5),
            bankNameLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constants.spacing),
            bankNameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.spacing),

            bankAccountNumberLabel.leadingAnchor.constraint(equalTo: bankNameLabel.trailingAnchor, constant: Constants.spacing),
            bankAccountNumberLabel.topAnchor.constraint(equalTo: topAnchor, constant: Constants.spacing),
            bankAccountNumberLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.spacing),

            xIconTappableArea.leadingAnchor.constraint(greaterThanOrEqualTo: bankAccountNumberLabel.trailingAnchor, constant: Constants.spacing),
            xIconTappableArea.trailingAnchor.constraint(equalTo: trailingAnchor),
            xIconTappableArea.topAnchor.constraint(equalTo: topAnchor),
            xIconTappableArea.bottomAnchor.constraint(equalTo: bottomAnchor),

            xIcon.leadingAnchor.constraint(greaterThanOrEqualTo: xIconTappableArea.leadingAnchor, constant: Constants.spacing),
            xIcon.trailingAnchor.constraint(equalTo: xIconTappableArea.trailingAnchor, constant: -Constants.spacing),
            xIcon.centerYAnchor.constraint(equalTo: xIconTappableArea.centerYAnchor),
            xIcon.heightAnchor.constraint(equalToConstant: Constants.spacing),
            xIcon.widthAnchor.constraint(equalToConstant: Constants.spacing),
        ])
    }

    func addTouchCallbackForX() {
        let touchItem = UITapGestureRecognizer(target: self, action: #selector(didTapXIcon))
        xIconTappableArea.addGestureRecognizer(touchItem)
    }

    @objc func didTapXIcon() {
        self.delegate?.didTapXIcon()
    }

    func setBankName(text: String) {
        self.bankNameLabel.text = text
    }

    func setLastFourOfBank(text: String) {
        self.bankAccountNumberLabel.text = text
    }
}
