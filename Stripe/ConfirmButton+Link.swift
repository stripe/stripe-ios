//
//  ConfirmButton+Link.swift
//  StripeiOS
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
        let button = ConfirmButton(
            callToAction: callToAction,
            appearance: LinkUI.appearance,
            didTap: didTap
        )

        // Override the background color of the `.succeeded` state. Make it match
        // the background color of the `.enabled` state.
        button.succeededBackgroundColor = (
            LinkUI.appearance.primaryButton.backgroundColor ??
            LinkUI.appearance.colors.primary
        )

        button.directionalLayoutMargins = compact
            ? LinkUI.compactButtonMargins
            : LinkUI.buttonMargins

        return button
    }

}
