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
final class LinkWalletButtonDemoSession: ObservableObject, LinkWalletButtonDelegate {
    enum Phase {
        case loading
        case ready(LinkController, LinkWalletButton)
        case error(String)
    }

    struct Message {
        let text: String
        let tint: Color
    }

    @Published private(set) var phase: Phase = .loading
    @Published private(set) var paymentMethod: STPPaymentMethod?
    @Published private(set) var message: Message?

    private var configuration = LinkWalletButtonDemoConfiguration()
    private var customerId: String?

    func load(configuration: LinkWalletButtonDemoConfiguration) async {
        guard case .loading = phase else { return }
        self.configuration = configuration

        do {
            let config = try await LinkControllerDemoBackendClient.fetchConfig()
            STPAPIClient.shared.publishableKey = config.publishableKey

            // Read when the controller is created and while Link is presented, so it's reset when the checkout screen disappears
            PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride = configuration.nativeLinkEnabled ? nil : false

            // Only read when the controller is created, so reset it to avoid affecting other demos
            LinkController.forcedLinkBrandForTesting = configuration.linkBrand.brand
            defer { LinkController.forcedLinkBrandForTesting = nil }
            let linkController = try await LinkController.create(
                intentConfiguration: makeIntentConfiguration(),
                appearance: configuration.appearance,
                configuration: .init(
                    supportedPaymentMethodTypes: Array(configuration.supportedPaymentMethodTypes),
                    merchantDisplayName: "Example, Inc."
                )
            )

            let button = LinkWalletButton(
                linkController: linkController,
                email: configuration.email.isEmpty ? nil : configuration.email,
                phoneNumber: configuration.phone.isEmpty ? nil : configuration.phone
            )
            button.delegate = self
            button.showsPaymentMethodPreview = configuration.showsPaymentMethodPreviewOnButton

            phase = .ready(linkController, button)
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    /// With "Pay in Link", an intent configuration whose confirm handler creates the PaymentIntent on the demo backend,
    /// so the button completes the payment inside Link. Otherwise `nil`, so the button returns the selected payment method.
    private func makeIntentConfiguration() -> PaymentSheet.IntentConfiguration? {
        guard configuration.integration == .payInLink else {
            return nil
        }
        let configuration = configuration
        return .init(mode: .payment(amount: configuration.amount, currency: configuration.currency)) { [weak self] paymentMethod, _ in
            guard let self else { throw CancellationError() }
            let customerId = try await self.resolveCustomerId(for: paymentMethod)
            let paymentIntent = try await LinkControllerDemoBackendClient.createDeferredPaymentIntent(
                paymentMethodId: paymentMethod.stripeId,
                customerId: customerId,
                amount: configuration.amount,
                currency: configuration.currency,
                setupFutureUsage: nil,
                confirmOnServer: configuration.confirmOnServer
            )
            return paymentIntent.clientSecret
        }
    }

    /// The demo backend's customer, created from the entered email, or, if none was entered,
    /// from the email Link attaches to the payment method, or else a shared guest customer.
    private func resolveCustomerId(for paymentMethod: STPPaymentMethod) async throws -> String {
        if let customerId {
            return customerId
        }
        let email = LinkControllerDemoBackendClient.customerEmail(enteredEmail: configuration.email, paymentMethod: paymentMethod)
        let customerId = try await LinkControllerDemoBackendClient.fetchOrCreateCustomer(email: email)
        self.customerId = customerId
        return customerId
    }

    // MARK: - LinkWalletButtonDelegate

    func linkWalletButtonWillPresent(_ button: LinkWalletButton) {
        message = nil
    }

    func linkWalletButton(
        _ button: LinkWalletButton,
        didCompleteWith result: Result<LinkController.PaymentMethodResult, Error>
    ) {
        switch result {
        case .success(.completed(let paymentMethod)):
            self.paymentMethod = paymentMethod
            switch configuration.integration {
            case .collectPaymentMethod:
                message = .init(text: "Payment method selected", tint: .green)
            case .payInLink:
                message = .init(text: "Payment succeeded!", tint: .green)
            }
        case .success(.canceled):
            message = .init(text: "Link flow canceled", tint: .orange)
        case .failure(let error):
            message = .init(text: "Error: \(error.localizedDescription)", tint: .red)
        }
    }
}

@available(iOS 16.0, *)
struct ExampleLinkWalletButtonCheckoutView: View {
    let configuration: LinkWalletButtonDemoConfiguration

    @StateObject private var session = LinkWalletButtonDemoSession()
    @State private var isShowingOrderConfirmation = false

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
                        Text("Loading LinkController...")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                case .ready(_, let button):
                    switch configuration.uiFramework {
                    case .swiftUI:
                        LinkWalletButtonView(button: button)
                    case .uiKit:
                        LinkWalletButtonUIKitHost(button: button)
                            .frame(height: 44)
                    }
                case .error(let errorMessage):
                    MessageBanner(text: "Failed to load: \(errorMessage)", tint: .red)
                }

                if let message = session.message {
                    MessageBanner(text: message.text, tint: message.tint)
                }

                if case .ready(let linkController, _) = session.phase {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Payment Method")
                            .font(.headline)
                        LinkControllerPreviewPaymentMethodView(linkController: linkController)
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
                case .collectPaymentMethod:
                    Button("Place order") {
                        isShowingOrderConfirmation = true
                    }
                    .buttonStyle(PreviewPrimaryButtonStyle())
                    .disabled(session.paymentMethod == nil)
                    .opacity(session.paymentMethod == nil ? 0.4 : 1)
                case .payInLink:
                    Text("Tap the Link button to pay. The payment completes inside Link.")
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
        .alert("Order placed", isPresented: $isShowingOrderConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This is a mock checkout, so no payment was made.\n\nPayment method: \(session.paymentMethod?.stripeId ?? "")")
        }
    }
}

/// Hosts a `LinkWalletButton` the way a UIKit integration would: in a view controller, using Auto Layout,
/// with `presentingViewController` set explicitly.
@available(iOS 16.0, *)
private struct LinkWalletButtonUIKitHost: UIViewControllerRepresentable {
    let button: LinkWalletButton

    func makeUIViewController(context: Context) -> LinkWalletButtonHostViewController {
        LinkWalletButtonHostViewController(button: button)
    }

    func updateUIViewController(_ uiViewController: LinkWalletButtonHostViewController, context: Context) {}
}

private final class LinkWalletButtonHostViewController: UIViewController {
    private let button: LinkWalletButton

    init(button: LinkWalletButton) {
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
