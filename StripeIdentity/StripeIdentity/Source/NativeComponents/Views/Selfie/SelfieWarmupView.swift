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
        static let contentInset: NSDirectionalEdgeInsets = .init(
            top: 132,
            leading: 16,
            bottom: 0,
            trailing: 16
        )
        static let warmupIconImageSpacing: CGFloat = 27
        static let warmupTitleSpacing: CGFloat = 12
    }

    private let stackView: UIStackView = {
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
        addAndPinSubview(stackView, insets: Styling.contentInset)

        stackView.addArrangedSubview(selfieWarmupIconImageView)
        stackView.addArrangedSubview(selfieWarmupTitleLabel)
        stackView.addArrangedSubview(selfieWarmupBodyLabel)

        stackView.setCustomSpacing(Styling.warmupIconImageSpacing, after: selfieWarmupIconImageView)
        stackView.setCustomSpacing(Styling.warmupTitleSpacing, after: selfieWarmupTitleLabel)
    }
}
