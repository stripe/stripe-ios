//
//  CloseConfirmationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/19/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class CloseConfirmationViewController: SheetViewController {

    private let appearance: FinancialConnectionsAppearance
    private let businessName: String?
    private let didSelectClose: () -> Void

    init(
        appearance: FinancialConnectionsAppearance,
        businessName: String?,
        didSelectClose: @escaping () -> Void
    ) {
        self.appearance = appearance
        self.businessName = businessName
        self.didSelectClose = didSelectClose
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let isLink = appearance.colors == .link
        let closeButtonConfiguration = PaneLayoutView.ButtonConfiguration(
            title: isLink
                ? STPLocalizedString(
                    "Exit",
                    "A button title. Pressing it exits the bank account connection flow."
                )
                : STPLocalizedString(
                    "Yes, exit",
                    "A button title. The user encounters it as part of a confirmation sheet when trying to exit a screen. Pressing it will exit the screen, and cancel the process of connecting the users bank account."
                ),
            accessibilityIdentifier: "close_confirmation_ok",
            action: { [weak self] in
                guard let self = self else { return }
                let didSelectClose = self.didSelectClose
                self.dismiss(
                    animated: true,
                    completion: {
                        // call `didSelectClose` AFTER we dismiss the
                        // sheet to ensure we don't have bugs where
                        // a view controller is in process of dismissing
                        // while we are trying to present/dismiss another
                        didSelectClose()
                    }
                )
            }
        )
        let cancelButtonConfiguration = PaneLayoutView.ButtonConfiguration(
            title: String.Localized.cancel,
            action: { [weak self] in
                self?.dismiss(animated: true)
            }
        )

        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: isLink
                    ? nil
                    : RoundedIconView(
                        image: .image(.panel_arrow_right),
                        style: .circle,
                        appearance: appearance,
                        imageFlipsForRightToLeftLayoutDirection: true
                    ),
                title: STPLocalizedString(
                    "Exit without connecting?",
                    "The title of a sheet that appears when the user attempts to exit the bank linking screen."
                ),
                subtitle: subtitle(isLink: isLink),
                contentView: nil,
                isSheet: true,
                appearance: appearance
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: isLink ? closeButtonConfiguration : cancelButtonConfiguration,
                secondaryButtonConfiguration: isLink ? cancelButtonConfiguration : closeButtonConfiguration,
                appearance: appearance,
                preferHorizontalButtonsForLink: true
            ).footerView
        )
    }

    private func subtitle(isLink: Bool) -> String {
        guard isLink else {
            return STPLocalizedString(
                "You haven't finished linking your bank account and all progress will be lost.",
                "The subtitle/description of a sheet that appears when the user attempts to exit the bank linking screen."
            )
        }
        guard let businessName else {
            return STPLocalizedString(
                "Your bank account won’t be connected and all progress will be lost.",
                "The subtitle/description of a sheet that appears when the user attempts to exit the bank linking screen."
            )
        }
        return String(format: STPLocalizedString(
            "Your bank account won’t be connected to %@ and all progress will be lost.",
            "The subtitle/description of a sheet that appears when the user attempts to exit the bank linking screen. '%@' is replaced by the business name."
        ), businessName)
    }
}
