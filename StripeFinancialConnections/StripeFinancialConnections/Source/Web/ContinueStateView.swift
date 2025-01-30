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

    let contentView: UIView
    private var primaryButton: StripeUICore.Button?
    private var secondaryButton: StripeUICore.Button?
    let footerView: UIView?

    init(
        institutionImageUrl: String?,
        appearance: FinancialConnectionsAppearance,
        didSelectContinue: @escaping () -> Void,
        didSelectCancel: (() -> Void)? = nil
    ) {
        self.contentView = PaneLayoutView.createContentView(
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
        let footerViewTuple = PaneLayoutView.createFooterView(
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
            }(),
            appearance: appearance
        )
        self.footerView = footerViewTuple.footerView
        self.primaryButton = footerViewTuple.primaryButton
        self.secondaryButton = footerViewTuple.secondaryButton
    }

    func showLoadingView(_ show: Bool) {
        primaryButton?.isLoading = show
        secondaryButton?.isEnabled = !show
    }
}
