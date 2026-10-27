//
//  CloseToolbarItem.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/10/26.
//

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import SwiftUI

/// A trailing navigation toolbar item intended to close the current flow.
struct CloseToolbarItem: ToolbarContent {

    /// The action to invoke when the button is activated.
    let action: () -> Void

    // MARK: - ToolbarContent

    var body: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: action) {
                if LiquidGlassDetector.isEnabledInMerchantApp {
                    icon(size: 20)
                } else {
                    icon(size: 12)
                        .frame(width: 32, height: 32)
                        .background(Color.surfaceSecondary, in: Circle())
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
            }
            .accessibilityLabel(String.Localized.close)
        }
    }

    // MARK: - CloseToolbarItem

    private func icon(size: CGFloat) -> some View {
        SwiftUI.Image(uiImage: Image.iconClose.makeImage(template: true))
            .resizable()
            .frame(width: size, height: size)
            .foregroundColor(.textPrimary)
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Close toolbar item", traits: .sizeThatFitsLayout) {
    NavigationStack {
        Color.clear
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                CloseToolbarItem(action: {})
            }
    }
    .frame(width: 280, height: 100)
}
#endif
