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
            top: 56,
            leading: 16,
            bottom: 0,
            trailing: 16
        )
        static let warmupTitleSpacing: CGFloat = 12
        static let warmupBodySpacing: CGFloat = 64
        static let warmupIconSpacing: CGFloat = 72
        static let consentTitleSpacing: CGFloat = 12
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

    private let trainingConsentTitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = IdentityUI.preferredFont(forTextStyle: .headline, weight: .semibold)
        label.adjustsFontForContentSizeCategory = true
        label.text = String.Localized.selfieWarmupTrainingConsentTitle
        label.isHidden = true
        return label
    }()

    private let trainingConsentTextView: HTMLTextView = {
        let view = HTMLTextView()
        view.isHidden = true
        return view
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
    func configure(
        trainingConsentText: String?,
        didOpenURL: @escaping (URL) -> Void
    ) throws {
        guard let trainingConsentText, !trainingConsentText.isEmpty else {
            trainingConsentTitleLabel.isHidden = true
            trainingConsentTextView.isHidden = true
            return
        }

        try trainingConsentTextView.configure(
            with: .init(
                text: trainingConsentText,
                style: .html(makeStyle: SelfieWarmupView.trainingConsentHTMLStyle),
                didOpenURL: didOpenURL
            )
        )
        trainingConsentTitleLabel.isHidden = false
        trainingConsentTextView.isHidden = false
    }
    fileprivate func installViews() {
        addAndPinSubview(stackView, insets: Styling.contentInset)

        stackView.addArrangedSubview(selfieWarmupTitleLabel)
        stackView.addArrangedSubview(selfieWarmupBodyLabel)
        stackView.addArrangedSubview(selfieWarmupIconImageView)
        stackView.addArrangedSubview(trainingConsentTitleLabel)
        stackView.addArrangedSubview(trainingConsentTextView)

        stackView.setCustomSpacing(Styling.warmupTitleSpacing, after: selfieWarmupTitleLabel)
        stackView.setCustomSpacing(Styling.warmupBodySpacing, after: selfieWarmupBodyLabel)
        stackView.setCustomSpacing(Styling.warmupIconSpacing, after: selfieWarmupIconImageView)
        stackView.setCustomSpacing(Styling.consentTitleSpacing, after: trainingConsentTitleLabel)
    }

    fileprivate static func trainingConsentHTMLStyle() -> HTMLStyle {
        let contentColor = IdentityUI.htmlLineTextColor
        let boldFont = IdentityUI.preferredFont(forTextStyle: .caption1, weight: .bold)
        return .init(
            bodyFont: IdentityUI.preferredFont(forTextStyle: .caption1),
            bodyColor: contentColor,
            h1Font: boldFont,
            h2Font: boldFont,
            h3Font: boldFont,
            h4Font: boldFont,
            h5Font: boldFont,
            h6Font: boldFont,
            isLinkUnderlined: true,
            shouldCenterText: true,
            linkColor: contentColor
        )
    }
}
