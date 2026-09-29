//
//  GenericErrorViewController.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2026-08-12.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol GenericErrorViewControllerDelegate: AnyObject {
    func genericErrorViewControllerDidSelectRestartAuthFlow(_ viewController: GenericErrorViewController)
    func genericErrorViewControllerDidSelectAnotherBank(_ viewController: GenericErrorViewController)
}

/// Represents the `generic_error` pane: an error screen whose entire contents are
/// dictated by the server via the `extra_fields` of an API error.
final class GenericErrorViewController: UIViewController {

    private let dataSource: GenericErrorDataSource
    weak var delegate: GenericErrorViewControllerDelegate?

    init(dataSource: GenericErrorDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background
        // this pane replaces the one the error came from, so there's nothing to go back to.
        // the user moves forward through the primary CTA instead.
        navigationItem.hidesBackButton = true

        let genericErrorPane = dataSource.genericErrorPane

        let contentView = PaneLayoutView.createContentView(
            iconView: {
                guard let iconUrl = genericErrorPane.iconUrl else { return nil }
                let institutionIconView = InstitutionIconView()
                institutionIconView.setImageUrl(iconUrl)
                return institutionIconView
            }(),
            title: genericErrorPane.heading,
            // the subheading is centered, which `createBodyView` can't do, so it's
            // built as part of the content view below
            subtitle: nil,
            headerAlignment: .center,
            contentView: CreateContentView(genericErrorPane: genericErrorPane)
        )
        let footerView = PaneLayoutView.createFooterView(
            primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                title: primaryCtaTitle,
                accessibilityIdentifier: "generic_error_primary_button",
                action: { [weak self] in
                    self?.didSelectPrimaryCta()
                }
            ),
            appearance: dataSource.appearance
        ).footerView

        PaneLayoutView(
            contentView: contentView,
            footerView: footerView
        ).addTo(view: view)

        dataSource.analyticsClient.logPaneLoaded(pane: .genericError)

        if genericErrorPane.primaryCtaAction == nil {
            dataSource
                .analyticsClient
                .logUnexpectedError(
                    FinancialConnectionsSheetError.unknown(
                        debugDescription: "Unhandled generic error pane primary CTA action."
                    ),
                    errorName: "GenericErrorPaneUnknownCtaAction",
                    pane: .genericError
                )
        }
    }

    private var primaryCtaTitle: String {
        switch dataSource.genericErrorPane.primaryCtaAction {
        case .restartAuthFlow:
            return dataSource.genericErrorPane.primaryCta
        case nil:
            // we don't know how to perform the action the server asked for, so we fall back
            // to letting the user pick a different bank. use our own copy for the button so
            // it can't promise something we won't do.
            return String.Localized.select_another_bank
        }
    }

    private func didSelectPrimaryCta() {
        let action = dataSource.genericErrorPane.primaryCtaAction
        dataSource
            .analyticsClient
            .log(
                eventName: "click.primary_cta",
                parameters: ["action": action?.rawValue ?? "unknown"],
                pane: .genericError
            )

        dataSource.cancelPendingAuthSessionIfNeeded()

        switch action {
        case .restartAuthFlow:
            delegate?.genericErrorViewControllerDidSelectRestartAuthFlow(self)
        case nil:
            delegate?.genericErrorViewControllerDidSelectAnotherBank(self)
        }
    }
}

private func CreateContentView(
    genericErrorPane: FinancialConnectionsGenericErrorPane
) -> UIView {
    let verticalStackView = UIStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 24

    let subheadingLabel = AttributedTextView(
        font: .body(.medium),
        boldFont: .body(.mediumEmphasized),
        linkFont: .body(.mediumEmphasized),
        textColor: FinancialConnectionsAppearance.Colors.textSubdued,
        alignment: .center
    )
    subheadingLabel.setText(genericErrorPane.subheading)
    verticalStackView.addArrangedSubview(subheadingLabel)

    if let imageUrl = genericErrorPane.imageUrl {
        verticalStackView.addArrangedSubview(
            PrepaneImageView(imageURLString: imageUrl)
        )
    }

    return verticalStackView
}

#if DEBUG

import SwiftUI

private struct GenericErrorViewControllerRepresentable: UIViewControllerRepresentable {

    let genericErrorPane: FinancialConnectionsGenericErrorPane

    func makeUIViewController(context: Context) -> GenericErrorViewController {
        GenericErrorViewController(
            dataSource: GenericErrorDataSource(
                genericErrorPane: genericErrorPane,
                authSession: nil,
                appearance: .stripe,
                apiClient: FinancialConnectionsAsyncAPIClient(apiClient: .shared),
                clientSecret: "las_123",
                analyticsClient: FinancialConnectionsAnalyticsClient()
            )
        )
    }

    func updateUIViewController(_ viewController: GenericErrorViewController, context: Context) {}
}

private func PreviewGenericErrorPane(
    primaryCtaAction: String? = "restart_auth_flow",
    iconUrl: String? = "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--wellsfargo-4x.png",
    imageUrl: String? = "https://b.stripecdn.com/connections-statics-srv/assets/ErrorAsset--ownership-wellsfargo-2x.png"
) -> FinancialConnectionsGenericErrorPane {
    var extraFields: [String: Any] = [
        "use_generic_error_pane": true,
        "generic_error_pane_heading": "There was a problem accessing your account",
        "generic_error_pane_subheading": "Please try again and be sure to select **Profile information**.",
        "generic_error_pane_primary_cta": "Try again",
    ]
    extraFields["generic_error_pane_icon_url"] = iconUrl
    extraFields["generic_error_pane_primary_cta_action"] = primaryCtaAction
    extraFields["generic_error_pane_image_url"] = imageUrl
    // swiftlint:disable:next force_unwrapping
    return FinancialConnectionsGenericErrorPane(extraFields: extraFields)!
}

struct GenericErrorViewController_Previews: PreviewProvider {
    static var previews: some View {
        // matches the design mock
        GenericErrorViewControllerRepresentable(
            genericErrorPane: PreviewGenericErrorPane()
        )
        .previewDisplayName("Restart auth flow")

        // the image is not always returned by the server
        GenericErrorViewControllerRepresentable(
            genericErrorPane: PreviewGenericErrorPane(
                iconUrl: "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--testmodePurpleOauth.svg",
                imageUrl: nil
            )
        )
        .previewDisplayName("No image")

        // an action we don't know how to handle falls back to "Select another bank"
        GenericErrorViewControllerRepresentable(
            genericErrorPane: PreviewGenericErrorPane(primaryCtaAction: "some_future_action")
        )
        .previewDisplayName("Unknown CTA action")
    }
}

#endif
