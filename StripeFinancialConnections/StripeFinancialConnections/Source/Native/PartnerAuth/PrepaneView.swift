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
        let bodyContainsImage = prepaneModel.body.entries?.contains(where: {
            if case .image = $0.content {
                return true
            } else {
                return false
            }
        }) ?? false
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
                // put the partner notice in the BODY if an image exists
                // (...because we want to avoid the partner notice clipping the image)
                prepanePartnerNoticeModel: bodyContainsImage ? prepaneModel.partnerNotice : nil,
                didSelectURL: didSelectURL
            ),
            headerAndContentSpacing: 8,
            footerView: CreateFooterView(
                prepaneCtaModel: prepaneModel.cta,
                // put the partner notice in the FOOTER if an image does NOT exist
                // (...because partner notice will not be able to clip image)
                prepanePartnerNoticeModel: bodyContainsImage ? nil : prepaneModel.partnerNotice,
                didSelectURL: didSelectURL,
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

private func CreateContentView(
    prepaneBodyModel: FinancialConnectionsOAuthPrepane.OauthPrepaneBody,
    prepanePartnerNoticeModel: FinancialConnectionsOAuthPrepane.OauthPrepanePartnerNotice?,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
    let verticalStackView = UIStackView()
    verticalStackView.spacing = 22
    verticalStackView.axis = .vertical

    prepaneBodyModel.entries?.forEach { entry in
        switch entry.content {
        case .text(let text):
            let label = AttributedTextView(
                font: .label(.large),
                boldFont: .label(.largeEmphasized),
                linkFont: .label(.largeEmphasized),
                textColor: .textPrimary
            )
            label.setText(text, action: didSelectURL)
            verticalStackView.addArrangedSubview(label)
        case .image(let image):
            if let imageUrl = image.default {
                let prepaneImageView = PrepaneImageView(imageURLString: imageUrl)
                verticalStackView.addArrangedSubview(prepaneImageView)
            }
        case .unparsable:
            break  // we encountered an unknown type, so just skip
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

private func CreateFooterView(
    prepaneCtaModel: FinancialConnectionsOAuthPrepane.OauthPrepaneCTA,
    prepanePartnerNoticeModel: FinancialConnectionsOAuthPrepane.OauthPrepanePartnerNotice?,
    didSelectURL: @escaping (URL) -> Void,
    view: PrepaneView
) -> UIView {
    let continueButton = Button(configuration: .financialConnectionsPrimary)
    continueButton.title = prepaneCtaModel.text
    continueButton.addTarget(view, action: #selector(PrepaneView.didSelectContinueButton), for: .touchUpInside)
    continueButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        continueButton.heightAnchor.constraint(equalToConstant: 56)
    ])
    continueButton.accessibilityIdentifier = "prepane_continue_button"

    let footerStackView = UIStackView()
    footerStackView.axis = .vertical
    footerStackView.spacing = 20

    if let prepanePartnerNoticeModel = prepanePartnerNoticeModel {
        footerStackView.addArrangedSubview(
            CreatePartnerDisclosureView(
                partnerNoticeModel: prepanePartnerNoticeModel,
                didSelectURL: didSelectURL
            )
        )
    }
    footerStackView.addArrangedSubview(continueButton)

    return footerStackView
}

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
                partnerIconImageView.clipsToBounds = true
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
            let partnerDisclosureLabel = AttributedTextView(
                font: .label(.small),
                boldFont: .label(.smallEmphasized),
                linkFont: .label(.smallEmphasized),
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

private struct PrepaneViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> PrepaneView {
        PrepaneView(
            prepaneModel: FinancialConnectionsOAuthPrepane(
                institutionIcon: nil,
                title: "Log in to Capital One and grant the right permissions",
                body: FinancialConnectionsOAuthPrepane.OauthPrepaneBody(
                    entries: [
                        .init(
                            content: .text("Be sure to select **Account Number & Routing Number**.")
                        ),
                        .init(
                            content: .image(
                                FinancialConnectionsImage(
                                    default: "https://js.stripe.com/v3/f0620405e3235ff4736f6876f4d3d045.gif"
                                )
                            )
                        ),
                        .init(
                            content: .text(
                                "We will only share the [requested data](https://www.stripe.com) with [Merchant] even if your bank grants Stripe access to more."
                            )
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
                    subtitle: nil,
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

@available(iOS 14.0, *)
struct PrepaneView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                PrepaneViewUIViewRepresentable()
            }
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.1))
            .navigationTitle("Stripe")
            .navigationBarTitleDisplayMode(.inline)
        }

    }
}

#endif
