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

class ConsentFooterView: UIView {
    
    private let didSelectAgree: () -> Void
    
    init(
        footerText: String,
        didSelectAgree: @escaping () -> Void
    ) {
        self.didSelectAgree = didSelectAgree
        super.init(frame: .zero)
        
        backgroundColor = UIColor.white
//         layer.shouldRasterize = true // avoid applying shadow to subviews
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowRadius = 14
        layer.shadowOpacity = 0.1
        
        let separatorView = UIView(frame: CGRect(x: 0, y: 0, width: bounds.width, height: 1 / UIScreen.main.scale))
        separatorView.backgroundColor = UIColor.systemGray
        separatorView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        addSubview(separatorView)
        
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
            print("clicked link: \(url)")
            // SFSafariViewController.present(url: url)
        }
        let footerTextLinks = footerText.extractLinks()
        let label = ClickableLabel()
        label.setText(
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
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(agreeButton)
        addSubview(stackView)
        
        let verticalPadding: CGFloat = 20
        let horizontalPadding: CGFloat = 24
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: horizontalPadding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
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
private struct ConsentFooterViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> ConsentFooterView {
        ConsentFooterView(
            footerText: "You agree to Stripe's [Terms](https://stripe.com/legal/end-users#linked-financial-account-terms) and [Privacy Policy](https://stripe.com/privacy). [Learn more](https://stripe.com/privacy-center/legal#linking-financial-accounts)",
            didSelectAgree: {}
        )
    }

    func updateUIView(_ uiView: ConsentFooterView, context: Context) {
        uiView.sizeToFit()
    }
}

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
