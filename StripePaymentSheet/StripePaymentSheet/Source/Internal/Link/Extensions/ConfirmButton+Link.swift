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
        showProcessingLabel: Bool,
        compact: Bool = false,
        linkAppearance: LinkAppearance? = nil,
        didTapWhenDisabled: @escaping () -> Void = {},
        didTap: @escaping () -> Void
    ) -> ConfirmButton {
        var directionalLayoutMargins = compact ? LinkUI.compactButtonMargins : LinkUI.buttonMargins

        var appearance = LinkUI.appearance

        if let linkAppearance {
            if let primaryColor = linkAppearance.colors?.primary {
                appearance.primaryButton.backgroundColor = primaryColor
                appearance.primaryButton.successBackgroundColor = primaryColor
            }

            if let buttonConfiguration = linkAppearance.primaryButton {
                appearance.primaryButton.cornerRadius = buttonConfiguration.cornerRadius

                // Adjust the margins to back solve for the `LinkAppearance` customized height.
                let desiredHeight = buttonConfiguration.height
                let verticalMargin = LinkUI.verticalMarginForPrimaryButton(withDesiredHeight: desiredHeight)
                directionalLayoutMargins.top = verticalMargin
                directionalLayoutMargins.bottom = verticalMargin
            }
        }

        appearance.primaryButton.height = LinkUI.primaryButtonHeight(margins: directionalLayoutMargins)

        let button = ConfirmButton(
            callToAction: callToAction,
            showProcessingLabel: showProcessingLabel,
            appearance: appearance,
            didTap: didTap,
            didTapWhenDisabled: didTapWhenDisabled
        )

        button.directionalLayoutMargins = directionalLayoutMargins

        return button
    }

}
