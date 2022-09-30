//
//  PrePaneView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/26/22.
//

import Foundation
import UIKit
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class PrepaneView: UIView {
    
    private let didSelectContinue: () -> Void
    
    init(
        institutionName: String,
        institutionImageUrl: String?,
        partnerName: String?,
        didSelectContinue: @escaping () -> Void
    ) {
        self.didSelectContinue = didSelectContinue
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        
        let institutionIconView = InstitutionIconView(size: .large)
        institutionIconView.setImageUrl(institutionImageUrl)
        
        let paneLayoutView = PaneWithHeaderLayoutView(
            icon: .view(institutionIconView),
            title: String(format: STPLocalizedString("Link with %@", "The title of the screen that appears before a user links their bank account. The %@ will be replaced by the banks name to form a sentence like 'Link with Bank of America'."), institutionName),
            subtitle: String(format: STPLocalizedString("A new window will open for you to log in and select the %@ account(s) you want to link.", "The description of the screen that appears before a user links their bank account. The %@ will be replaced by the banks name, ex. 'Bank of America'. "), institutionName),
            contentView: {
                let clearView = UIView()
                clearView.backgroundColor = .clear
                return clearView
            }(),
            footerView: createFooterView(partnerName: partnerName)
        )
        paneLayoutView.addTo(view: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didSelectContinueButton() {
        didSelectContinue()
    }
    
    private func createFooterView(partnerName: String?) -> UIView {
        let continueButton = Button(configuration: .financialConnectionsPrimary)
        continueButton.title = "Continue" // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.continue`
        continueButton.addTarget(self, action: #selector(didSelectContinueButton), for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            continueButton.heightAnchor.constraint(equalToConstant: 56),
        ])
        
        let footerStackView = UIStackView()
        footerStackView.axis = .vertical
        footerStackView.spacing = 20

        if let partnerName = partnerName {
            let partnersString = String(format: STPLocalizedString("Stripe works with partners like %@ to reliably offer access to thousands of financial institutions.", "Disclosure that appears right before users connect their bank account to Stripe. It's used to educate users. The %@ will be replaced by the partner name, ex. 'Finicity' or 'MX'"), partnerName)
            let learnMoreString = String.Localized.learn_more
            let learnMoreUrlString = "https://support.stripe.com/user/questions/what-is-the-relationship-between-stripe-and-stripes-service-providers"
            let partnerDisclosureView = CreateFooterPartnerDisclosureView(
                text: partnersString + " [\(learnMoreString)](\(learnMoreUrlString))"
            )
            footerStackView.addArrangedSubview(partnerDisclosureView)
        }
        footerStackView.addArrangedSubview(continueButton)

        return footerStackView
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateFooterPartnerDisclosureView(text: String) -> UIView {
    let iconImageView = UIImageView() // TODO(kgaidis): Set the partner icon
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
    horizontalStackView.layer.borderColor = UIColor.borderNeutral.cgColor
    horizontalStackView.layer.borderWidth = 1.0 / UIScreen.main.nativeScale
    
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
            institutionImageUrl: nil,
            partnerName: "Finicity",
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
