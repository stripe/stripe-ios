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
    
    private let didSelectOKAction: () -> Void
    
    init(
        model: FinancialConnectionsDataAccessNotice,
        didSelectOK: @escaping () -> Void,
        didSelectURL: @escaping (URL) -> Void
    ) {
        self.didSelectOKAction = didSelectOK
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        
        let padding: CGFloat = 24
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateContentView(
                    headerTitle: model.title,
                    bulletItems: model.body.bullets,
                    connectedAccountNotice: model.connectedAccountNotice,
                    learnMoreText: model.learnMore,
                    didSelectURL: didSelectURL
                ),
                CreateFooterView(
                    cta: model.cta,
                    actionTarget: self
                ),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 24
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: padding,
            leading: padding,
            bottom: padding,
            trailing: padding
        )
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners() // needs to be in `layoutSubviews` to get the correct size for the mask
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
    
    @IBAction fileprivate func didSelectOK() {
        didSelectOKAction()
    }
}

@available(iOSApplicationExtension, unavailable)
private func CreateContentView(
    headerTitle: String,
    bulletItems: [FinancialConnectionsBulletPoint],
    connectedAccountNotice: String?,
    learnMoreText: String,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let verticalStackView = UIStackView(
        arrangedSubviews: {
            var subviews: [UIView] = []
            subviews.append(
                CreateHeaderView(
                    text: headerTitle,
                    didSelectURL: didSelectURL
                )
            )
            bulletItems.forEach { bulletItem in
                subviews.append(
                    CreateBulletinView(
                        title: bulletItem.title,
                        subtitle: bulletItem.content,
                        iconUrl: bulletItem.icon?.default,
                        didSelectURL: didSelectURL
                    )
                )
            }
            if let connectedAccountNotice = connectedAccountNotice {
                let connectedAccountNoticeLabel = ClickableLabel(
                    font: .stripeFont(forTextStyle: .caption),
                    boldFont: .stripeFont(forTextStyle: .captionEmphasized),
                    linkFont: .stripeFont(forTextStyle: .captionEmphasized),
                    textColor: .textSecondary
                )
                connectedAccountNoticeLabel.setText(connectedAccountNotice, action: didSelectURL)
                subviews.append(connectedAccountNoticeLabel)
            }
            subviews.append(
                CreateLearnMoreLabel(
                    text: learnMoreText,
                    didSelectURL: didSelectURL
                )
            )
            return subviews
        }()
    )
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 16
    return verticalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateHeaderView(
    text: String,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let headerLabel = ClickableLabel(
        font: .stripeFont(forTextStyle: .bodyEmphasized),
        boldFont: .stripeFont(forTextStyle: .bodyEmphasized),
        linkFont: .stripeFont(forTextStyle: .bodyEmphasized),
        textColor: .textPrimary
    )
    headerLabel.setText(text, action: didSelectURL)
    return headerLabel
}

@available(iOSApplicationExtension, unavailable)
private func CreateBulletinView(
    title: String?,
    subtitle: String,
    iconUrl: String?,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let imageView = AlwaysTemplateImageView(tintColor: .textSuccess)
    imageView.contentMode = .scaleAspectFit
    imageView.setImage(with: iconUrl)
    imageView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        imageView.widthAnchor.constraint(equalToConstant: 16),
        imageView.heightAnchor.constraint(equalToConstant: 16),
    ])
    
    let verticalLabelStackView = UIStackView()
    verticalLabelStackView.axis = .vertical
    verticalLabelStackView.spacing = 5
    if let title = title {
        let primaryLabel = ClickableLabel(
            font: .stripeFont(forTextStyle: .detailEmphasized),
            boldFont: .stripeFont(forTextStyle: .detailEmphasized),
            linkFont: .stripeFont(forTextStyle: .detailEmphasized),
            textColor: .textPrimary
        )
        primaryLabel.setText(title, action: didSelectURL)
        verticalLabelStackView.addArrangedSubview(primaryLabel)
    }
    let subtitleLabel = ClickableLabel(
        font: .stripeFont(forTextStyle: .caption),
        boldFont: .stripeFont(forTextStyle: .captionEmphasized),
        linkFont: .stripeFont(forTextStyle: .captionEmphasized),
        textColor: .textSecondary
    )
    subtitleLabel.setText(subtitle, action: didSelectURL)
    verticalLabelStackView.addArrangedSubview(subtitleLabel)
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            imageView,
            verticalLabelStackView,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 10
    horizontalStackView.alignment = .top
    return horizontalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateLearnMoreLabel(
    text: String,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let label = ClickableLabel(
        font: .stripeFont(forTextStyle: .caption),
        boldFont: .stripeFont(forTextStyle: .captionEmphasized),
        linkFont: .stripeFont(forTextStyle: .captionEmphasized),
        textColor: .textSecondary
    )
    label.setText(text, action: didSelectURL)
    return label
}

@available(iOSApplicationExtension, unavailable)
private func CreateFooterView(
    cta: String,
    actionTarget: DataAccessNoticeView
) -> UIView {
    let okButton = Button(configuration: .financialConnectionsPrimary)
    okButton.title = cta
    okButton.addTarget(actionTarget, action: #selector(DataAccessNoticeView.didSelectOK), for: .touchUpInside)
    okButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        okButton.heightAnchor.constraint(equalToConstant: 56),
    ])
    return okButton
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct DataAccessNoticeViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> DataAccessNoticeView {
        DataAccessNoticeView(
            model: FinancialConnectionsDataAccessNotice(
                title: "",
                body: FinancialConnectionsDataAccessNotice.Body(
                    bullets: [
                        FinancialConnectionsBulletPoint(
                            icon: FinancialConnectionsImage(default: nil),
                            title: "...",
                            content: "..."
                        )
                    ]
                ),
                connectedAccountNotice: nil,
                learnMore: "...",
                cta: "..."
            ),
            didSelectOK: {},
            didSelectURL: { _ in }
        )
    }
    
    func updateUIView(_ uiView: DataAccessNoticeView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOSApplicationExtension, unavailable)
struct DataAccessNoticeView_Previews: PreviewProvider {
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
