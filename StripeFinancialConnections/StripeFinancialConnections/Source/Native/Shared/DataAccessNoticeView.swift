//
//  DataAccessNoticeView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/13/22.
//

import Foundation
import SafariServices
import UIKit
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class DataAccessNoticeView: UIView {
    
    private let model: DataAccessNoticeModel
    private let didSelectOKAction: () -> Void
    
    init(
        model: DataAccessNoticeModel,
        didSelectOK: @escaping () -> Void
    ) {
        self.model = model
        self.didSelectOKAction = didSelectOK
        super.init(frame: .zero)
        
        backgroundColor = .customBackgroundColor
        
        let padding: CGFloat = 24
        
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
                top: padding,
                leading: padding,
                bottom: padding,
                trailing: padding
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
            arrangedSubviews: {
                var subviews: [UIView] = []
                subviews.append(CreateHeaderView(text: model.headerText))
                model.bodyItems.forEach { item in
                    subviews.append(
                        CreateBulletinView(
                            title: item.title,
                            subtitle: item.subtitle
                        )
                    )
                }
                subviews.append(createLearnMoreLabel())
                return subviews
            }()
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16
        
        return verticalStackView
    }
    
    private func createLearnMoreLabel() -> UIView {
        let label = ClickableLabel()
        label.setText(
            model.footerText,
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

private func CreateHeaderView(text: String) -> UIView {
    let headerLabel = UILabel()
    headerLabel.numberOfLines = 0
    headerLabel.text = text
    headerLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
    headerLabel.textColor = UIColor.textPrimary
    headerLabel.textAlignment = .left
    return headerLabel
}

private func CreateBulletinView(title: String, subtitle: String) -> UIView {
    let primaryLabel = UILabel()
    primaryLabel.numberOfLines = 0
    primaryLabel.text = title
    primaryLabel.font = .stripeFont(forTextStyle: .detailEmphasized)
    primaryLabel.textColor = UIColor.textPrimary
    primaryLabel.textAlignment = .left
    let secondaryLabel = UILabel()
    secondaryLabel.numberOfLines = 0
    secondaryLabel.text = subtitle
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
@available(iOSApplicationExtension, unavailable)
private struct DataAccessNoticeViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> DataAccessNoticeView {
        DataAccessNoticeView(
            model: DataAccessNoticeModel(businessName: "Coca-Cola Inc"),
            didSelectOK: {}
        )
    }
    
    func updateUIView(_ uiView: DataAccessNoticeView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOSApplicationExtension, unavailable)
struct DataAccessNoticeView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack {
                    DataAccessNoticeViewUIViewRepresentable()
                        .frame(width: 320)
                        .frame(height: 350)
                
            }
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.1))
        }
    }
}

#endif
