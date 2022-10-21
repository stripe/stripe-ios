//
//  ConsentBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/15/22.
//

import Foundation
import SafariServices
import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
class ConsentBodyView: UIView {
    
    private let bulletItems: [FinancialConnectionsBullet]
    private let dataAccessNoticeModel: DataAccessNoticeModel
    
    init(
        bulletItems: [FinancialConnectionsBullet],
        dataAccessNoticeModel: DataAccessNoticeModel
    ) {
        self.bulletItems = bulletItems
        self.dataAccessNoticeModel = dataAccessNoticeModel
        super.init(frame: .zero)
        
        backgroundColor = .customBackgroundColor
        
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        
        let linkAction: (URL) -> Void = { url in
            if let scheme = url.scheme, scheme.contains("stripe") {
                let dataAccessNoticeViewController = DataAccessNoticeViewController(model: dataAccessNoticeModel)
                dataAccessNoticeViewController.modalTransitionStyle = .crossDissolve
                dataAccessNoticeViewController.modalPresentationStyle = .overCurrentContext
                // `false` for animations because we do a custom animation inside VC logic
                UIViewController
                    .topMostViewController()?
                    .present(dataAccessNoticeViewController, animated: false, completion: nil)
            } else {
                SFSafariViewController.present(url: url)
            }
        }
        bulletItems.forEach { bulletItem in
            verticalStackView.addArrangedSubview(
                CreateLabelView(
                    text: bulletItem.content,
                    action: linkAction
                )
            )
        }
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateLabelView(text: String, action: @escaping (URL) -> Void) -> UIView {
    let imageView = UIImageView(image: Image.close.makeImage(template: false))
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 16),
        // skip `imageView.heightAnchor` so the labels naturally expand
    ])
    
    let label = ClickableLabel(
        font: UIFont.stripeFont(forTextStyle: .detail),
        boldFont: UIFont.stripeFont(forTextStyle: .detailEmphasized),
        linkFont: UIFont.stripeFont(forTextStyle: .detailEmphasized),
        textColor: .textSecondary
    )
    label.setText(text, action: action)

    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            imageView,
            label,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 10
    horizontalStackView.alignment = .top
    return horizontalStackView
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct ConsentBodyViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ConsentBodyView {
        ConsentBodyView(
            bulletItems: [
                FinancialConnectionsBullet(
                    icon: "...",
                    title: "",
                    content: "Stripe will allow Goldilocks to access only the [data requested](https://www.stripe.com). We never share your login details with them."
                ),
                FinancialConnectionsBullet(
                    icon: "...",
                    title: "",
                    content: "Your data is encrypted for your protection."
                ),
                FinancialConnectionsBullet(
                    icon: "...",
                    title: "",
                    content: "You can [disconnect](https://www.stripe.com) your accounts at any time."
                ),
            ],
            dataAccessNoticeModel: DataAccessNoticeModel(businessName: "Coca-Cola Inc")
        )
    }
    
    func updateUIView(_ uiView: ConsentBodyView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct ConsentBodyView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        VStack(alignment: .leading) {
            ConsentBodyViewUIViewRepresentable()
                .frame(maxHeight: 200)
                .padding()
            Spacer()
        }
    }
}

#endif
