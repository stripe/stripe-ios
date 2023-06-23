//
//  LinkBankAccountInfoView.swift
//  StripePaymentSheet
//
//  Created by Vardges Avetisyan on 6/22/23.
//

import UIKit
@_spi(STP) import StripeUICore

final class LinkBankAccountInfoView: UIView {
    struct Constants {
        static let contentSpacing: CGFloat = 4
        static let iconSize = CGSize(width: 30, height: 20)
        static let maxFontSize: CGFloat = 20
    }

    private lazy var bankIconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        iconView.tintColor = .systemGray2
        return iconView
    }()

    private let primaryLabel: UILabel = {
        let label = UILabel()
        label.adjustsFontForContentSizeCategory = true
        label.font = LinkUI.font(forTextStyle: .bodyEmphasized, maximumPointSize: Constants.maxFontSize)
        label.textColor = .linkPrimaryText
        return label
    }()

    private let secondaryLabel: UILabel = {
        let label = UILabel()
        label.font = LinkUI.font(forTextStyle: .caption, maximumPointSize: Constants.maxFontSize)
        label.textColor = .linkSecondaryText
        return label
    }()

    private lazy var iconContainerView: UIView = {
        let view = UIView()
        bankIconView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(bankIconView)

        NSLayoutConstraint.activate([
            bankIconView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
            bankIconView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
            bankIconView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
            bankIconView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
            bankIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            bankIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

        return view
    }()

    private lazy var stackView: UIStackView = {
        let labelStackView = UIStackView(arrangedSubviews: [
            primaryLabel,
            secondaryLabel,
        ])
        labelStackView.axis = .vertical
        labelStackView.alignment = .leading
        labelStackView.spacing = 2

        let stackView = UIStackView(arrangedSubviews: [
            iconContainerView,
            labelStackView,
        ])

        stackView.spacing = Constants.contentSpacing
        stackView.distribution = .fillProportionally
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addAndPinSubview(stackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setBankAccountInfo(iconCode: String?, bankName: String?, last4: String?) {
        bankIconView.image = PaymentSheetImageLibrary.bankIcon(for: iconCode)
        primaryLabel.text = bankName
        if let last4 = last4 {
            secondaryLabel.text = "••••\(last4)"
        }
    }
}
