//
//  LinkPaymentTypePicker.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 5/15/25.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

/// For internal SDK use only
@objc(STP_Internal_LinkPaymentTypePicker)
final class LinkPaymentTypePicker: UIView {
    enum Constants {
        static let bankIconSize = CGSize(width: 20, height: 20)
        static let cardIconSize = CGSize(width: 20, height: 15)
        static let iconBackgroundSize = CGSize(width: 40, height: 40)
    }
    enum PaymentType {
        case card
        case bank

        var icon: UIImage {
            switch self {
            case .card:
                LinkIconGenerator.cardIcon(
                    backgroundSize: Constants.iconBackgroundSize,
                    iconSize: Constants.cardIconSize
                )
            case .bank:
                LinkIconGenerator.bankIcon(
                    backgroundSize: Constants.iconBackgroundSize,
                    iconSize: Constants.bankIconSize
                )
            }
        }

        var label: String {
            switch self {
            case .card:
                STPLocalizedString(
                    "Debit or credit card",
                    "Label shown in the payment type picker describing a card payment"
                )
            case .bank:
                STPLocalizedString(
                    "Bank",
                    "Label shown in the payment type picker describing a bank payment"
                )
            }
        }
    }

    private let bankCell = Cell(type: .bank)
    private let separatorView = LinkSeparatorView()
    private let cardCell = Cell(type: .card)

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            bankCell,
            separatorView,
            cardCell,
        ])

        stackView.axis = .vertical
        stackView.clipsToBounds = true
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addAndPinSubview(stackView)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        clipsToBounds = true
        accessibilityIdentifier = "Stripe.Link.LinkPaymentTypePicker"

        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor.linkControlBorder.cgColor
        tintColor = .linkBrand
        backgroundColor = .linkControlBackground

        bankCell.addTarget(self, action: #selector(onBankCellTapped), for: .touchUpInside)
        cardCell.addTarget(self, action: #selector(onCardCellTapped), for: .touchUpInside)
    }

    @objc private func onBankCellTapped() {

    }

    @objc private func onCardCellTapped() {

    }
}
