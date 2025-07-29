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
        appearance: PaymentSheet.Appearance,
        compact: Bool = false,
        didTap: @escaping () -> Void
    ) -> ConfirmButton {
        let directionalLayoutMargins = compact ? LinkUI.compactButtonMargins : LinkUI.buttonMargins

        // TODO: verify that we should be using the value specified in `LinkAppearance` instead of what was hardcoded here.

        let button = ConfirmButton(
            callToAction: callToAction,
            appearance: appearance,
            didTap: didTap
        )

        button.directionalLayoutMargins = directionalLayoutMargins

        return button
    }

}
