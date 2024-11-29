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
    
    init(
        appearance: PaymentSheet.Appearance,
        cornerRadius: CGFloat? = nil,
        tinyMode: Bool,
        text: String? = nil
    ) {
        super.init(frame: .zero)
        setupView(tinyMode: tinyMode)
        setAppearance(appearance)
        
        if let cornerRadius {
            // In embedded mode with checkmarks, the `appearance` corner radius might not be what the
            // merchant has specified. We use the original corner radius instead.
            labelBackground.layer.cornerRadius = cornerRadius
        }
        
        if let text {
            setText(text)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setAppearance(_ appearance: PaymentSheet.Appearance) {
        let backgroundColor = appearance.primaryButton.successBackgroundColor
        let foregroundColor = appearance.primaryButton.successTextColor ?? appearance.primaryButton.textColor ?? backgroundColor.contrastingColor
        
        labelBackground.backgroundColor = backgroundColor
        labelBackground.layer.cornerRadius = appearance.cornerRadius
        label.font = appearance.scaledFont(
            for: appearance.font.base.medium,
            style: .caption1,
            maximumPointSize: 20
        )
        label.numberOfLines = 1
        label.textColor = foregroundColor
    }
    
    func setText(_ text: String) {
        label.text = formatPromoText(text)
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
    
    private func formatPromoText(_ text: String) -> String {
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
