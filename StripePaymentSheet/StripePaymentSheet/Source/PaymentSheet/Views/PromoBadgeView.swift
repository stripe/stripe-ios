//
//  PromoBadgeView.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 11/19/24.
//

import UIKit

@_spi(STP) import StripeUICore

class PromoBadgeView: UIView {
    
    private let labelBackground = UIView()
    private let label = UILabel()
    
    private var appearance: PaymentSheet.Appearance
    private var cornerRadius: CGFloat?
    private var text: String?
    private var eligible: Bool
    
    override var intrinsicContentSize: CGSize {
        CGSize(
            width: labelBackground.layoutMargins.left + label.intrinsicContentSize.width + labelBackground.layoutMargins.right,
            height: labelBackground.layoutMargins.top + label.intrinsicContentSize.height + labelBackground.layoutMargins.bottom
        )
    }
    
    init(
        appearance: PaymentSheet.Appearance,
        cornerRadius: CGFloat? = nil,
        tinyMode: Bool,
        text: String? = nil
    ) {
        self.appearance = appearance
        self.cornerRadius = cornerRadius
        self.eligible = true
        self.text = text
        super.init(frame: .zero)
        
        setupView(tinyMode: tinyMode)
        updateAppearance()
        
        if let text {
            updateText(text)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()
    }
    
    func setAppearance(_ appearance: PaymentSheet.Appearance) {
        self.appearance = appearance
        updateAppearance()
    }
    
    func setText(_ text: String) {
        self.text = text
        updateText(text)
    }
    
    func setEligible(_ eligible: Bool) {
        self.eligible = eligible
        updateText(text)
    }
    
    private func updateText(_ text: String?) {
        guard let text else {
            return
        }
        
        label.text = formatPromoText(text, eligible: eligible)
        updateAppearance()
        invalidateIntrinsicContentSize()
    }
    
    private func updateAppearance() {
        let backgroundColor = if eligible {
            appearance.primaryButton.successBackgroundColor
        } else {
            appearance.colors.componentBorder
        }
        
        let foregroundColor = if eligible {
            appearance.primaryButton.successTextColor ?? appearance.primaryButton.textColor ?? backgroundColor.contrastingColor
        } else {
            appearance.colors.componentText
        }
        
        // In embedded mode with checkmarks, the `appearance` corner radius might not be what the
        // merchant has specified. We use the original corner radius instead.
        labelBackground.layer.cornerRadius = cornerRadius ?? appearance.cornerRadius
        
        labelBackground.backgroundColor = backgroundColor
        label.font = appearance.scaledFont(
            for: appearance.font.base.medium,
            style: .caption1,
            maximumPointSize: 20
        )
        label.numberOfLines = 1
        label.textColor = foregroundColor
    }
    
    private func setupView(tinyMode: Bool) {
        labelBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelBackground)
        
        let verticalSpacing: CGFloat = tinyMode ? 2 : 4
        let horizontalSpacing: CGFloat = tinyMode ? 4 : 6
        labelBackground.layoutMargins = UIEdgeInsets(
            top: verticalSpacing,
            left: horizontalSpacing,
            bottom: verticalSpacing,
            right: horizontalSpacing
        )
        
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        labelBackground.addSubview(label)
        
        NSLayoutConstraint.activate([
            labelBackground.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelBackground.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: labelBackground.layoutMarginsGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: labelBackground.layoutMarginsGuide.topAnchor),
            label.trailingAnchor.constraint(equalTo: labelBackground.layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: labelBackground.layoutMarginsGuide.bottomAnchor),
        ])
    }
    
    private func formatPromoText(_ text: String, eligible: Bool) -> String {
        guard eligible else {
            let baseString = STPLocalizedString(
                "No %@ promo",
                "Label for when the user is not eligible for a promo."
            )
            return String(format: baseString, text)
        }
        
        // We have limited screen real estate, so we only show the "Get" prefix in English
        let isEnglish = Locale.current.isEnglishLanguage
        return isEnglish ? "Get \(text)" : text
    }
}

private extension Locale {
    
    var isEnglishLanguage: Bool {
        let languageCode = if #available(iOS 16, *) {
            self.language.languageCode?.identifier
        } else {
            self.languageCode?.split(separator: "-").first.flatMap { String($0) }
        }
        return languageCode == "en"
    }
}
