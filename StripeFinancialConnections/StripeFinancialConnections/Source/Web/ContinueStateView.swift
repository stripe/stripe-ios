//
//  ContinueStateView.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 10/5/22.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

class ContinueStateView: UIView {
    
    // MARK: - Properties
    
    let primaryButton: Button
    
    // MARK: - UIView
    
    override init(frame: CGRect) {
        var primaryButtonConfiguration = Button.Configuration.primary()
        let appleTextStyle = UIFont.TextStyle.body
        let metrics = UIFontMetrics(forTextStyle: appleTextStyle)
        
        let font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        let scaledFont = metrics.scaledFont(for: font)

        primaryButtonConfiguration.font = scaledFont
        primaryButtonConfiguration.backgroundColor = UIColor(red: 99 / 255.0, green: 91 / 255.0, blue: 255 / 255.0, alpha: 1) // #635bff
        primaryButtonConfiguration.foregroundColor = .white
        primaryButtonConfiguration.disabledBackgroundColor = primaryButtonConfiguration.backgroundColor
        primaryButtonConfiguration.disabledForegroundColor = primaryButtonConfiguration.foregroundColor

        primaryButton = Button(configuration: primaryButtonConfiguration)

        super.init(frame: .zero)
        
        self.translatesAutoresizingMaskIntoConstraints = false

        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        labelStackView.spacing = 8
        
        let titleLabel = UILabel()
        titleLabel.text = STPLocalizedString("Continue linking your account", "Title for a label of a screen telling users to tap below to continue linking process.")
        titleLabel.font = UIFontMetrics(forTextStyle: .title2).scaledFont(for: UIFont.systemFont(ofSize: 24, weight: .bold))
        titleLabel.textColor = UIColor(red: 48 / 255.0, green: 49 / 255.0, blue: 61 / 255.0, alpha: 1)
        titleLabel.numberOfLines = 0
        labelStackView.addArrangedSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = STPLocalizedString("You haven't finished linking your account. Press continue to finish the process.", "Title for a label explaining that the linking process hasn't finished yet.")
        subtitleLabel.textColor = UIColor(red: 106 / 255.0, green: 115 / 255.0, blue: 131 / 255.0, alpha: 1) // #6a7383
        subtitleLabel.numberOfLines = 0
        let subtitleFont = UIFont.systemFont(ofSize: 16, weight: .medium)
        subtitleLabel.font = metrics.scaledFont(for: subtitleFont)
        labelStackView.addArrangedSubview(subtitleLabel)

        self.addSubview(labelStackView)
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelStackView.widthAnchor.constraint(equalTo: self.widthAnchor),
            labelStackView.topAnchor.constraint(equalTo: self.topAnchor, constant: 48),
        ])

        primaryButton.title = String.Localized.continue
        primaryButton.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(primaryButton)
        
        NSLayoutConstraint.activate([
            primaryButton.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            primaryButton.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            primaryButton.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            primaryButton.heightAnchor.constraint(equalToConstant: 56),
        ])

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
