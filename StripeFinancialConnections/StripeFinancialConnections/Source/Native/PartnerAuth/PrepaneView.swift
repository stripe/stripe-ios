//
//  PrepaneView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/9/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class PrepaneView: UIView {

    private let didSelectContinue: () -> Void

    init(
        prepaneModel: FinancialConnectionsOAuthPrepane,
        didSelectURL: @escaping (URL) -> Void,
        didSelectContinue: @escaping () -> Void
    ) {
        self.didSelectContinue = didSelectContinue
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor
        let paneLayoutView = PaneWithHeaderLayoutView(
            icon: {
                if let institutionIcon = prepaneModel.institutionIcon,
                    let institutionImageUrl = institutionIcon.default
                {
                    return .view(
                        {
                            let institutionIconView = InstitutionIconView(size: .large)
                            institutionIconView.setImageUrl(institutionImageUrl)
                            return institutionIconView
                        }()
                    )
                } else {
                    return nil
                }
            }(),
            title: prepaneModel.title,
            subtitle: nil,
            contentView: CreateContentView(
                prepaneBodyModel: prepaneModel.body,
                prepanePartnerNoticeModel: prepaneModel.partnerNotice,
                didSelectURL: didSelectURL
            ),
            headerAndContentSpacing: 8,
            footerView: CreateFooterView(
                prepaneCtaModel: prepaneModel.cta,
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
private func CreateContentView(
    prepaneBodyModel: FinancialConnectionsOAuthPrepane.OauthPrepaneBody,
    prepanePartnerNoticeModel: FinancialConnectionsOAuthPrepane.OauthPrepanePartnerNotice?,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let verticalStackView = UIStackView()
    verticalStackView.spacing = 22
    verticalStackView.axis = .vertical

    prepaneBodyModel.entries?.forEach { entry in
        if let text = entry.text {
            let label = ClickableLabel(
                font: .stripeFont(forTextStyle: .body),
                boldFont: .stripeFont(forTextStyle: .bodyEmphasized),
                linkFont: .stripeFont(forTextStyle: .bodyEmphasized),
                textColor: .textSecondary
            )
            label.setText(text, action: didSelectURL)
            verticalStackView.addArrangedSubview(label)
        } else if let imageUrl = entry.image?.default {
            let imageView = UIImageView()
            imageView.setImage(with: imageUrl)
            verticalStackView.addArrangedSubview(imageView)
        }
    }

    if let prepanePartnerNoticeModel = prepanePartnerNoticeModel {
        verticalStackView.addArrangedSubview(
            CreatePartnerDisclosureView(
                partnerNoticeModel: prepanePartnerNoticeModel,
                didSelectURL: didSelectURL
            )
        )
    }

    return verticalStackView
}

@available(iOSApplicationExtension, unavailable)
private func CreateFooterView(
    prepaneCtaModel: FinancialConnectionsOAuthPrepane.OauthPrepaneCTA,
    view: PrepaneView
) -> UIView {
    let continueButton = Button(configuration: .financialConnectionsPrimary)
    continueButton.title = prepaneCtaModel.text
    continueButton.addTarget(view, action: #selector(PrepaneView.didSelectContinueButton), for: .touchUpInside)
    continueButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        continueButton.heightAnchor.constraint(equalToConstant: 56)
    ])
    return continueButton
}

@available(iOSApplicationExtension, unavailable)
private func CreatePartnerDisclosureView(
    partnerNoticeModel: FinancialConnectionsOAuthPrepane.OauthPrepanePartnerNotice,
    didSelectURL: @escaping (URL) -> Void
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

    if let partnerIconUrlString = partnerNoticeModel.partnerIcon?.default {
        horizontalStackView.addArrangedSubview(
            {
                let partnerIconImageView = UIImageView()
                partnerIconImageView.setImage(with: partnerIconUrlString)
                partnerIconImageView.layer.cornerRadius = 4
                partnerIconImageView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    partnerIconImageView.widthAnchor.constraint(equalToConstant: 24),
                    partnerIconImageView.heightAnchor.constraint(equalToConstant: 24),
                ])
                return partnerIconImageView
            }()
        )
    }

    horizontalStackView.addArrangedSubview(
        {
            let partnerDisclosureLabel = ClickableLabel(
                font: .stripeFont(forTextStyle: .captionTight),
                boldFont: .stripeFont(forTextStyle: .captionTightEmphasized),
                linkFont: .stripeFont(forTextStyle: .captionTightEmphasized),
                textColor: .textSecondary
            )
            partnerDisclosureLabel.setText(
                partnerNoticeModel.text,
                action: didSelectURL
            )
            return partnerDisclosureLabel
        }()
    )

    return horizontalStackView
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct PrepaneViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> PrepaneView {
        PrepaneView(
            prepaneModel: FinancialConnectionsOAuthPrepane(
                institutionIcon: nil,
                title: "Log in to Capital One and grant the right permissions",
                body: FinancialConnectionsOAuthPrepane.OauthPrepaneBody(
                    entries: [
                        .init(
                            type: .text,
                            content: "Be sure to select **Account Number & Routing Number**."
                        ),
                        .init(
                            type: .image,
                            content: FinancialConnectionsImage(
                                default:
                                    "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--capitalone-4x.png"
                            )
                        ),
                        .init(
                            type: .text,
                            content:
                                "We will only share the [requested data](https://www.stripe.com) with [Merchant] even if your bank grants Stripe access to more."
                        ),
                    ]
                ),
                partnerNotice: FinancialConnectionsOAuthPrepane.OauthPrepanePartnerNotice(
                    partnerIcon: nil,
                    text:
                        "Stripe works with partners like [Partner Name] to reliability offer access to thousands of financial institutions. [Learn more](https://www.stripe.com)"
                ),
                cta: FinancialConnectionsOAuthPrepane.OauthPrepaneCTA(
                    text: "Continue",
                    icon: nil
                ),
                dataAccessNotice: FinancialConnectionsDataAccessNotice(
                    title: "",
                    body: FinancialConnectionsDataAccessNotice.Body(bullets: []),
                    connectedAccountNotice: nil,
                    learnMore: "",
                    cta: ""
                )
            ),
            didSelectURL: { _ in },
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
