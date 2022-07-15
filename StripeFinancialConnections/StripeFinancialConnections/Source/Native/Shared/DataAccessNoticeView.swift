//
//  DataAccessNoticeView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/13/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class DataAccessNoticeView: UIView {
    
    private let didSelectOKAction: () -> Void
    
    init(didSelectOK: @escaping () -> Void) {
        self.didSelectOKAction = didSelectOK
        super.init(frame: .zero)
        
        backgroundColor = .white
        
        let verticalPadding: CGFloat = 20
        let horizontalPadding: CGFloat = 24
        
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                createContentView(),
                createFooterView(),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 24
        addAndPinSubviewToSafeArea(
            verticalStackView,
            insets: NSDirectionalEdgeInsets(
                top: verticalPadding,
                leading: horizontalPadding,
                bottom: verticalPadding,
                trailing: horizontalPadding
            )
        )
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners() // needs to be in `layoutSubviews` to get the correct size for the mask
    }
    
    private func createContentView() -> UIView {
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateHeaderView(),
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
        
        return verticalStackView
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
    
    private func createFooterView() -> UIView {
        var okButtonConfiguration = Button.Configuration.primary()
        okButtonConfiguration.font = .stripeFont(forTextStyle: .bodyEmphasized)
        okButtonConfiguration.backgroundColor = .textBrand
        let okButton = Button(configuration: okButtonConfiguration)
        okButton.title = "OK"
        
        okButton.addTarget(self, action: #selector(didSelectOK), for: .touchUpInside)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            okButton.heightAnchor.constraint(equalToConstant: 56),
        ])
        
        return okButton
    }
    
    private func roundCorners() {
        clipsToBounds = true
        let path = UIBezierPath(
            roundedRect: bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: 8, height: 8)
        )
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    @IBAction private func didSelectOK() {
        didSelectOKAction()
    }
}

private func CreateHeaderView() -> UIView {
    let headerLabel = UILabel()
    headerLabel.numberOfLines = 0
    headerLabel.text = "Data requested by MERCHANT for the accounts you link:"
    headerLabel.font = .stripeFont(forTextStyle: .body)
    headerLabel.textColor = UIColor.textPrimary
    headerLabel.textAlignment = .left
    return headerLabel
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
private struct DataAccessNoticeViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> DataAccessNoticeView {
        DataAccessNoticeView(didSelectOK: {})
    }
    
    func updateUIView(_ uiView: DataAccessNoticeView, context: Context) {
        uiView.sizeToFit()
    }
}

struct DataAccessNoticeView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                    DataAccessNoticeViewUIViewRepresentable()
                        .frame(width: 320)
                
            }
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
        }
    }
}

#endif
