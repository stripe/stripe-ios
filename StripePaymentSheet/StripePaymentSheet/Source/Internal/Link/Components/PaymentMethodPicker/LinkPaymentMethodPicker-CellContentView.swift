//
//  LinkPaymentMethodPicker-CellContentView.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/19/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

extension LinkPaymentMethodPicker {

    final class CellContentView: UIView {
        struct Constants {
            static let contentSpacing: CGFloat = 12
            static let iconSize: CGSize = CardBrandView.targetIconSize
            static let maxFontSize: CGFloat = 20
        }

        var paymentMethod: ConsumerPaymentDetails? {
            didSet {
                switch paymentMethod?.details {
                case .card(let card):
                    cardBrandView.setCardBrand(STPCard.brand(from: card.brand))
                    bankIconView.isHidden = true
                    cardBrandView.isHidden = false
                    primaryLabel.text = paymentMethod?.paymentSheetLabel
                    let hasDisplayName = card.displayName(with: paymentMethod?.nickname) != nil
                    secondaryLabel.text = hasDisplayName ? card.secondaryName : nil
                    secondaryLabel.isHidden = !hasDisplayName
                case .bankAccount(let bankAccount):
                    bankIconView.image = makeBankIcon(for: bankAccount.iconCode)
                    cardBrandView.isHidden = true
                    bankIconView.isHidden = false
                    primaryLabel.text = bankAccount.name
                    secondaryLabel.text = paymentMethod?.paymentSheetLabel
                    secondaryLabel.isHidden = false
                case .none, .unparsable:
                    cardBrandView.isHidden = true
                    bankIconView.isHidden = true
                    primaryLabel.text = nil
                    secondaryLabel.text = nil
                    secondaryLabel.isHidden = true
                }
            }
        }

        private lazy var bankIconView: UIImageView = {
            let iconView = UIImageView()
            iconView.contentMode = .scaleAspectFit
            return iconView
        }()

        private lazy var cardBrandView: CardBrandView = CardBrandView(centerHorizontally: true)

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
            cardBrandView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(bankIconView)
            view.addSubview(cardBrandView)

            let cardBrandSize = cardBrandView.size(for: Constants.iconSize)
            let width = max(Constants.iconSize.width, cardBrandSize.width)
            let height = max(Constants.iconSize.height, cardBrandSize.height)

            // Use the largest value in { width | height } to determine the size of the bounding square.
            let squareSize = max(width, height)
            NSLayoutConstraint.activate([
                view.widthAnchor.constraint(equalToConstant: squareSize),
                view.heightAnchor.constraint(equalToConstant: squareSize),

                bankIconView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
                bankIconView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
                bankIconView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
                bankIconView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
                bankIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                bankIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

                cardBrandView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
                cardBrandView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
                cardBrandView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
                cardBrandView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
                cardBrandView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                cardBrandView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

                cardBrandView.widthAnchor.constraint(equalToConstant: cardBrandSize.width),
                cardBrandView.heightAnchor.constraint(equalToConstant: cardBrandSize.height),
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
            labelStackView.spacing = 0

            let stackView = UIStackView(arrangedSubviews: [
                iconContainerView,
                labelStackView,
            ])

            stackView.spacing = Constants.contentSpacing
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

        private func makeBankIcon(for bankName: String?) -> UIImage {
            if let institutionIcon = PaymentSheetImageLibrary.bankInstitutionIcon(for: bankName) {
                return institutionIcon
            }
            return createGenericBankIcon()
        }

        private func createGenericBankIcon() -> UIImage {
            let icon = PaymentSheetImageLibrary.linkBankIcon()
            let iconColor: UIColor = .linkIconDefault
            let backgroundColor: UIColor = .linkIconBackground

            let iconSize: CGSize = .init(width: 16, height: 16)
            let backgroundSize: CGSize = .init(width: 24, height: 24)
            let cornerRadius: CGFloat = 3.0

            let renderer = UIGraphicsImageRenderer(size: backgroundSize)
            return renderer.image { _ in
                let rect = CGRect(origin: .zero, size: backgroundSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

                backgroundColor.setFill()
                path.fill()

                let iconRect = CGRect(
                    x: (backgroundSize.width - iconSize.width) / 2,
                    y: (backgroundSize.height - iconSize.height) / 2,
                    width: iconSize.width,
                    height: iconSize.height
                )
                icon.withTintColor(iconColor).draw(in: iconRect)
            }
        }

        private func refreshBankIconIfNeeded() {
            guard case .bankAccount(let bankAccount) = paymentMethod?.details else {
                return
            }
            bankIconView.image = makeBankIcon(for: bankAccount.iconCode)
        }

        // UIImages need to be manually updated when the system theme changes.
        #if !os(visionOS)
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
                return
            }
            refreshBankIconIfNeeded()
        }
        #endif
    }

}
