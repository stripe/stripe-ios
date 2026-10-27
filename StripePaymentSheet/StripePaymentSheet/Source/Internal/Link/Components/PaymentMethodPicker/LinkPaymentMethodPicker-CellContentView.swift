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
            static let genericIconCornerRadius: CGFloat = 3.0
            static let maxFontSize: CGFloat = 20
        }

        private let downloadManager: DownloadManager

        /// Whether the remote `display.icon.default` image is currently displayed in place of the local icon.
        private var isShowingRemoteIcon = false

        var paymentMethod: ConsumerPaymentDetails? {
            didSet {
                // Avoid resetting the icon and re-downloading it when reconfigured with the same payment method.
                guard paymentMethod !== oldValue else {
                    return
                }
                isShowingRemoteIcon = false
                switch paymentMethod?.details {
                case .card(let card):
                    cardBrandView.setCardBrand(STPCard.brand(from: card.brand))
                    showIconView(cardBrandView)
                    primaryLabel.text = paymentMethod?.paymentSheetLabel
                    let hasDisplayName = card.displayName(with: paymentMethod?.nickname) != nil
                    secondaryLabel.text = hasDisplayName ? card.secondaryName : nil
                    secondaryLabel.isHidden = !hasDisplayName
                case .bankAccount(let bankAccount):
                    bankIconView.image = makeBankIcon(for: bankAccount.iconCode)
                    showIconView(bankIconView)
                    primaryLabel.text = bankAccount.displayName(with: paymentMethod?.nickname)
                    secondaryLabel.text = "•••• \(bankAccount.last4)"
                    secondaryLabel.isHidden = false
                case .generic:
                    guard let display = paymentMethod?.display else {
                        showIconView(nil)
                        primaryLabel.text = nil
                        secondaryLabel.text = nil
                        secondaryLabel.isHidden = true
                        break
                    }
                    genericIconView.image = createGenericPaymentMethodIcon()
                    showIconView(genericIconView)
                    primaryLabel.text = display.label
                    secondaryLabel.text = display.sublabel
                    secondaryLabel.isHidden = display.sublabel == nil || display.sublabel?.isEmpty == true
                case .none:
                    showIconView(nil)
                    primaryLabel.text = nil
                    secondaryLabel.text = nil
                    secondaryLabel.isHidden = true
                }
                loadRemoteIconIfNeeded()
            }
        }

        private lazy var bankIconView: UIImageView = {
            let iconView = UIImageView()
            iconView.contentMode = .scaleAspectFit
            return iconView
        }()

        private lazy var genericIconView: UIImageView = {
            let iconView = UIImageView()
            iconView.contentMode = .scaleAspectFit
            iconView.clipsToBounds = true
            iconView.layer.cornerRadius = Constants.genericIconCornerRadius
            return iconView
        }()

        private lazy var cardBrandView: CardBrandView = CardBrandView(centerHorizontally: true)

        /// Displays the remote `display.icon.default` image for cards, which uses the same rectangular size as the card brand image.
        private lazy var remoteCardIconView: UIImageView = {
            let iconView = UIImageView()
            iconView.contentMode = .scaleAspectFit
            iconView.clipsToBounds = true
            iconView.layer.cornerRadius = Constants.genericIconCornerRadius
            return iconView
        }()

        private var iconViews: [UIView] {
            [bankIconView, cardBrandView, remoteCardIconView, genericIconView]
        }

        private let primaryLabel: UILabel = {
            let label = UILabel()
            label.adjustsFontForContentSizeCategory = true
            label.font = LinkUI.font(forTextStyle: .bodyEmphasized, maximumPointSize: Constants.maxFontSize)
            label.textColor = .linkTextPrimary
            return label
        }()

        private let secondaryLabel: UILabel = {
            let label = UILabel()
            label.font = LinkUI.font(forTextStyle: .caption, maximumPointSize: Constants.maxFontSize)
            label.textColor = .linkTextTertiary
            return label
        }()

        private lazy var iconContainerView: UIView = {
            let view = UIView()
            bankIconView.translatesAutoresizingMaskIntoConstraints = false
            cardBrandView.translatesAutoresizingMaskIntoConstraints = false
            remoteCardIconView.translatesAutoresizingMaskIntoConstraints = false
            genericIconView.translatesAutoresizingMaskIntoConstraints = false

            view.addSubview(bankIconView)
            view.addSubview(cardBrandView)
            view.addSubview(remoteCardIconView)
            view.addSubview(genericIconView)

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

                remoteCardIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                remoteCardIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                // `cardBrandSize` includes padding around the brand image, so size remote card icons to match the visible brand image instead.
                remoteCardIconView.widthAnchor.constraint(equalToConstant: Constants.iconSize.width),
                remoteCardIconView.heightAnchor.constraint(equalToConstant: Constants.iconSize.height),

                genericIconView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor),
                genericIconView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor),
                genericIconView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor),
                genericIconView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor),
                genericIconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                genericIconView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

                // generic payment method icons will be squares, so use the largest dimension of our icon size
                genericIconView.widthAnchor.constraint(equalToConstant: max(Constants.iconSize.width, Constants.iconSize.height)),
                genericIconView.heightAnchor.constraint(equalTo: genericIconView.widthAnchor),
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

        init(downloadManager: DownloadManager = .sharedManager) {
            self.downloadManager = downloadManager
            super.init(frame: .zero)
            addAndPinSubview(stackView)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func makeBankIcon(for bankName: String?) -> UIImage {
            if let institutionIcon = PaymentSheetImageLibrary.bankInstitutionIcon(for: bankName) {
                return institutionIcon
            }
            return createGenericPaymentMethodIcon()
        }

        private func createGenericPaymentMethodIcon() -> UIImage {
            let icon = PaymentSheetImageLibrary.linkBankIcon()
            let iconColor: UIColor = .linkIconPrimary
            let backgroundColor: UIColor = .linkSurfaceTertiary

            let iconSize: CGSize = .init(width: 16, height: 16)
            let backgroundSize: CGSize = .init(width: 24, height: 24)

            let renderer = UIGraphicsImageRenderer(size: backgroundSize)
            return renderer.image { _ in
                let rect = CGRect(origin: .zero, size: backgroundSize)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: Constants.genericIconCornerRadius)

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

        /// Shows `iconView` and hides all other icon views.
        private func showIconView(_ iconView: UIView?) {
            for view in iconViews {
                view.isHidden = view !== iconView
            }
        }

        /// Replaces the local icon with the remote `display.icon.default` image once it's available.
        /// The local icon remains visible while the image downloads, or if the download fails.
        private func loadRemoteIconIfNeeded() {
            guard let paymentMethod, let url = paymentMethod.display?.icon?.main else {
                return
            }

            // Cards use a rectangular icon, while bank accounts and other payment methods use a square icon.
            let remoteIconView: UIImageView
            switch paymentMethod.details {
            case .card:
                remoteIconView = remoteCardIconView
            case .bankAccount, .generic:
                remoteIconView = genericIconView
            }

            let placeholder = UIImage()
            let image = downloadManager.downloadImage(
                url: url,
                placeholder: placeholder,
                updateHandler: { [weak self] image in
                    DispatchQueue.main.async {
                        // Ignore the image if this view has since been configured with a different payment method.
                        guard let self, self.paymentMethod === paymentMethod else {
                            return
                        }
                        self.showRemoteIcon(image, in: remoteIconView)
                    }
                }
            )
            if image !== placeholder {
                showRemoteIcon(image, in: remoteIconView)
            }
        }

        private func showRemoteIcon(_ image: UIImage, in iconView: UIImageView) {
            iconView.image = image
            showIconView(iconView)
            isShowingRemoteIcon = true
        }

        private func refreshBankIconIfNeeded() {
            guard case .bankAccount(let bankAccount) = paymentMethod?.details else {
                return
            }
            bankIconView.image = makeBankIcon(for: bankAccount.iconCode)
        }

        private func refreshGenericIconIfNeeded() {
            guard case .generic = paymentMethod?.details, !isShowingRemoteIcon else {
                return
            }
            genericIconView.image = createGenericPaymentMethodIcon()
        }

        // UIImages need to be manually updated when the system theme changes.
        #if !os(visionOS)
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
                return
            }
            refreshBankIconIfNeeded()
            refreshGenericIconIfNeeded()
        }
        #endif
    }

}
