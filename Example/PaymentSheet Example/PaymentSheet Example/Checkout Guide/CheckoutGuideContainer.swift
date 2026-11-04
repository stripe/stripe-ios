import Combine
@_spi(InternalOnlyAPI) import StripePaymentSheet
import SwiftUI
import UIKit

// A runnable assembly of the iOS guide at docs revision de7108d1.
// See integration_guide_walkthrough.md for the source ranges and scaffolding decisions.
// This intentionally does not use CheckoutPlayground.SessionFactory or CheckoutCartView.
// Backend bootstrap is outside the guide container so its repeated .task uses
// the same client secret, just as the guide does.
struct CheckoutGuideLauncher: View {
    @State private var clientSecret: String?
    @State private var loadError: Error?
    private let scenario = ProcessInfo.processInfo.environment["STP_CHECKOUT_GUIDE"] ?? "sheet"

    var body: some View {
        NavigationView {
            Group {
                if let clientSecret {
                    CheckoutGuideContainer(clientSecret: clientSecret)
                } else if let loadError {
                    Text(loadError.localizedDescription)
                } else {
                    ProgressView()
                }
            }
        }
        .task {
            do {
                // Server transport and app setup for this guide reproduction.
                let backend = PlaygroundBackend(baseURL: URL(string: CheckoutPlayground.EndpointOption.hosted.endpoint!)!)
                STPAPIClient.shared.publishableKey = try await backend.fetchPublishableKey()
                var parameters: [String: Any] = [
                    "ui_mode": "mobile_elements",
                    "customer_email": "jenny.rosen@example.com",
                    "shipping_address_collection": ["allowed_countries": ["US", "CA"]],
                    "items": [
                        [
                            "type": "one_time_price",
                            "one_time_price": [
                                "items": [
                                    [
                                        "price_data": [
                                            "currency": scenario == "sepa" ? "eur" : "usd",
                                            "unit_amount": 5000,
                                            "product_data": ["name": "Painting class fee", "description": "1-hour painting class"],
                                        ],
                                        "quantity": 1,
                                    ],
                                ],
                            ],
                        ],
                    ],
                ]
                if scenario.hasPrefix("email") { parameters.removeValue(forKey: "customer_email") }
                // The shared test merchant's automatic list omits SEPA. Scope this test
                // Session to it instead of changing shared Dashboard settings.
                if scenario == "sepa" { parameters["allowed_payment_method_types"] = ["sepa_debit"] }
                if scenario == "currency" {
                    parameters["adaptive_pricing"] = ["enabled": true]
                    // Test-mode customer-location override; the product configuration
                    // above is the guide's documented Adaptive Pricing option.
                    parameters["customer_email"] = "test+location_DE@example.com"
                }
                clientSecret = try await backend.createCheckoutSession(
                    stripeVersion: "2026-08-26.preview", requestParams: parameters
                )
            } catch { loadError = error }
        }
    }
}

struct CheckoutGuideContainer: View {
    let clientSecret: String
    @State private var checkout: CheckoutController?
    @State private var loadError: Error?
    @State private var resultMessage: String?
    private let scenario = ProcessInfo.processInfo.environment["STP_CHECKOUT_GUIDE"] ?? "sheet"

    var body: some View {
        Group {
            if let checkout {
                if scenario.hasPrefix("uikit") {
                    CheckoutGuideUIKitHost(checkout: checkout, embedded: scenario.contains("embedded"))
                } else {
                    CheckoutGuideView(checkout: checkout, scenario: scenario)
                }
            } else if let loadError {
                Text(loadError.localizedDescription)
            } else {
                ProgressView()
            }
        }
        .alert("Express result", isPresented: Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })) {
            Button("OK") { resultMessage = nil }
        } message: {
            Text(resultMessage ?? "")
        }
        .task {
            // Minimal control for the guide's repeated-load repro; baseline stays literal.
            if scenario == "navigation-fixed", checkout != nil { return }
            do {
                var configuration = CheckoutController.Configuration(
                    clientSecret: clientSecret, returnURL: "payments-example://stripe-redirect"
                )
                configuration.currencySelectorElement = CurrencySelectorElement.Configuration()
                var expressCheckout = ExpressCheckoutElement.Configuration { result in
                    switch result {
                    case .completed(let paymentStatus): resultMessage = "Payment status: \(paymentStatus)"
                    case .canceled: break
                    case .failed(let error): resultMessage = error.localizedDescription
                    }
                }
                expressCheckout.applePayConfiguration = ExpressCheckoutElement.Configuration.ApplePayConfiguration(
                    merchantId: "merchant.com.stripe.umbrella.test", buttonType: .buy
                )
                configuration.expressCheckoutElement = expressCheckout
                configuration.shippingAddressElement = ShippingAddressElement.Configuration()
                configuration.paymentElement = PaymentElement.Configuration()
                if scenario == "email-no-link" {
                    configuration.paymentElement?.linkConfiguration = .init(display: .never)
                }
                checkout = try await CheckoutController(configuration: configuration)
            } catch {
                loadError = error
            }
        }
    }
}

