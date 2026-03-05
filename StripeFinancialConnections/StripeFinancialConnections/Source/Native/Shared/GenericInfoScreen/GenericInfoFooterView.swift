//
//  GenericInfoFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/2/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

func GenericInfoFooterView(
    footer: FinancialConnectionsGenericInfoScreen.Footer?,
    appearance: FinancialConnectionsAppearance,
    didSelectPrimaryButton: (() -> Void)?,
    didSelectSecondaryButton: (() -> Void)?,
    didSelectURL: @escaping (URL) -> Void
) -> UIView? {
    let (footerView, _) = GenericInfoFooterViewAndPrimaryButton(
        footer: footer,
        appearance: appearance,
        didSelectPrimaryButton: didSelectPrimaryButton,
        didSelectSecondaryButton: didSelectSecondaryButton,
        didSelectURL: didSelectURL
    )
    return footerView
}

func GenericInfoFooterViewAndPrimaryButton(
     footer: FinancialConnectionsGenericInfoScreen.Footer?,
     appearance: FinancialConnectionsAppearance,
     didSelectPrimaryButton: (() -> Void)?,
     didSelectSecondaryButton: (() -> Void)?,
     didSelectURL: @escaping (URL) -> Void
 ) -> (footerView: UIView?, primaryButton: StripeUICore.Button?) {
     guard let footer else {
         return (nil, nil)
     }
     let primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration?
     if let primaryCta = footer.primaryCta, let didSelectPrimaryButton {
         primaryButtonConfiguration = PaneLayoutView.ButtonConfiguration(
             title: primaryCta.label,
             accessibilityIdentifier: "generic_info_primary_button",
             action: didSelectPrimaryButton
         )
     } else {
         primaryButtonConfiguration = nil
     }
     let secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration?
     if let secondaryCta = footer.secondaryCta, let didSelectSecondaryButton {
         secondaryButtonConfiguration = PaneLayoutView.ButtonConfiguration(
             title: secondaryCta.label,
             accessibilityIdentifier: "generic_info_secondary_button",
             action: didSelectSecondaryButton
         )
     } else {
         secondaryButtonConfiguration = nil
     }
     let footerView = PaneLayoutView.createFooterView(
         primaryButtonConfiguration: primaryButtonConfiguration,
         secondaryButtonConfiguration: secondaryButtonConfiguration,
         topText: footer.disclaimer,
         appearance: appearance,
         bottomText: footer.belowCta,
         didSelectURL: didSelectURL
     )
     return (footerView.footerView, footerView.primaryButton)
 }
