//
//  GenericInfoFooterView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/2/24.
//

import Foundation
import UIKit

func GenericInfoFooterView(
    footer: FinancialConnectionsGenericInfoScreen.Footer?,
    didSelectPrimaryButton: @escaping () -> Void,
    didSelectSecondaryButton: @escaping () -> Void,
    didSelectURL: @escaping (URL) -> Void
) -> UIView? {
    if let footer {
        let primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration?
        if let primaryCta = footer.primaryCta {
            primaryButtonConfiguration = PaneLayoutView.ButtonConfiguration(
                title: primaryCta.label,
                action: didSelectPrimaryButton
            )
        } else {
            primaryButtonConfiguration = nil
        }
        let secondaryButtonConfiguration: PaneLayoutView.ButtonConfiguration?
        if let secondaryCta = footer.secondaryCta {
            secondaryButtonConfiguration = PaneLayoutView.ButtonConfiguration(
                title: secondaryCta.label,
                action: didSelectSecondaryButton
            )
        } else {
            secondaryButtonConfiguration = nil
        }
        return PaneLayoutView.createFooterView(
            primaryButtonConfiguration: primaryButtonConfiguration,
            secondaryButtonConfiguration: secondaryButtonConfiguration,
            topText: footer.disclaimer,
            bottomText: footer.belowCta,
            didSelectURL: didSelectURL
        ).footerView
    } else {
        return nil
    }
}

#if DEBUG

import SwiftUI

@available(iOS 14.0, *)
private struct GenericInfoFooterViewUIViewRepresentable: UIViewRepresentable {

    let footer: FinancialConnectionsGenericInfoScreen.Footer

    func makeUIView(context: Context) -> UIView {
        GenericInfoFooterView(
            footer: footer,
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
