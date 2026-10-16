//
//  LinkWalletButtonView.swift
//  StripePaymentSheet
//

import SwiftUI
import UIKit

/// A SwiftUI view that displays a `LinkWalletButton`.
///
/// Set the button's `delegate` to receive the result of the Link flow.
@_spi(STP) @_spi(LinkControllerPreview) public struct LinkWalletButtonView: View {
    private let button: LinkWalletButton

    /// Creates a view that displays the given `LinkWalletButton`.
    public init(button: LinkWalletButton) {
        self.button = button
    }

    public var body: some View {
        LinkWalletButtonRepresentable(button: button)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct LinkWalletButtonRepresentable: UIViewRepresentable {
    let button: LinkWalletButton

    func makeUIView(context: Context) -> LinkWalletButton {
        return button
    }

    func updateUIView(_ uiView: LinkWalletButton, context: Context) {}
}
