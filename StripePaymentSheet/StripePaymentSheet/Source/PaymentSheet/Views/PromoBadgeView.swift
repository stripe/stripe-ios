//
//  PromoBadgeView.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 11/19/24.
//

import UIKit

class PromoBadgeView: UIView {
    
    private let labelBackground = UIView()
    private let label = UILabel()
    private let tinyMode: Bool
    
    init(
        font: UIFont,
        tinyMode: Bool = false,
        text: String? = nil
    ) {
        self.tinyMode = tinyMode
        super.init(frame: .zero)
        setupView(font: font, tinyMode: tinyMode)
        
        if let text {
            setText(text)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(_ text: String) {
        label.text = formatPromoText(text)
    }
    
    private func setupView(font: UIFont, tinyMode: Bool) {
        labelBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(labelBackground)
        
        // TODO(tillh-stripe) Revisit this
        labelBackground.backgroundColor = UIColor(red: 48/255, green: 177/255, blue: 48/255, alpha: 1)
        labelBackground.layer.cornerRadius = tinyMode ? 4 : 8
        
        let verticalSpacing: CGFloat = tinyMode ? 0 : 2
        let horizontalSpacing: CGFloat = tinyMode ? 4 : 8
        labelBackground.layoutMargins = UIEdgeInsets(
            top: verticalSpacing,
            left: horizontalSpacing,
            bottom: verticalSpacing,
            right: horizontalSpacing
        )
        
        label.textColor = .white
        label.numberOfLines = 0
        label.font = font
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.text = ""
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
        // We have limited screen real estate, so we only show the "Get" prefix in some cases
        let isEnglish = Locale.current.isEnglishLanguage
        let showFullText = isEnglish && !tinyMode
        return showFullText ? "Get \(text)" : text
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
