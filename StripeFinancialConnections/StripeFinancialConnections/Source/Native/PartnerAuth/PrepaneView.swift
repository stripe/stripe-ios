//
//  PrePaneView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/26/22.
//

import Foundation
import UIKit
import SafariServices
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class PrepaneView: UIView {
    
    private let didSelectContinue: () -> Void
    
    init(
        institutionName: String,
        partnerName: String?,
        isSingleAccount: Bool,
        didSelectContinue: @escaping () -> Void
    ) {
        self.didSelectContinue = didSelectContinue
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        
        let headerView = CreateHeaderView(
            title: "Link with \(institutionName)",
            subtitle: "A new window will open for you to log in and select the \(institutionName) account\(isSingleAccount ? "" : "(s)") you want to link.\n\nThis page will update once you're done."
        )
        addSubview(headerView)
        let horizontalPadding: CGFloat = 24
        headerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
        ])
        
        let footerView = createFooterView(partnerName: partnerName)
        addSubview(footerView)
        footerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            footerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
            footerView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -horizontalPadding),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didSelectContinueButton() {
        didSelectContinue()
    }
    
    private func createFooterView(partnerName: String?) -> UIView {
        let continueButton = Button(configuration: {
            var continueButtonConfiguration = Button.Configuration.primary()
            continueButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
            continueButtonConfiguration.backgroundColor = .textBrand
            return continueButtonConfiguration
        }())
        continueButton.title = "Continue"
        continueButton.addTarget(self, action: #selector(didSelectContinueButton), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            continueButton.heightAnchor.constraint(equalToConstant: 56),
        ])
        
        let footerStackView = UIStackView()
        footerStackView.axis = .vertical
        footerStackView.spacing = 20

        if let partnerName = partnerName {
            let partnerDisclosureView = CreatePartnerDisclosureView(
                text: "Stripe works with partners like \(partnerName) to reliably offer access to thousands of financial institutions. [Learn more](https://support.stripe.com/user/questions/what-is-the-relationship-between-stripe-and-stripes-service-providers)"
            )
            footerStackView.addArrangedSubview(partnerDisclosureView)
        }
        footerStackView.addArrangedSubview(continueButton)

        return footerStackView
    }
}

private func CreateHeaderView(title: String, subtitle: String) -> UIView {
    let headerStackView = UIStackView(arrangedSubviews: [
        CreateIconView(),
        CreateTitleAndSubtitleView(
            title: title,
            subtitle: subtitle
        ),
    ])
    
    headerStackView.axis = .vertical
    headerStackView.spacing = 16
    headerStackView.alignment = .leading
    return headerStackView
}

private func CreateIconView() -> UIView {
    let iconContainerView = UIView()
    iconContainerView.layer.cornerRadius = 6
    iconContainerView.backgroundColor = .textDisabled // TODO(kgaidis): fix temporary "icon" styling before we get loading icons
    
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

@available(iOSApplicationExtension, unavailable)
private func CreatePartnerDisclosureView(text: String) -> UIView {

    let iconImageView = UIImageView() // TODO(kgaidis): Set the icon
    iconImageView.backgroundColor = .textDisabled
    iconImageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        iconImageView.widthAnchor.constraint(equalToConstant: 24),
        iconImageView.heightAnchor.constraint(equalToConstant: 24),
    ])
    iconImageView.layer.cornerRadius = 4
    
    let partnerDisclosureLabel = ClickableLabel()
    partnerDisclosureLabel.setText(
        text,
        font: .stripeFont(forTextStyle: .captionTight),
        linkFont: .stripeFont(forTextStyle: .captionTightEmphasized)
    )
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            iconImageView,
            partnerDisclosureLabel,
        ]
    )
    horizontalStackView.spacing = 12
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 10,
        leading: 12,
        bottom: 10,
        trailing: 12
    )
    horizontalStackView.alignment = .center
    horizontalStackView.backgroundColor = .backgroundContainer
    horizontalStackView.layer.cornerRadius = 8
    
    return horizontalStackView
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct PrepaneViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> PrepaneView {
        PrepaneView(
            institutionName: "Chase",
            partnerName: "Finicity",
            isSingleAccount: true,
            didSelectContinue: {}
        )
    }
    
    func updateUIView(_ uiView: PrepaneView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct PrepaneView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        VStack {
            PrepaneViewUIViewRepresentable()
                .frame(width: 320)
        }
        .frame(maxWidth: .infinity)
        .background(Color.purple.opacity(0.1))
    }
}

#endif
