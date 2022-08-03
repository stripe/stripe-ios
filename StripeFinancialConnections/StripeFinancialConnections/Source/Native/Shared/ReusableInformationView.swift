//
//  InformationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/25/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

/// A reusable view that allows developers to quickly
/// render information.
final class ReusableInformationView: UIView {
    
    enum IconType {
        case loading
    }
    
    struct ButtonConfiguration {
        let title: String
        let action: () -> Void
    }
    
    private let padding: CGFloat = 24
    private let primaryButtonAction: (() -> Void)?
    private let secondaryButtonAction: (() -> Void)?
    
    init(
        iconType: IconType,
        title: String,
        subtitle: String,
        // the primary button is the bottom-most button
        primaryButtonConfiguration: ButtonConfiguration? = nil,
        secondaryButtonConfiguration: ButtonConfiguration? = nil
    ) {
        self.primaryButtonAction = primaryButtonConfiguration?.action
        self.secondaryButtonAction = secondaryButtonConfiguration?.action
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        
        setupHeaderView(iconType: iconType, title: title, subtitle: subtitle)
        
        if primaryButtonConfiguration != nil || secondaryButtonConfiguration != nil {
            setupFooterView(
                primaryButtonConfiguration: primaryButtonConfiguration,
                secondaryButtonConfiguration: secondaryButtonConfiguration
            )
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupHeaderView(iconType: IconType, title: String, subtitle: String) {
        let headerStackView = UIStackView(
            arrangedSubviews: [
                CreateIconView(iconType: iconType),
                CreateTitleAndSubtitleView(title: title, subtitle: subtitle),
            ]
        )
        headerStackView.axis = .vertical
        headerStackView.spacing = 16
        headerStackView.alignment = .leading
        addSubview(headerStackView)
        
        headerStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            headerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            headerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
        ])
    }
    
    private func setupFooterView(
        primaryButtonConfiguration: ButtonConfiguration?,
        secondaryButtonConfiguration: ButtonConfiguration?
    ) {
        let footerStackView = UIStackView()
        footerStackView.axis = .vertical
        footerStackView.spacing = 12
        if let secondaryButtonConfiguration = secondaryButtonConfiguration {
            let secondaryButton = Button(
                configuration: {
                    var continueButtonConfiguration = Button.Configuration.secondary()
                    continueButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
                    continueButtonConfiguration.foregroundColor = .textSecondary
                    continueButtonConfiguration.backgroundColor = .borderNeutral
                    return continueButtonConfiguration
                }()
            )
            secondaryButton.title = secondaryButtonConfiguration.title
            secondaryButton.addTarget(self, action: #selector(didSelectSecondaryButton), for: .touchUpInside)
            secondaryButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                secondaryButton.heightAnchor.constraint(equalToConstant: 56),
            ])
            footerStackView.addArrangedSubview(secondaryButton)
        }
        if let primaryButtonConfiguration = primaryButtonConfiguration {
            let primaryButton = Button(
                configuration: {
                    var continueButtonConfiguration = Button.Configuration.primary()
                    continueButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
                    continueButtonConfiguration.backgroundColor = .textBrand
                    return continueButtonConfiguration
                }()
            )
            primaryButton.title = primaryButtonConfiguration.title
            primaryButton.addTarget(self, action: #selector(didSelectPrimaryButton), for: .touchUpInside)
            primaryButton.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                primaryButton.heightAnchor.constraint(equalToConstant: 56),
            ])
            footerStackView.addArrangedSubview(primaryButton)
        }
        addSubview(footerStackView)
        footerStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            footerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            footerStackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -padding),
        ])
    }
    
    @objc private func didSelectPrimaryButton() {
        primaryButtonAction?()
    }
    
    @objc private func didSelectSecondaryButton() {
        secondaryButtonAction?()
    }
}

private func CreateIconView(iconType: ReusableInformationView.IconType) -> UIView {
    let iconContainerView = UIView()
    iconContainerView.backgroundColor = .textBrand
    iconContainerView.layer.cornerRadius = 20 // TODO(kgaidis): fix temporary "icon" styling before we get loading icons
    
    iconContainerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconContainerView.widthAnchor.constraint(equalToConstant: 40),
        iconContainerView.heightAnchor.constraint(equalToConstant: 40),
    ])
    return iconContainerView
}

private func CreateTitleAndSubtitleView(title: String, subtitle: String) -> UIView {
    let titleLabel = UILabel()
    titleLabel.font = .stripeFont(forTextStyle: .subtitle)
    titleLabel.textColor = .textPrimary
    titleLabel.numberOfLines = 0
    titleLabel.text = title
    let subtitleLabel = UILabel()
    subtitleLabel.font = .stripeFont(forTextStyle: .body)
    subtitleLabel.textColor = .textSecondary
    subtitleLabel.numberOfLines = 0
    subtitleLabel.text = subtitle
    let labelStackView = UIStackView(arrangedSubviews: [
        titleLabel,
        subtitleLabel,
    ])
    labelStackView.axis = .vertical
    labelStackView.spacing = 8
    return labelStackView
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
private struct ReusableInformationViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ReusableInformationView {
        ReusableInformationView(
            iconType: .loading,
            title: "Establishing connection",
            subtitle: "Please wait while a connection is established."
        )
    }
    
    func updateUIView(_ uiView: ReusableInformationView, context: Context) {}
}

struct ReusableInformationView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        VStack {
            ReusableInformationViewUIViewRepresentable()
                .frame(width: 320)
        }
        .frame(maxWidth: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

#endif
