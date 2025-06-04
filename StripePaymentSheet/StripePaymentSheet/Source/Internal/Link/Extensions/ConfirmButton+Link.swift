//
//  ConfirmButton+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/12/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension ConfirmButton {

    static func makeLinkButton(
        callToAction: CallToActionType,
        compact: Bool = false,
        didTap: @escaping () -> Void
    ) -> ConfirmButton {
        let directionalLayoutMargins = compact ? LinkUI.compactButtonMargins : LinkUI.buttonMargins

        var appearance = LinkUI.appearance
        appearance.primaryButton.height = LinkUI.primaryButtonHeight(margins: directionalLayoutMargins)

        let button = ConfirmButton(
            callToAction: callToAction,
            appearance: appearance,
            didTap: didTap
        )

        button.directionalLayoutMargins = directionalLayoutMargins

        return button
    }

}
