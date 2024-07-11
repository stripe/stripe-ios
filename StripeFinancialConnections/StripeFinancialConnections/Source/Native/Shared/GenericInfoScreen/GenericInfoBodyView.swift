//
//  GenericInfoBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/11/24.
//

import Foundation
import UIKit

func GenericInfoBodyView(
    body: FinancialConnectionsGenericInfoScreen.Body?,
    didSelectURL: @escaping (URL) -> Void
) -> UIView? {
    guard  let body, !body.entries.isEmpty else {
        return nil
    }
    let verticalStackView = UIStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 0
    for entry in body.entries {
        switch entry {
        case .text(let textBodyEntry):
            let font: FinancialConnectionsFont
            let boldFont: FinancialConnectionsFont
            let textColor: UIColor
            switch textBodyEntry.size {
            case .xsmall:
                font = .body(.extraSmall)
                boldFont = .body(.extraSmallEmphasized)
                textColor = .textSubdued
            case .small:
                font = .body(.small)
                boldFont = .body(.smallEmphasized)
                textColor = .textSubdued
            case .medium: fallthrough
            case .unparsable: fallthrough
            case .none:
                font = .body(.medium)
                boldFont = .body(.mediumEmphasized)
                textColor = .textDefault
            }
            let textView = AttributedTextView(
                font: font,
                boldFont: boldFont,
                linkFont: font,
                textColor: textColor,
                alignment: {
                    switch textBodyEntry.alignment {
                    case .left:
                        return .left
                    case .center:
                        return .center
                    case .right:
                        return .right
                    case .unparsable: fallthrough
                    case .none:
                        return nil
                    }
                }()
            )
            textView.setText(
                textBodyEntry.text,
                action: didSelectURL
            )
            verticalStackView.addArrangedSubview(textView)
        case .image(let image):
            print(image)
        case .unparasable:
            break // skip
        }
    }
    // check `isEmpty` in case we were not able to handle any entry type
    return verticalStackView.arrangedSubviews.isEmpty ? nil : verticalStackView
}

#if DEBUG

import SwiftUI

@available(iOS 14.0, *)
private struct GenericInfoBodyViewUIViewRepresentable: UIViewRepresentable {

    let body: FinancialConnectionsGenericInfoScreen.Body

    func makeUIView(context: Context) -> UIView {
        return AutoResizableUIView(
            contentView: GenericInfoBodyView(
                body: body,
                didSelectURL: { _ in }
            )!
        )
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.sizeToFit()
    }
}

@available(iOS 14.0, *)
struct GenericInfoBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GenericInfoBodyViewUIViewRepresentable(
                body: FinancialConnectionsGenericInfoScreen.Body(
                    entries: [
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "Text - Alignment(nil) - Size (nil)",
                                alignment: nil,
                                size: nil
                            )
                        ),
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "Text - Alignment(left) - Size (xsmall)",
                                alignment: .left,
                                size: .xsmall
                            )
                        ),
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "Text - Alignment(center) - Size (small)",
                                alignment: .center,
                                size: .small
                            )
                        ),
                        .text(
                            FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry(
                                id: "",
                                text: "Text - Alignment(right) - Size (medium)",
                                alignment: .right,
                                size: .medium
                            )
                        ),
                    ]
                )
            )
            .applyAutoResizableUIViewModifier()
            .padding()
            Spacer()
        }
    }
}

#endif
