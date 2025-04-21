//
//  TerminalErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/24.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

func TerminalErrorView(
    allowManualEntry: Bool,
    appearance: FinancialConnectionsAppearance,
    didSelectManualEntry: @escaping () -> Void,
    didSelectClose: @escaping () -> Void
) -> UIView {
    return PaneLayoutView(
        contentView: PaneLayoutView.createContentView(
            iconView: RoundedIconView(
                image: .image(.warning_triangle),
                style: .circle,
                appearance: appearance
            ),
            title: STPLocalizedString(
                "Something went wrong",
                "Title of a screen that shows an error. The error screen appears after user has selected a bank. The error is a generic one: something wrong happened and we are not sure what."
            ),
            subtitle: {
                if allowManualEntry {
                    return STPLocalizedString(
                        "Your account can’t be connected at this time. Please enter your bank details manually or try again later.",
                        "The subtitle/description of a screen that shows an error. The error is generic: something wrong happened and we are not sure what."
                    )
                } else {
                    return STPLocalizedString(
                        "Your account can’t be connected at this time. Please try again later.",
                        "The subtitle/description of a screen that shows an error. The error is generic: something wrong happened and we are not sure what."
                    )
                }
            }(),
            contentView: nil
        ),
        footerView: PaneLayoutView.createFooterView(
            primaryButtonConfiguration: {
                if allowManualEntry {
                    return PaneLayoutView.ButtonConfiguration(
                        title: String.Localized.enter_bank_details_manually,
                        action: {
                            didSelectManualEntry()
                        }
                    )
                } else {
                    return PaneLayoutView.ButtonConfiguration(
                        title: "Close",  // TODO: once we localize use String.Localized.close
                        action: {
                            didSelectClose()
                        }
                    )
                }
            }(),
            appearance: appearance
        ).footerView
    ).createView()
}
