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

@available(iOSApplicationExtension, unavailable)
class ConsentFooterView: UIView {
    
    private let didSelectAgree: () -> Void
    private let didSelectManuallyVerify: (() -> Void)?
    
    private lazy var agreeButton: StripeUICore.Button = {
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
        return agreeButton
    }()
    
    init(
        footerText: String,
        didSelectAgree: @escaping () -> Void,
        didSelectManuallyVerify: (() -> Void)?, // null if manual entry disabled
        showManualEntryBusinessDaysNotice: Bool
    ) {
        self.didSelectAgree = didSelectAgree
        self.didSelectManuallyVerify = didSelectManuallyVerify
        super.init(frame: .zero)
        
        backgroundColor = .customBackgroundColor
        
        let termsAndPrivacyPolicyLabel = ClickableLabel()
        termsAndPrivacyPolicyLabel.setText(
            footerText,
            alignCenter: true
        )
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                termsAndPrivacyPolicyLabel,
                agreeButton,
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 20
            
        if let didSelectManuallyVerify = didSelectManuallyVerify {
            let text: String
            if showManualEntryBusinessDaysNotice {
                let localizedManuallyVerifyText = STPLocalizedString("Manually verify instead", "The title of a button that allows the user to press it to enter bank account details manually.")
                let localizedBusinessDaysNotice = STPLocalizedString("(takes 1-2 business days)", "An extra notice next to a title of a button that allows the user to press it to enter bank account details manually. The full text looks like: 'Manually verify instead (takes 1-2 business days)'")
                text = "[\(localizedManuallyVerifyText)](https://www.urlIsIgnored.com) \(localizedBusinessDaysNotice)"
            } else {
                let localizedText = STPLocalizedString("Enter account details manually instead", "The title of a button that allows the user to press it to enter bank account details manually.")
                text = "[\(localizedText)](https://www.urlIsIgnored.com)"
            }
            
            let manuallyVerifyLabel = ClickableLabel()
            manuallyVerifyLabel.setText(
                text,
                alignCenter: true,
                action: { _ in
                    didSelectManuallyVerify()
                }
            )
            verticalStackView.addArrangedSubview(manuallyVerifyLabel)
            verticalStackView.setCustomSpacing(24, after: agreeButton)
        }
        
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didSelectAgreeButton() {
        didSelectAgree()
    }
    
    func setIsLoading(_ isLoading: Bool) {
        agreeButton.isLoading = isLoading
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
                ConsentFooterViewUIViewRepresentable()
                    .frame(maxHeight: 200)
                Spacer()
            }
            .padding()
        }
    }
}

#endif
