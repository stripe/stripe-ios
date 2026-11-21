//
//  ExampleLinkWalletButtonCheckoutView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

import StripePayments
@_spi(InternalOnlyAPI) @_spi(LinkControllerPreview) import StripePaymentSheet

@available(iOS 16.0, *)
@MainActor
final class LinkWalletButtonDemoSession: ObservableObject, LinkWalletButtonUIViewDelegate {
    enum Phase {
        case loading
        /// With the UIKit integration, also the `LinkWalletButtonUIView`. The SwiftUI integration's `LinkWalletButton`
        /// creates its own.
        case ready(LinkWalletButtonViewModel, LinkWalletButtonUIView?)
        case error(String)
    }

    struct Message {
        let text: String
        let tint: Color
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var paymentMethod: STPPaymentMethod?
    @Published private(set) var message: Message?
    @Published private(set) var isPlacingOrder = false

    private var configuration = LinkWalletButtonDemoConfiguration()
    private var customerId: String?

    func load(configuration: LinkWalletButtonDemoConfiguration) async {
        guard case .loading = phase else { return }
        self.configuration = configuration

        do {
            let config = try await LinkControllerDemoBackendClient.fetchConfig()
            STPAPIClient.shared.publishableKey = config.publishableKey

            // Read when the view model is created and while Link is presented, so it's reset when the checkout screen disappears
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = configuration.nativeLinkEnabled ? nil : false

            // Only read when the view model is created, so reset it to avoid affecting other demos
            LinkController.forcedLinkBrandForTesting = configuration.linkBrand.brand
            defer { LinkController.forcedLinkBrandForTesting = nil }
            let viewModel = try await LinkWalletButtonViewModel.create(
                mode: makeMode(),
                appearance: configuration.appearance,
                configuration: .init(
                    supportedPaymentMethodTypes: Array(configuration.supportedPaymentMethodTypes),
                    merchantDisplayName: "Example, Inc."
                )
            )

            viewModel.email = configuration.email.isEmpty ? nil : configuration.email
            viewModel.phoneNumber = configuration.phone.isEmpty ? nil : configuration.phone
            switch configuration.uiFramework {
            case .swiftUI:
                phase = .ready(viewModel, nil)
            case .uiKit:
                let button = LinkWalletButtonUIView(viewModel: viewModel)
                button.delegate = self
                phase = .ready(viewModel, button)
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    /// With `.payment` and `.setup`, the client secret provider creates the intent on the demo backend when the button is
    /// tapped, and Link confirms it.
    private func makeMode() -> LinkWalletButtonViewModel.Mode {
        let configuration = configuration
        switch configuration.integration {
        case .payment:
            return .payment(clientSecretProvider: { [weak self] in
                guard let self else { throw CancellationError() }
                return try await LinkControllerDemoBackendClient.createUnconfirmedPaymentIntent(
                    customerId: self.resolveCustomerId(),
                    amount: configuration.amount,
                    currency: configuration.currency
                ).clientSecret
            })
        case .setup:
            return .setup(clientSecretProvider: { [weak self] in
                guard let self else { throw CancellationError() }
                return try await LinkControllerDemoBackendClient.createSetupIntent(customerId: self.resolveCustomerId())
            })
        case .paymentMethod:
            return .paymentMethod
        }
    }

    /// The demo backend's customer, created from the entered email, or else a shared guest customer. The intent is created
    /// before the customer signs in to Link, so there's no payment method email to use yet.
    private func resolveCustomerId() async throws -> String {
        if let customerId {
            return customerId
        }
        let email = configuration.email.isEmpty ? LinkControllerDemoBackendClient.guestCustomerEmail : configuration.email
        let customerId = try await LinkControllerDemoBackendClient.fetchOrCreateCustomer(email: email)
        self.customerId = customerId
        return customerId
    }

    /// With `.paymentMethod`: creates a PaymentIntent, and confirms it with the payment method the customer selected.
    func placeOrder() async {
        guard case .ready(let viewModel, _) = phase, let presentingViewController = UIViewController.topMostViewController() else {
            return
        }
        isPlacingOrder = true
        defer { isPlacingOrder = false }
        message = nil
        let result: LinkWalletButtonResult
        do {
            let paymentIntent = try await LinkControllerDemoBackendClient.createUnconfirmedPaymentIntent(
                customerId: resolveCustomerId(),
                amount: configuration.amount,
                currency: configuration.currency
            )
            result = await viewModel.confirmPaymentIntent(clientSecret: paymentIntent.clientSecret, from: presentingViewController)
        } catch {
            result = .failed(error: error)
        }
        switch result {
        case .completed(let paymentMethod):
            self.paymentMethod = paymentMethod
            message = .init(text: "Order placed!", tint: .green)
        case .canceled:
            message = .init(text: "Authentication canceled", tint: .orange)
        case .failed(let error):
            message = .init(text: "Error: \(error.localizedDescription)", tint: .red)
        }
    }

    func linkWalletButtonWillPresent() {
        message = nil
    }

    func linkWalletButtonDidFinish(with result: LinkWalletButtonResult) {
        switch result {
        case .completed(let paymentMethod):
            self.paymentMethod = paymentMethod
            switch configuration.integration {
            case .payment:
                message = .init(text: "Payment succeeded!", tint: .green)
            case .setup:
                message = .init(text: "Payment method saved", tint: .green)
            case .paymentMethod:
                message = .init(text: "Payment method selected", tint: .green)
            }
        case .canceled:
            message = .init(text: "Link flow canceled", tint: .orange)
        case .failed(let error):
            message = .init(text: "Error: \(error.localizedDescription)", tint: .red)
        }
    }

    // MARK: - LinkWalletButtonUIViewDelegate

    func linkWalletButtonUIViewWillPresent(_ button: LinkWalletButtonUIView) {
        linkWalletButtonWillPresent()
    }

    func linkWalletButtonUIView(_ button: LinkWalletButtonUIView, didFinishWith result: LinkWalletButtonResult) {
        linkWalletButtonDidFinish(with: result)
    }
}

@available(iOS 16.0, *)
struct ExampleLinkWalletButtonCheckoutView: View {
    let configuration: LinkWalletButtonDemoConfiguration

    @StateObject private var session = LinkWalletButtonDemoSession()

    private let lineItems: [(name: String, price: String)] = [
        ("Premium plan (monthly)", "$9.99"),
        ("Priority support", "$1.00"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                DemoSection(title: "Order Summary") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(lineItems, id: \.name) { item in
                            PreviewInfoRow(label: item.name, value: item.price)
                        }
                        Divider()
                        HStack {
                            Text("Total")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("$10.99")
                                .fontWeight(.semibold)
                        }
                    }
                }

                switch session.phase {
                case .loading:
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("Loading Link...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                case .ready(let viewModel, let uiKitButton):
                    if let uiKitButton {
                        LinkWalletButtonUIKitHost(button: uiKitButton)
                            .frame(height: 44)
                    } else {
                        LinkWalletButton(
                            viewModel: viewModel,
                            onWillPresent: { session.linkWalletButtonWillPresent() },
                            onCompletion: { session.linkWalletButtonDidFinish(with: $0) }
                        )
                    }
                case .error(let errorMessage):
                    MessageBanner(text: "Failed to load: \(errorMessage)", tint: .red)
                }

                if let message = session.message {
                    MessageBanner(text: message.text, tint: message.tint)
                }

                if case .ready(let viewModel, _) = session.phase {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .font(.headline)
                        LinkWalletButtonPaymentMethodView(viewModel: viewModel)
                        if let paymentMethod = session.paymentMethod {
                            VStack(alignment: .leading, spacing: 8) {
                                PreviewInfoRow(label: "ID", value: paymentMethod.stripeId)
                                PreviewInfoRow(label: "Type", value: paymentMethod.allResponseFields["type"] as? String ?? "unknown")
                            }
                            .padding()
                            .background(Color(UIColor.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }

                switch configuration.integration {
                case .paymentMethod:
                    let canPlaceOrder = session.paymentMethod != nil && !session.isPlacingOrder
                    Button(session.isPlacingOrder ? "Placing order..." : "Place order") {
                        Task { await session.placeOrder() }
                    }
                    .buttonStyle(PreviewPrimaryButtonStyle())
                    .disabled(!canPlaceOrder)
                    .opacity(canPlaceOrder ? 1 : 0.4)
                case .payment:
                    Text("Tap the Link button to pay. The payment completes inside Link.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                case .setup:
                    Text("Tap the Link button to save a payment method. Link confirms the SetupIntent.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.load(configuration: configuration)
        }
        .onDisappear {
            // Don't affect other demos
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = nil
        }
    }
}

/// Shows the payment method the customer selected in Link, from the view model.
@available(iOS 16.0, *)
private struct LinkWalletButtonPaymentMethodView: View {
    @ObservedObject var viewModel: LinkWalletButtonViewModel

    var body: some View {
        PaymentMethodPreviewCard(paymentMethodPreview: viewModel.paymentMethodPreview)
    }
}

/// Hosts a `LinkWalletButtonUIView` the way a UIKit integration would: in a view controller, using Auto Layout,
/// with `presentingViewController` set explicitly.
@available(iOS 16.0, *)
private struct LinkWalletButtonUIKitHost: UIViewControllerRepresentable {
    let button: LinkWalletButtonUIView

    func makeUIViewController(context: Context) -> LinkWalletButtonHostViewController {
        LinkWalletButtonHostViewController(button: button)
    }

    func updateUIViewController(_ uiViewController: LinkWalletButtonHostViewController, context: Context) {}
}

private final class LinkWalletButtonHostViewController: UIViewController {
    private let button: LinkWalletButtonUIView

    init(button: LinkWalletButtonUIView) {
        self.button = button
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        button.presentingViewController = self
        button.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
}
