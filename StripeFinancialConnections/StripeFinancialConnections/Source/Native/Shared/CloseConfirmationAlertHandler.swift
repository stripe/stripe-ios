//
//  CloseConfirmationAlertHandler.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/25/22.
//

import Foundation
import UIKit

final class CloseConfirmationAlertHandler {

    private init() {}

    static func present(
        businessName: String?,
        showNetworkingLanguageInConfirmationAlert: Bool,
        didSelectOK: @escaping () -> Void
    ) {
        guard let topMostViewController = UIViewController.topMostViewController() else {
            return
        }
        let alertController = UIAlertController(
            title: STPLocalizedString(
                "Are you sure you want to cancel?",
                "The title of a pop-up that appears when the user attempts to exit the bank linking screen."
            ),
            message: {
                if showNetworkingLanguageInConfirmationAlert {
                    if let businessName = businessName {
                        return String(
                            format: STPLocalizedString(
                                "If you cancel now, your account will be linked to %@ but it will not be saved to Link.",
                                "The subtitle/description of a pop-up that appears when the user attempts to exit the bank linking screen."
                            ),
                            businessName
                        )
                    } else {
                        return STPLocalizedString(
                            "If you cancel now, your account will be linked but it will not be saved to Link.",
                            "The subtitle/description of a pop-up that appears when the user attempts to exit the bank linking screen."
                        )
                    }
                } else if let businessName = businessName {
                    return String(
                        format: STPLocalizedString(
                            "You haven’t finished linking your bank account to %@.",
                            "The subtitle/description of a pop-up that appears when the user attempts to exit the bank linking screen."
                        ),
                        businessName
                    )
                } else {
                    return STPLocalizedString(
                        "You haven’t finished linking your bank account to Stripe.",
                        "The subtitle/description of a pop-up that appears when the user attempts to exit the bank linking screen."
                    )
                }
            }(),
            preferredStyle: .alert
        )
        alertController.addAction(
            UIAlertAction(
                title: STPLocalizedString(
                    "Back",
                    "A button title. The user encounters it as part of a confirmation pop-up when trying to exit a screen. Pressing it will close the pop-up, and will ensure that the screen does NOT exit."
                ),
                style: .cancel
            )
        )
        alertController.addAction(
            UIAlertAction(
                title: STPLocalizedString(
                    "Yes, cancel",
                    "A button title. The user encounters it as part of a confirmation pop-up when trying to exit a screen. Pressing it will exit the screen, and cancel the process of connecting the users bank account."
                ),
                style: .destructive,
                handler: { _ in
                    didSelectOK()
                }
            )
        )
        topMostViewController.present(alertController, animated: true, completion: nil)
    }
}
