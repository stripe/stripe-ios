//
//  LinkWalletButton.swift
//  StripePaymentSheet
//

import SwiftUI
import UIKit

/// A SwiftUI "Pay with Link" button that launches the Link flow using a `LinkWalletButtonViewModel`.
///
/// It behaves like `LinkWalletButtonUIView`, and delivers the result of the Link flow to `onCompletion`.
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) public struct LinkWalletButton: View {
    private let viewModel: LinkWalletButtonViewModel
    private let onWillPresent: () -> Void
    private let onCompletion: (LinkWalletButtonResult) -> Void

    /// Creates a `LinkWalletButton`.
    /// - Parameter viewModel: The view model that looks up the customer and presents the Link flow.
    /// - Parameter onWillPresent: Called right before the button presents the Link flow.
    ///   Use it to clear old error messages, for example.
    /// - Parameter onCompletion: Called when the Link flow finishes, with the same result as
    ///   `LinkWalletButtonUIViewDelegate.linkWalletButtonUIView(_:didFinishWith:)`.
    public init(
        viewModel: LinkWalletButtonViewModel,
        onWillPresent: @escaping () -> Void = {},
        onCompletion: @escaping (LinkWalletButtonResult) -> Void
    ) {
        self.viewModel = viewModel
        self.onWillPresent = onWillPresent
        self.onCompletion = onCompletion
    }

    public var body: some View {
        LinkWalletButtonRepresentable(
            viewModel: viewModel,
            onWillPresent: onWillPresent,
            onCompletion: onCompletion
        )
        .fixedSize(horizontal: false, vertical: true)
        // A new view model needs a new button, since the button is bound to its view model
        .id(ObjectIdentifier(viewModel))
    }
}

private struct LinkWalletButtonRepresentable: UIViewRepresentable {
    let viewModel: LinkWalletButtonViewModel
    let onWillPresent: () -> Void
    let onCompletion: (LinkWalletButtonResult) -> Void

    func makeCoordinator() -> LinkWalletButtonCoordinator {
        LinkWalletButtonCoordinator(onWillPresent: onWillPresent, onCompletion: onCompletion)
    }

    func makeUIView(context: Context) -> LinkWalletButtonUIView {
        let button = LinkWalletButtonUIView(viewModel: viewModel)
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
    var onCompletion: (LinkWalletButtonResult) -> Void

    init(
        onWillPresent: @escaping () -> Void,
        onCompletion: @escaping (LinkWalletButtonResult) -> Void
    ) {
        self.onWillPresent = onWillPresent
        self.onCompletion = onCompletion
    }

    func linkWalletButtonUIViewWillPresent(_ button: LinkWalletButtonUIView) {
        onWillPresent()
    }

    func linkWalletButtonUIView(
        _ button: LinkWalletButtonUIView,
        didFinishWith result: LinkWalletButtonResult
    ) {
        onCompletion(result)
    }
}
