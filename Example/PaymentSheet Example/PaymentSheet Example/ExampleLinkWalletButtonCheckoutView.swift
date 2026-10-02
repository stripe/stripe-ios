//
//  ExampleLinkWalletButtonCheckoutView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

import StripePayments
@_spi(LinkControllerPreview) import StripePaymentSheet

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

    func load(configuration: LinkWalletButtonDemoConfiguration) async {
        guard case .loading = phase else { return }

        do {
            let config = try await LinkControllerDemoBackendClient.fetchConfig()
            STPAPIClient.shared.publishableKey = config.publishableKey

            let linkController = try await LinkController.create(
                appearance: configuration.appearance,
                configuration: .init(
                    supportedPaymentMethodTypes: Array(configuration.supportedPaymentMethodTypes),
                    merchantDisplayName: "Example, Inc."
                )
            )

            let button = LinkWalletButton(
                linkController: linkController,
                email: configuration.email,
                phoneNumber: configuration.phone.isEmpty ? nil : configuration.phone
            )
            button.delegate = self
            button.showsPaymentMethodPreview = configuration.showsPaymentMethodPreviewOnButton

            phase = .ready(linkController, button)
        } catch {
            phase = .error(error.localizedDescription)
        }
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
            message = .init(text: "Payment method selected", tint: .green)
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

                Button("Place order") {
                    isShowingOrderConfirmation = true
                }
                .buttonStyle(PreviewPrimaryButtonStyle())
                .disabled(session.paymentMethod == nil)
                .opacity(session.paymentMethod == nil ? 0.4 : 1)
            }
            .padding()
        }
        .navigationTitle("Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await session.load(configuration: configuration)
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
