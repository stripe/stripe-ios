//
//  ConsentFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/14/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import SafariServices

@available(iOSApplicationExtension, unavailable)
class ConsentFooterView: UIView {
    
    private let didSelectAgree: () -> Void
    private let didSelectManuallyVerify: (() -> Void)?
    
    init(
        footerText: String,
        didSelectAgree: @escaping () -> Void,
        didSelectManuallyVerify: (() -> Void)?,
        showManualEntryBusinessDaysNotice: Bool // // !customManualEntryHandle && manualEntryUsesMicrodeposits
    ) {
        self.didSelectAgree = didSelectAgree
        self.didSelectManuallyVerify = didSelectManuallyVerify
        super.init(frame: .zero)
        
        backgroundColor = .customBackgroundColor
        
        var agreeButtonConfiguration = Button.Configuration.primary()
        agreeButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
        agreeButtonConfiguration.backgroundColor = .textBrand
        let agreeButton = Button(configuration: agreeButtonConfiguration)
        agreeButton.title = "Agree"
        
        agreeButton.addTarget(self, action: #selector(didSelectAgreeButton), for: .touchUpInside)
        agreeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            agreeButton.heightAnchor.constraint(equalToConstant: 56),
        ])
        
        let selectedUrl: (URL) -> Void = { url in
            SFSafariViewController.present(url: url)
        }
        let footerTextLinks = footerText.extractLinks()
        let termsAndPrivacyPolicyLabel = ClickableLabel()
        termsAndPrivacyPolicyLabel.setText(
            footerTextLinks.linklessString,
            links: footerTextLinks.links.map {
                ClickableLabel.Link(
                    range: $0.range,
                    urlString: $0.urlString,
                    action: selectedUrl
                )
            },
            alignCenter: true
        )
        
        let stackView = UIStackView(
            arrangedSubviews: [
                termsAndPrivacyPolicyLabel,
                agreeButton,
            ]
        )
        stackView.axis = .vertical
        stackView.spacing = 20
        addSubview(stackView)
            
        if let didSelectManuallyVerify = didSelectManuallyVerify {
            let text: String
            if showManualEntryBusinessDaysNotice {
                text = "[Manually verify instead](https://www.fakelinkthatisignored.com) (takes 1-2 business days)"
            } else {
                text = "[Enter account details manually instead](https://www.fakelinkthatisignored.com)"
            }
            
            let manuallyVerifyLabel = ClickableLabel()
            manuallyVerifyLabel.setText(
                text,
                action: { _ in
                    didSelectManuallyVerify()
                }
            )
            stackView.addArrangedSubview(manuallyVerifyLabel)
            stackView.setCustomSpacing(24, after: agreeButton)
        }
        
        let verticalPadding: CGFloat = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: verticalPadding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -verticalPadding),
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didSelectAgreeButton() {
        didSelectAgree()
    }
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct ConsentFooterViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> ConsentFooterView {
        ConsentFooterView(
            footerText: "You agree to Stripe's [Terms](https://stripe.com/legal/end-users#linked-financial-account-terms) and [Privacy Policy](https://stripe.com/privacy). [Learn more](https://stripe.com/privacy-center/legal#linking-financial-accounts)",
            didSelectAgree: {},
            didSelectManuallyVerify: {},
            showManualEntryBusinessDaysNotice: false
        )
    }

    func updateUIView(_ uiView: ConsentFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOSApplicationExtension, unavailable)
struct ConsentFooterView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                Text("Header")
                ScrollView {
                    Text("Scroll View Content")
                }
                ConsentFooterViewUIViewRepresentable()
            }
        }
    }
}

#endif
