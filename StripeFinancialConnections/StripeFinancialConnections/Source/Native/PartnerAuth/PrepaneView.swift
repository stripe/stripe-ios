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
    private let didSelectCancel: () -> Void

    private let contentStackView: UIStackView = {
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        return contentStackView
    }()
    private let headerView: UIView
    private let bodyView: UIView
    private var loadingView: UIView?
    private var primaryButton: StripeUICore.Button?
    private var secondaryButton: StripeUICore.Button?

    init(
        prepaneModel: FinancialConnectionsOAuthPrepane,
        isRepairSession: Bool,
        didSelectURL: @escaping (URL) -> Void,
        didSelectContinue: @escaping () -> Void,
        didSelectCancel: @escaping () -> Void
    ) {
        self.didSelectContinue = didSelectContinue
        self.didSelectCancel = didSelectCancel
        self.headerView = PaneLayoutView.createHeaderView(
            iconView: {
                if let institutionIconUrl = prepaneModel.institutionIcon?.default {
                    let institutionIconView = InstitutionIconView()
                    institutionIconView.setImageUrl(institutionIconUrl)
                    return institutionIconView
                } else {
                    return nil
                }
            }(),
            title: prepaneModel.title
        )
        self.bodyView = PaneLayoutView.createBodyView(
            text: prepaneModel.subtitle,
            contentView: CreateContentView(
                prepaneBodyModel: prepaneModel.body,
                didSelectURL: didSelectURL
            )
        )
        super.init(frame: .zero)
        backgroundColor = .customBackgroundColor

        contentStackView.addArrangedSubview(headerView)

        let footerViewTuple = PaneLayoutView.createFooterView(
            primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                title: prepaneModel.cta.text,
                accessibilityIdentifier: "prepane_continue_button",
                action: didSelectContinue
            ),
            secondaryButtonConfiguration: {
                if isRepairSession {
                    return nil
                } else {
                    return PaneLayoutView.ButtonConfiguration(
                        title: STPLocalizedString(
                            "Choose a different bank",
                            "Title of a button. It acts as a back button to go back to choosing a different bank instead of the currently selected one."
                        ),
                        action: didSelectCancel
                    )
                }
            }()
        )
        self.primaryButton = footerViewTuple.primaryButton
        self.secondaryButton = footerViewTuple.secondaryButton

        let paneLayoutView = PaneLayoutView(
            contentView: contentStackView,
            footerView: footerViewTuple.footerView
        )
        paneLayoutView.addTo(view: self)

        // setup the `contentContainerView`
        showLoadingView(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showLoadingView(_ show: Bool) {
        bodyView.removeFromSuperview()
        loadingView?.removeFromSuperview()
        loadingView = nil

        if show {
            let loadingView = PrepaneLoadingView()
            self.loadingView = loadingView
            contentStackView.addArrangedSubview(loadingView)
        } else {
            contentStackView.addArrangedSubview(bodyView)
        }
        primaryButton?.isLoading = show
        secondaryButton?.isEnabled = !show
    }

    @objc fileprivate func didSelectContinueButton() {
        didSelectContinue()
    }
}

private func CreateContentView(
    prepaneBodyModel: FinancialConnectionsOAuthPrepane.OauthPrepaneBody,
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

    return verticalStackView
}

private class PrepaneLoadingView: ShimmeringView {

    init() {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateLoadingLabelView(width: 400),
                CreateLoadingLabelView(width: 163),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .leading
        verticalStackView.spacing = 8
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 0,
            leading: 24,
            bottom: 0,
            trailing: 24
        )
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
private func CreateLoadingLabelView(width: CGFloat) -> UIView {
    let labelView = UIView()
    labelView.backgroundColor = .backgroundOffset
    labelView.layer.cornerRadius = 8
    labelView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        labelView.heightAnchor.constraint(equalToConstant: 16),
        labelView.widthAnchor.constraint(equalToConstant: width),
    ])
    // make the width fit the screen if-needed
    labelView.setContentCompressionResistancePriority(.fittingSizeLevel, for: .horizontal)
    return labelView
}

#if DEBUG

import SwiftUI

private struct PrepaneViewUIViewRepresentable: UIViewRepresentable {

    let isLoading: Bool

    func makeUIView(context: Context) -> PrepaneView {
        PrepaneView(
            prepaneModel: FinancialConnectionsOAuthPrepane(
                institutionIcon: nil,
                title: "Log in to Capital One and grant the right permissions",
                subtitle: "Next, you'll be promted to log in and connect your accounts.",
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
                    icon: nil,
                    title: "",
                    subtitle: nil,
                    body: FinancialConnectionsDataAccessNotice.Body(bullets: []),
                    connectedAccountNotice: nil,
                    disclaimer: nil,
                    cta: "OK"
                )
            ),
            isRepairSession: false,
            didSelectURL: { _ in },
            didSelectContinue: {},
            didSelectCancel: {}
        )
    }

    func updateUIView(_ prepaneView: PrepaneView, context: Context) {
        prepaneView.showLoadingView(isLoading)
    }
}

@available(iOS 14.0, *)
struct PrepaneView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                PrepaneViewUIViewRepresentable(isLoading: false)
            }
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.1))
            .navigationTitle("stripe")
            .navigationBarTitleDisplayMode(.inline)
        }

        NavigationView {
            VStack {
                PrepaneViewUIViewRepresentable(isLoading: true)
            }
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.1))
            .navigationTitle("stripe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#endif
