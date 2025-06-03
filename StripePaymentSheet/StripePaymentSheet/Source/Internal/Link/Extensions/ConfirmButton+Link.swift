//
//  ConfirmButton+Link.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 1/12/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

extension ConfirmButton {

    private static let minimumLabelHeight: CGFloat = 24
    private static let minimumButtonHeight: CGFloat = 44

    static func makeLinkButton(
        callToAction: CallToActionType,
        compact: Bool = false,
        didTap: @escaping () -> Void
    ) -> ConfirmButton {
        let directionalLayoutMargins = compact ? LinkUI.compactButtonMargins : LinkUI.buttonMargins

        let height = Self.minimumLabelHeight
            + directionalLayoutMargins.top
            + directionalLayoutMargins.bottom

        var appearance = LinkUI.appearance
        appearance.primaryButton.height = max(height, Self.minimumButtonHeight)

        let button = ConfirmButton(
            callToAction: callToAction,
            appearance: appearance,
            didTap: didTap
        )

        button.directionalLayoutMargins = directionalLayoutMargins

        return button
    }

}