struct CheckoutGuideView: View {
    @ObservedObject var checkout: CheckoutController
    let scenario: String
    @State private var email = ""
    @FocusState private var emailFocused: Bool
    @State private var message: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Guide checkout")
                if scenario.hasPrefix("navigation") {
                    NavigationLink("Order details") { Text("Merchant order details") }
                }
                Text(guideOrderSummary(checkout.session))
                Text("Total \(checkout.session.totals.total.amount)")
                    .accessibilityIdentifier("guide_total")
                    .accessibilityValue(checkout.session.id)
                if let currencySelector = checkout.getCurrencySelectorElement() {
                    currencySelector.view
                }
                if !checkout.session.availableExpressCheckoutPaymentMethods.isEmpty {
                    checkout.getExpressCheckoutElement().view
                        .transition(.opacity.combined(with: .move(edge: .top)).animation(.easeInOut(duration: 0.25)))
                }
                if scenario.hasPrefix("email") {
                    // The guide prescribes merchant UI plus updateEmail but supplies no snippet.
                    TextField("Checkout email", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .disableAutocorrection(true)
                        .focused($emailFocused)
                        .submitLabel(.done)
                        .onSubmit { emailFocused = false }
                    Button("Update email") {
                        emailFocused = false
                        Task {
                            do { try await checkout.updateEmail(email) } catch { message = error.localizedDescription }
                        }
                    }.disabled(checkout.isUpdating)
                }
                Button("Add shipping address") {
                    Task { await checkout.getShippingAddressElement().present() }
                }.disabled(checkout.isUpdating)
                // Render the changed address as directed by the shipping prose.
                Text(checkout.session.shippingAddress?.address.line1 ?? "No shipping address")
                if scenario.contains("embedded") {
                    checkout.getPaymentElement().view
                } else {
                    Button {
                        Task { await checkout.getPaymentElement().present() }
                    } label: {
                        if let paymentOption = checkout.session.paymentOption {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(paymentOption.label)
                                if let sublabel = paymentOption.sublabel { Text(sublabel).foregroundColor(.secondary) }
                            }
                        } else {
                            Text("Select payment method")
                        }
                    }
                    .disabled(checkout.isUpdating)
                    .accessibilityIdentifier("guide_payment")
                }
                Button("Pay") {
                    Task { handleCheckoutResult(await checkout.confirm()) }
                }
                .disabled(checkout.isUpdating || checkout.session.paymentOption == nil || checkout.session.shippingAddress == nil)
                .accessibilityIdentifier("guide_pay")
            }.padding()
        }
        .alert("Guide result", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
    }

    func handleCheckoutResult(_ result: CheckoutController.ConfirmResult) {
        switch result {
        case .completed(let paymentStatus): message = "Payment status: \(paymentStatus)"
        case .canceled: break
        case .failed(let error): message = error.localizedDescription
        }
    }
}

struct CheckoutGuideUIKitHost: UIViewControllerRepresentable {
    let checkout: CheckoutController
    let embedded: Bool

    func makeUIViewController(context: Context) -> CheckoutGuideViewController {
        CheckoutGuideViewController(checkout: checkout, embedded: embedded)
    }
    func updateUIViewController(_ uiViewController: CheckoutGuideViewController, context: Context) {}
}

final class CheckoutGuideViewController: UIViewController, PaymentElementViewDelegate {
    let checkout: CheckoutController
    let embedded: Bool
    let contentStackView = UIStackView()
    let totalLabel = UILabel()
    let summaryLabel = UILabel()
    let addressLabel = UILabel()
    let shippingButton = UIButton(type: .system)
    let paymentMethodButton = UIButton(type: .system)
    let payButton = UIButton(type: .system)
    var cancellables = Set<AnyCancellable>()

