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
        partner: FinancialConnectionsPartner?,
        isStripeDirect: Bool,
        didSelectContinue: @escaping () -> Void
    ) {
        self.didSelectContinue = didSelectContinue
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        
        let paneLayoutView = PaneWithHeaderLayoutView(
            icon: .view({
                let institutionIconView = InstitutionIconView(size: .large)
                institutionIconView.setImageUrl(institutionImageUrl)
                return institutionIconView
            }()),
            title: String(format: STPLocalizedString("Link with %@", "The title of the screen that appears before a user links their bank account. The %@ will be replaced by the banks name to form a sentence like 'Link with Bank of America'."), institutionName),
            // TODO(kgaidis): do we need a "we will only share the requested data" subtitle addition?
            subtitle: String(format: STPLocalizedString("A new window will open for you to log in and select the %@ account(s) you want to link.", "The description of the screen that appears before a user links their bank account. The %@ will be replaced by the banks name, ex. 'Bank of America'. "), institutionName),
            contentView: {
                let clearView = UIView()
                clearView.backgroundColor = .clear
                return clearView
            }(),
            footerView: CreateFooterView(
                partner: partner,
                isStripeDirect: isStripeDirect,
                view: self
            )
        )
        paneLayoutView.addTo(view: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc fileprivate func didSelectContinueButton() {
        didSelectContinue()
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateFooterView(
    partner: FinancialConnectionsPartner?,
    isStripeDirect: Bool,
    view: PrepaneView
) -> UIView {
    let continueButton = Button(configuration: .financialConnectionsPrimary)
    continueButton.title = "Continue" // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.continue`
    continueButton.addTarget(view, action: #selector(PrepaneView.didSelectContinueButton), for: .touchUpInside)
    continueButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        continueButton.heightAnchor.constraint(equalToConstant: 56),
    ])
    
    let footerStackView = UIStackView()
    footerStackView.axis = .vertical
    footerStackView.spacing = 20

    if let partner = partner {
        let partnerDisclosureView = CreatePartnerDisclosureView(
            partner: partner,
            isStripeDirect: isStripeDirect
        )
        footerStackView.addArrangedSubview(partnerDisclosureView)
    }
    footerStackView.addArrangedSubview(continueButton)

    return footerStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreatePartnerDisclosureView(
    partner: FinancialConnectionsPartner,
    isStripeDirect: Bool
) -> UIView {
    let horizontalStackView = UIStackView()
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
    
    if let partnerIcon = partner.icon {
        horizontalStackView.addArrangedSubview({
            let partnerIconImageView = UIImageView()
            partnerIconImageView.image = partnerIcon
            partnerIconImageView.layer.cornerRadius = 4
            partnerIconImageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                partnerIconImageView.widthAnchor.constraint(equalToConstant: 24),
                partnerIconImageView.heightAnchor.constraint(equalToConstant: 24),
            ])
            return partnerIconImageView
        }())
    }
    
    horizontalStackView.addArrangedSubview({
        let partnerDisclosureLabel = ClickableLabel(
            font: .stripeFont(forTextStyle: .captionTight),
            boldFont: .stripeFont(forTextStyle: .captionTightEmphasized),
            linkFont: .stripeFont(forTextStyle: .captionTightEmphasized),
            textColor: .textSecondary
        )
        partnerDisclosureLabel.setText(
            CreatePartnerDisclosureText(
                partnerName: partner.name,
                isStripeDirect: isStripeDirect
            )
        )
        return partnerDisclosureLabel
    }())
    
    return horizontalStackView
}

private func CreatePartnerDisclosureText(
    partnerName: String,
    isStripeDirect: Bool
) -> String {
    let partnersString = String(format: STPLocalizedString("Stripe works with partners like %@ to reliably offer access to thousands of financial institutions.", "Disclosure that appears right before users connect their bank account to Stripe. It's used to educate users. The %@ will be replaced by the partner name, ex. 'Finicity' or 'MX'"), partnerName)
    let learnMoreString = String.Localized.learn_more
    let learnMoreUrlString: String = {
        if isStripeDirect {
            return "https://stripe.com/docs/linked-accounts/faqs"
        } else {
            return "https://support.stripe.com/user/questions/what-is-the-relationship-between-stripe-and-stripes-service-providers"
        }
    }()
    return partnersString + " [\(learnMoreString)](\(learnMoreUrlString))"
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct PrepaneViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> PrepaneView {
        PrepaneView(
            institutionName: "Chase",
            institutionImageUrl: nil,
            partner: .finicity,
            isStripeDirect: false,
            didSelectContinue: {}
        )
    }
    
    func updateUIView(_ uiView: PrepaneView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct PrepaneView_Previews: PreviewProvider {
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
