//
//  SelfieWarmup.swift
//  StripeIdentity
//
//  Created by Chen Cen on 8/15/23.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

class SelfieWarmupView: UIView {
    struct Styling {
        static let horizontalInset: CGFloat = 16
        static let heroHeight: CGFloat = 176
        static let iconSize: CGFloat = 144
        static let cardCornerRadius: CGFloat = 32
        static let cardInsets: NSDirectionalEdgeInsets = .init(
            top: 32,
            leading: 24,
            bottom: 40,
            trailing: 24
        )
        static let warmupTitleSpacing: CGFloat = 12
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()
    private let heroView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    private let cardWrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    private let cardTopBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = Styling.cardCornerRadius
        view.layer.cornerCurve = .continuous
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true
        return view
    }()

    private let cardStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    private let selfieWarmupIconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.image = Image.iconSelfieWarmup.makeImage(template: true)
        imageView.tintColor = IdentityUI.iconColor
        return imageView
    }()

    private let selfieWarmupTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = IdentityUI.titleFont
        label.accessibilityTraits = [.header]
        label.adjustsFontForContentSizeCategory = true
        label.text = String.Localized.selfieWarmupTitle
        return label
    }()

    private let selfieWarmupBodyLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = IdentityUI.instructionsFont
        label.adjustsFontForContentSizeCategory = true
        label.text = String.Localized.selfieWarmupBody
        return label
    }()

    init() {
        super.init(frame: .zero)
        installViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SelfieWarmupView {
    fileprivate func installViews() {
        backgroundColor = .systemBackground
        addAndPinSubview(stackView)

        stackView.addArrangedSubview(heroView)
        stackView.addArrangedSubview(cardWrapperView)

        heroView.addSubview(selfieWarmupIconImageView)
        cardWrapperView.addSubview(cardTopBackgroundView)
        cardWrapperView.addSubview(cardView)
        cardView.addAndPinSubview(cardStackView, insets: Styling.cardInsets)

        cardStackView.addArrangedSubview(selfieWarmupTitleLabel)
        cardStackView.addArrangedSubview(selfieWarmupBodyLabel)
        cardStackView.setCustomSpacing(Styling.warmupTitleSpacing, after: selfieWarmupTitleLabel)

        selfieWarmupIconImageView.translatesAutoresizingMaskIntoConstraints = false
        cardTopBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        cardView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heroView.heightAnchor.constraint(equalToConstant: Styling.heroHeight),
            selfieWarmupIconImageView.centerXAnchor.constraint(equalTo: heroView.centerXAnchor),
            selfieWarmupIconImageView.centerYAnchor.constraint(equalTo: heroView.centerYAnchor),
            selfieWarmupIconImageView.widthAnchor.constraint(equalToConstant: Styling.iconSize),
            selfieWarmupIconImageView.heightAnchor.constraint(equalToConstant: Styling.iconSize),
            cardTopBackgroundView.topAnchor.constraint(equalTo: cardWrapperView.topAnchor),
            cardTopBackgroundView.leadingAnchor.constraint(equalTo: cardWrapperView.leadingAnchor),
            cardTopBackgroundView.trailingAnchor.constraint(equalTo: cardWrapperView.trailingAnchor),
            cardTopBackgroundView.heightAnchor.constraint(equalToConstant: Styling.cardCornerRadius),
            cardView.topAnchor.constraint(equalTo: cardWrapperView.topAnchor),
            cardView.leadingAnchor.constraint(
                equalTo: cardWrapperView.leadingAnchor,
                constant: Styling.horizontalInset
            ),
            cardView.trailingAnchor.constraint(
                equalTo: cardWrapperView.trailingAnchor,
                constant: -Styling.horizontalInset
            ),
            cardView.bottomAnchor.constraint(equalTo: cardWrapperView.bottomAnchor),
        ])
    }
}
