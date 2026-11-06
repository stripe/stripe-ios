@_spi(STP) import StripePaymentSheet
import SwiftUI

/// A merchant integrates one CheckoutSheet, without assembling individual Elements.
@available(iOS 16.0, *)
struct CheckoutSheetExampleView: View {
    let clientSecret: String
    let emailSettings: CheckoutPlayground.EmailSettings
    let defaultShippingAddress: CheckoutPlayground.DefaultShippingAddress?
    var allowsLink = true
    var allowsApplePay = true
    var delayPaymentPagesRequests = false
    @Environment(\.dismiss) private var dismiss
    @StateObject private var diagnostics = CheckoutSessionDiagnostics()
    @State private var checkoutSheet: CheckoutSheet?
    @State private var isLoading = false
    @State private var isPresenting = false
    @State private var message: String?
    @State private var didComplete = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading Checkout Session…")
                } else if let checkoutSheet {
                    Image(systemName: didComplete ? "checkmark.circle.fill" : "bag")
                        .font(.system(size: 56)).foregroundColor(didComplete ? .green : .primary)
                    Text("Your Cart").font(.largeTitle.bold())
                    ForEach(checkoutSheet.session.orderSummaryItems) { group in
                        switch group {
                        case .oneTimePrice(let price):
                            ForEach(price.items) { item in
                                HStack {
                                    Text("\(item.displayName) × \(item.quantity)")
                                    Spacer()
                                    Text(item.amountDetails.total.amount)
                                }
                            }
                        }
                    }
                    HStack {
                        Text("Total").bold()
                        Spacer()
                        Text(checkoutSheet.session.totals.total.amount).bold()
                    }
                    Button(didComplete ? "Create another session" : "Checkout") {
                        if didComplete { dismiss() } else { Task { await presentCheckout() } }
                    }
                    .buttonStyle(.borderedProminent).controlSize(.large)
                    .disabled(isPresenting).accessibilityIdentifier("launch_checkout_sheet")
                } else {
                    Button("Retry") { Task { await loadCheckout() } }
                }
                if let message { Text(message).font(.subheadline).foregroundColor(.secondary) }
            }
            .padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Checkout Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { dismiss() }.disabled(isPresenting) }
            }
            .task { await loadCheckout() }
        }
    }

    private func loadCheckout() async {
        guard checkoutSheet == nil, !isLoading else { return }
        isLoading = true
        message = nil
        defer { isLoading = false }
        do {
            var configuration = CheckoutSheet.Configuration(
                clientSecret: clientSecret,
                returnURL: "payments-example://stripe-redirect"
            )
            configuration.apiClient = diagnostics.makeAPIClient(
                paymentPagesRequestDelay: delayPaymentPagesRequests ? 1 : 0
            )
            configuration.merchantDisplayName = "Example Store"
            configuration.defaults.email = emailSettings.localDefaultEmail
            configuration.defaults.shippingDetails = defaultShippingAddress?.checkoutShippingDetails
            configuration.allowsLink = allowsLink
            if allowsApplePay {
                configuration.applePay = .init(merchantId: "merchant.com.stripe.paymentsheet.example")
            }
            checkoutSheet = try await CheckoutSheet(configuration: configuration)
        } catch { message = error.localizedDescription }
    }

    private func presentCheckout() async {
        guard let checkoutSheet, !isPresenting else { return }
        isPresenting = true
        defer { isPresenting = false }
        switch await checkoutSheet.present() {
        case .completed(let status):
            didComplete = true
            message = "Checkout completed. Payment status: \(status)."
        case .canceled:
            message = "Checkout canceled. You can reopen the same session."
        case .failed(let error):
            message = error.localizedDescription
        }
    }
}