    init(checkout: CheckoutController, embedded: Bool) {
        self.checkout = checkout
        self.embedded = embedded
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        // App-owned layout and target wiring omitted from the guide's partial snippets.
        view.backgroundColor = .systemBackground
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        view.addSubview(scroll)
        scroll.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentStackView.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 20),
            contentStackView.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20),
            contentStackView.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40),
        ])
        totalLabel.accessibilityIdentifier = "guide_total"
        summaryLabel.numberOfLines = 0
        contentStackView.addArrangedSubview(summaryLabel)
        contentStackView.addArrangedSubview(totalLabel)
        if let currencySelector = checkout.getCurrencySelectorElement() {
            currencySelector.uiView.translatesAutoresizingMaskIntoConstraints = false
            contentStackView.addArrangedSubview(currencySelector.uiView)
        }
        let expressView = checkout.getExpressCheckoutElement().uiView
        expressView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.addArrangedSubview(expressView)
        shippingButton.setTitle("Add shipping address", for: .normal)
        shippingButton.addTarget(self, action: #selector(didSelectShippingAddress), for: .touchUpInside)
        contentStackView.addArrangedSubview(shippingButton)
        contentStackView.addArrangedSubview(addressLabel)
        if embedded {
            let paymentElementView = checkout.getPaymentElement().uiView
            paymentElementView.delegate = self
            paymentElementView.translatesAutoresizingMaskIntoConstraints = false
            contentStackView.addArrangedSubview(paymentElementView)
        } else {
            paymentMethodButton.accessibilityIdentifier = "guide_payment"
            paymentMethodButton.addTarget(self, action: #selector(didSelectPaymentMethod), for: .touchUpInside)
            contentStackView.addArrangedSubview(paymentMethodButton)
        }
        payButton.setTitle("Pay", for: .normal)
        payButton.accessibilityIdentifier = "guide_pay"
        payButton.addTarget(self, action: #selector(didSelectPay), for: .touchUpInside)
        contentStackView.addArrangedSubview(payButton)
        checkout.$session.receive(on: DispatchQueue.main).sink { [weak self] session in
            self?.summaryLabel.text = guideOrderSummary(session)
            self?.totalLabel.text = "Total \(session.totals.total.amount)"
            self?.addressLabel.text = session.shippingAddress?.address.line1 ?? "No shipping address"
            self?.updatePayButton()
            self?.updatePaymentMethodButton()
        }.store(in: &cancellables)
        checkout.$isUpdating.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.updatePayButton()
            self?.updatePaymentMethodButton()
        }.store(in: &cancellables)
    }

    func updatePayButton() {
        shippingButton.isEnabled = !checkout.isUpdating
        payButton.isEnabled = !checkout.isUpdating && checkout.session.paymentOption != nil && checkout.session.shippingAddress != nil
    }
    func updatePaymentMethodButton() {
        let title = checkout.session.paymentOption.map {
            [$0.label, $0.sublabel].compactMap { $0 }.joined(separator: "\n")
        } ?? "Select payment method"
        paymentMethodButton.setTitle(title, for: .normal)
        paymentMethodButton.titleLabel?.numberOfLines = 2
        paymentMethodButton.isEnabled = !checkout.isUpdating
    }
    @objc func didSelectShippingAddress() {
        Task { await checkout.getShippingAddressElement().present(from: self) }
    }
    @objc func didSelectPaymentMethod() {
        Task { await checkout.getPaymentElement().present(from: self) }
    }
    @objc func didSelectPay() {
        Task {
            let result = await checkout.confirm(from: self)
            switch result {
            case .completed(let paymentStatus): showMessage("Payment status: \(paymentStatus)")
            case .canceled: break
            case .failed(let error): showMessage(error.localizedDescription)
            }
        }
    }
    func showMessage(_ message: String) {
        let alert = UIAlertController(title: "Guide result", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    func paymentElementViewDidUpdateHeight(paymentElementView: PaymentElementUIView) {
        paymentElementView.invalidateIntrinsicContentSize()
        view.layoutIfNeeded()
    }
}

// The prose requests a full order summary but only shows a total. These fields
// were discovered from the public Session types, not another example checkout.
private func guideOrderSummary(_ session: CheckoutController.Session) -> String {
    var lines = session.orderSummaryItems.flatMap { group -> [String] in
        switch group {
        case .oneTimePrice(let prices):
            return prices.items.map { "\($0.displayName) × \($0.quantity): \($0.amountDetails.total.amount)" }
        }
    }
    lines.append("Subtotal \(session.totals.subtotal.amount)")
    lines.append("Discount \(session.totals.discount.amount)")
    lines.append("Tax \(session.totals.taxExclusive.amount)")
    return lines.joined(separator: "\n")
}
