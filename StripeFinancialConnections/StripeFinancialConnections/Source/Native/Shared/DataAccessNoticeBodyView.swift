//
//  DataAccessNoticeBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/14/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class DataAccessNoticeBodyView: UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreatBulletinView(
                    primaryText: "Account owner information",
                    secondaryText: "Account owner name and mailing address associated with your account"
                ),
                CreatBulletinView(
                    primaryText: "Account details",
                    secondaryText: "Account number, routing number, account type, account nickname"
                ),
                createLearnMoreLabel(),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func createLearnMoreLabel() -> UIView {
        let footerText = "[Learn more about data access](https://support.stripe.com/user/questions/what-data-does-stripe-access-from-my-linked-financial-account)"
        let selectedUrl: (URL) -> Void = { url in
            // TODO(kgaidis): add ability to show Safari VC
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
            font: .stripeFont(forTextStyle: .caption),
            linkFont: .stripeFont(forTextStyle: .captionEmphasized)
        )
        
        return label
    }
}

private func CreatBulletinView(primaryText: String, secondaryText: String) -> UIView {
    let primaryLabel = UILabel()
    primaryLabel.numberOfLines = 0
    primaryLabel.text = primaryText
    primaryLabel.font = .stripeFont(forTextStyle: .detailEmphasized)
    primaryLabel.textColor = UIColor.textPrimary
    primaryLabel.textAlignment = .left
    let secondaryLabel = UILabel()
    secondaryLabel.numberOfLines = 0
    secondaryLabel.text = secondaryText
    secondaryLabel.font = .stripeFont(forTextStyle: .caption)
    secondaryLabel.textColor = UIColor.textSecondary
    secondaryLabel.textAlignment = .left
    let verticalStackView = UIStackView(
        arrangedSubviews: [
            primaryLabel,
            secondaryLabel,
        ]
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 5

    let imageView = UIImageView(image: Image.close.makeImage(template: false))
    imageView.contentMode = .scaleAspectFit
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 16),
        // skip `imageView.heightAnchor` so the labels naturally expand
    ])
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            imageView,
            verticalStackView,
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
private struct DataAccessNoticeBodyViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> DataAccessNoticeBodyView {
        DataAccessNoticeBodyView()
    }
    
    func updateUIView(_ uiView: DataAccessNoticeBodyView, context: Context) {
        uiView.sizeToFit()
    }
}

struct DataAccessNoticeBodyView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                DataAccessNoticeBodyViewUIViewRepresentable()
                        .frame(width: 320)
                        .frame(maxHeight: 200)
                
            }
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
        }
    }
}

#endif

