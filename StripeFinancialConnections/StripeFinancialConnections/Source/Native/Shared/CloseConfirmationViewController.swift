//
//  CloseConfirmationViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/19/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class CloseConfirmationViewController: SheetViewController {

    private let appearance: FinancialConnectionsAppearance
    private let didSelectClose: () -> Void

    init(appearance: FinancialConnectionsAppearance, didSelectClose: @escaping () -> Void) {
        self.appearance = appearance
        self.didSelectClose = didSelectClose
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup(
            withContentView: PaneLayoutView.createContentView(
                iconView: RoundedIconView(
                    image: .image(.panel_arrow_right),
                    style: .circle,
                    appearance: appearance
                ),
                title: STPLocalizedString(
                    "Exit without connecting?",
                    "The title of a sheet that appears when the user attempts to exit the bank linking screen."
                ),
                subtitle: STPLocalizedString(
                    "You haven't finished linking your bank account and all progress will be lost.",
                    "The subtitle/description of a sheet that appears when the user attempts to exit the bank linking screen."
                ),
                contentView: nil,
                isSheet: true
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: "Cancel", // TODO: when Financial Connections starts supporting localization, change this to `String.Localized.cancel`
                    action: { [weak self] in
                        self?.dismiss(animated: true)
                    }
                ),
                secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: STPLocalizedString(
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
                ),
                appearance: appearance
            ).footerView
        )
    }
}
