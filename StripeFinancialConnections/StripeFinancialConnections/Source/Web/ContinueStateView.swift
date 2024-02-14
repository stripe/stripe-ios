//
//  ContinueStateView.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 10/5/22.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class ContinueStateViews {

    private init() {}

    static func createContentView(institutionImageUrl: String?) -> UIView {
        return PaneLayoutView.createContentView(
            iconView: {
                if let institutionImageUrl {
                    let institutionIconView = InstitutionIconView()
                    institutionIconView.setImageUrl(institutionImageUrl)
                    return institutionIconView
                } else {
                    return nil
                }
            }(),
            title: STPLocalizedString(
                "Continue linking your account",
                "Title for a label of a screen telling users to tap below to continue linking process."
            ),
            subtitle: STPLocalizedString(
                "You haven't finished linking your account. Press continue to finish the process.",
                "Title for a label explaining that the linking process hasn't finished yet."
            ),
            contentView: nil
        )
    }

    static func createFooterView(
        didSelectContinue: @escaping () -> Void,
        didSelectCancel: (() -> Void)? = nil
    ) -> UIView? {
        return PaneLayoutView.createFooterView(
            primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                title: "Continue", // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.continue`,
                action: didSelectContinue
            ),
            secondaryButtonConfiguration: {
                if let didSelectCancel {
                    return PaneLayoutView.ButtonConfiguration(
                        title: "Cancel", // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.cancel`
                        action: didSelectCancel
                    )
                } else {
                    return nil
                }
            }()
        ).footerView
    }
}
