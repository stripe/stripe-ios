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

    private let didSelectClose: () -> Void

    init(didSelectClose: @escaping () -> Void) {
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
                    image: .image(.arrow_right),
                    style: .circle
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
                    title: STPLocalizedString(
                        "Yes, exit",
                        "A button title. The user encounters it as part of a confirmation sheet when trying to exit a screen. Pressing it will exit the screen, and cancel the process of connecting the users bank account."
                    ),
                    action: { [weak self] in
                        guard let self = self else { return }
                        self.dismiss(
                            animated: true,
                            completion: { [didSelectClose] in
                                // call `didSelectClose` AFTER we dismiss the
                                // sheet to ensure we don't have bugs where
                                // a view controller is in process of dismissing
                                // while we are trying to present/dismiss another
                                didSelectClose()
                            }
                        )
                    }
                ),
                secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: STPLocalizedString(
                        "No, continue",
                        "A button title. The user encounters it as part of a confirmation pop-up when trying to exit a screen. Pressing it will close the pop-up, and will ensure that the screen does NOT exit."
                    ),
                    action: { [weak self] in
                        self?.dismiss(animated: true)
                    }
                )
            ).footerView
        )
    }
}
