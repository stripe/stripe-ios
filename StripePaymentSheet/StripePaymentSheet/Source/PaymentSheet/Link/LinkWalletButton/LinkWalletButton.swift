//
//  LinkWalletButton.swift
//  StripePaymentSheet
//

import SwiftUI
import UIKit

/// A SwiftUI "Pay with Link" button that launches the Link flow using a `LinkController`.
///
/// It behaves like `LinkWalletButtonUIView`, and delivers the result of the Link flow to `onCompletion`.
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public struct LinkWalletButton: View {
    private let linkController: LinkController
    private let onWillPresent: () -> Void
    private let onCompletion: (Result<LinkController.PaymentMethodResult, Error>) -> Void

    /// Creates a `LinkWalletButton`.
    /// - Parameter linkController: The `LinkController` used to look up the customer and present the Link flow.
    /// - Parameter onWillPresent: Called right before the button presents the Link flow.
    ///   Use it to clear old error messages, for example.
    /// - Parameter onCompletion: Called when the Link flow finishes, with the same result as
    ///   `LinkWalletButtonUIViewDelegate.linkWalletButtonUIView(_:didCompleteWith:)`.
    public init(
        linkController: LinkController,
        onWillPresent: @escaping () -> Void = {},
        onCompletion: @escaping (Result<LinkController.PaymentMethodResult, Error>) -> Void
    ) {
        self.linkController = linkController
        self.onWillPresent = onWillPresent
        self.onCompletion = onCompletion
    }

    public var body: some View {
        LinkWalletButtonRepresentable(
            linkController: linkController,
            onWillPresent: onWillPresent,
            onCompletion: onCompletion
        )
        .fixedSize(horizontal: false, vertical: true)
        // A new controller needs a new button, since the button is bound to its controller
        .id(ObjectIdentifier(linkController))
    }
}

private struct LinkWalletButtonRepresentable: UIViewRepresentable {
    let linkController: LinkController
    let onWillPresent: () -> Void
    let onCompletion: (Result<LinkController.PaymentMethodResult, Error>) -> Void

    func makeCoordinator() -> LinkWalletButtonCoordinator {
        LinkWalletButtonCoordinator(onWillPresent: onWillPresent, onCompletion: onCompletion)
    }

    func makeUIView(context: Context) -> LinkWalletButtonUIView {
        let button = LinkWalletButtonUIView(linkController: linkController)
        button.delegate = context.coordinator
        return button
    }

    func updateUIView(_ uiView: LinkWalletButtonUIView, context: Context) {
        // Use the latest closures, which may capture new state
        context.coordinator.onWillPresent = onWillPresent
        context.coordinator.onCompletion = onCompletion
    }
}

/// Forwards the `LinkWalletButtonUIView`'s delegate calls to the `LinkWalletButton`'s closures.
@MainActor
final class LinkWalletButtonCoordinator: LinkWalletButtonUIViewDelegate {
    var onWillPresent: () -> Void
    var onCompletion: (Result<LinkController.PaymentMethodResult, Error>) -> Void

    init(
        onWillPresent: @escaping () -> Void,
        onCompletion: @escaping (Result<LinkController.PaymentMethodResult, Error>) -> Void
    ) {
        self.onWillPresent = onWillPresent
        self.onCompletion = onCompletion
    }

    func linkWalletButtonUIViewWillPresent(_ button: LinkWalletButtonUIView) {
        onWillPresent()
    }

    func linkWalletButtonUIView(
        _ button: LinkWalletButtonUIView,
        didCompleteWith result: Result<LinkController.PaymentMethodResult, Error>
    ) {
        onCompletion(result)
    }
}
