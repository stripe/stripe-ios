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

#if DEBUG

import SwiftUI

@available(iOS 14.0, *)
private struct GenericInfoFooterViewUIViewRepresentable: UIViewRepresentable {

    let footer: FinancialConnectionsGenericInfoScreen.Footer

    func makeUIView(context: Context) -> UIView {
        GenericInfoFooterView(
            footer: footer,
            appearance: .stripe,
            didSelectPrimaryButton: {},
            didSelectSecondaryButton: {},
            didSelectURL: { _ in }
        )!
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOS 14.0, *)
struct GenericInfoFooterView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GenericInfoFooterViewUIViewRepresentable(
                footer: FinancialConnectionsGenericInfoScreen.Footer(
                    disclaimer: "Disclaimer Text",
                    primaryCta: FinancialConnectionsGenericInfoScreen
                        .Footer
                        .GenericInfoAction(
                            id: UUID().uuidString,
                            label: "Primary CTA",
                            icon: nil,
                            action: "primary_cta_action",
                            testId: nil
                        ),
                    secondaryCta: FinancialConnectionsGenericInfoScreen
                        .Footer
                        .GenericInfoAction(
                            id: UUID().uuidString,
                            label: "Secondary CTA",
                            icon: nil,
                            action: "secondary_cta_action",
                            testId: nil
                        ),
                    belowCta: "[Below CTA](stripe://link_here)"
                )
            )
            .frame(maxHeight: 228)
            .background(Color.red.opacity(0.1))
        }
        .padding()
    }
}

#endif
