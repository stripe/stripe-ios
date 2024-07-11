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
        let entryView: UIView?
        switch entry {
        case .text(let textBodyEntry):
            entryView = TextBodyEntryView(
                textBodyEntry,
                didSelectURL: didSelectURL
            )
        case .image(let image):
            _ = image
            entryView = nil // TODO(kgaidis): implement ImageBodyEntry support
        case .unparasable:
            entryView = nil // skip
        }
        if let entryView {
            verticalStackView.addArrangedSubview(entryView)
        }
    }
    // check `isEmpty` in case we were not able to handle any entry type
    return verticalStackView.arrangedSubviews.isEmpty ? nil : verticalStackView
}

private func TextBodyEntryView(
    _ textBodyEntry: FinancialConnectionsGenericInfoScreen.Body.TextBodyEntry,
    didSelectURL: @escaping (URL) -> Void
) -> UIView {
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
            case .center:
                return .center
            case .right:
                return .right
            case .left: fallthrough
            case .unparsable: fallthrough
            case .none:
                return .left
            }
        }()
    )
    textView.setText(
        textBodyEntry.text,
        action: didSelectURL
    )
    return textView
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
