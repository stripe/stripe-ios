//
//  PrepaneViewss.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/6/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// A container that encapsulates all the subviews necessary
// to create a prepane view. Helps to avoid bloat in
// `PartnerAuthViewController`.
final class PrepaneViews {

    private let didSelectContinue: () -> Void
    private let didSelectCancel: () -> Void

    let contentStackView: UIStackView = {
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        return contentStackView
    }()
    private let headerView: UIView
    private let bodyView: UIView
    private var primaryButton: StripeUICore.Button?
    private var secondaryButton: StripeUICore.Button?
    let footerView: UIView?

    init(
        prepaneModel: FinancialConnectionsOAuthPrepane,
        hideSecondaryButton: Bool,
        panePresentationStyle: PanePresentationStyle,
        appearance: FinancialConnectionsAppearance,
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
            title: prepaneModel.title,
            isSheet: (panePresentationStyle == .sheet)
        )
        self.bodyView = PaneLayoutView.createBodyView(
            text: prepaneModel.subtitle,
            contentView: CreateContentView(
                prepaneBodyModel: prepaneModel.body,
                didSelectURL: didSelectURL
            )
        )

        contentStackView.addArrangedSubview(headerView)

        let footerViewTuple = PaneLayoutView.createFooterView(
            primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                title: prepaneModel.cta.text,
                accessibilityIdentifier: "prepane_continue_button",
                action: didSelectContinue
            ),
            secondaryButtonConfiguration: {
                if hideSecondaryButton {
                    return nil
                } else {
                    return PaneLayoutView.ButtonConfiguration(
                        title: {
                            switch panePresentationStyle {
                            case .fullscreen:
                                return STPLocalizedString(
                                   "Choose a different bank",
                                   "Title of a button. It acts as a back button to go back to choosing a different bank instead of the currently selected one."
                               )
                            case .sheet:
                                return "Cancel" // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.cancel`
                            }
                        }(),
                        accessibilityIdentifier: "prepane_cancel_button",
                        action: didSelectCancel
                    )
                }
            }(),
            appearance: appearance
        )
        self.footerView = footerViewTuple.footerView
        self.primaryButton = footerViewTuple.primaryButton
        self.secondaryButton = footerViewTuple.secondaryButton

        contentStackView.addArrangedSubview(bodyView)

        showLoadingView(false)
    }

    deinit {
        contentStackView.removeFromSuperview()
        footerView?.removeFromSuperview()
    }

    func showLoadingView(_ show: Bool) {
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
) -> UIView? {
    guard
        let entries = prepaneBodyModel.entries,
        !entries.isEmpty
    else {
        // returning an empty `UIStackView` added unnecessary
        // padding, so returning `nil` removes the extra padding
        return nil
    }

    let verticalStackView = UIStackView()
    verticalStackView.spacing = 22
    verticalStackView.axis = .vertical

    entries.forEach { entry in
        switch entry.content {
        case .text(let text):
            let label = AttributedTextView(
                font: .label(.large),
                boldFont: .label(.largeEmphasized),
                linkFont: .label(.largeEmphasized),
                textColor: FinancialConnectionsAppearance.Colors.textDefault
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

#if DEBUG

import SwiftUI

private class PrepanePreviewView: UIView {

    let prepaneViews = PrepaneViews(
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
                connectedAccountNotice: nil,
                subtitle: nil,
                body: FinancialConnectionsDataAccessNotice.Body(bullets: []),
                disclaimer: nil,
                cta: "OK"
            )
        ),
        hideSecondaryButton: false,
        panePresentationStyle: .sheet,
        appearance: .stripe,
        didSelectURL: { _ in },
        didSelectContinue: {},
        didSelectCancel: {}
    )

    init() {
        super.init(frame: .zero)
        let paneLayoutView = PaneLayoutView(
            contentView: prepaneViews.contentStackView,
            footerView: prepaneViews.footerView
        )
        paneLayoutView.addTo(view: self)
        backgroundColor = FinancialConnectionsAppearance.Colors.background
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private struct PrepaneViewsUIViewRepresentable: UIViewRepresentable {

    let isLoading: Bool

    func makeUIView(context: Context) -> PrepanePreviewView {
        PrepanePreviewView()
    }

    func updateUIView(_ prepanePreviewView: PrepanePreviewView, context: Context) {
        prepanePreviewView.prepaneViews.showLoadingView(isLoading)
    }
}

@available(iOS 14.0, *)
struct PrepaneViews_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            VStack {
                PrepaneViewsUIViewRepresentable(isLoading: false)
            }
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.1))
            .navigationTitle("stripe")
            .navigationBarTitleDisplayMode(.inline)
        }

        NavigationView {
            VStack {
                PrepaneViewsUIViewRepresentable(isLoading: true)
            }
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.1))
            .navigationTitle("stripe")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#endif
