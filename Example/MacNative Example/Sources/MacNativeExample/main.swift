import AppKit
import Stripe
import StripePaymentSheet

private struct CheckoutResponse {
    let customerId: String
    let ephemeralKeySecret: String
    let paymentIntentClientSecret: String
    let publishableKey: String
}

private enum ExampleBackend {
    static let checkoutURL = URL(string: "https://stripe-mobile-payment-sheet.stripedemos.com/checkout")!

    static func loadCheckout() async throws -> CheckoutResponse {
        var request = URLRequest(url: checkoutURL)
        request.httpMethod = "POST"

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(
                domain: "MacNativeExample",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Example backend returned an unsuccessful response."]
            )
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let customerId = json["customer"] as? String,
              let ephemeralKeySecret = json["ephemeralKey"] as? String,
              let paymentIntentClientSecret = json["paymentIntent"] as? String,
              let publishableKey = json["publishableKey"] as? String else {
            throw NSError(
                domain: "MacNativeExample",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Example backend response was missing PaymentSheet fields."]
            )
        }

        return CheckoutResponse(
            customerId: customerId,
            ephemeralKeySecret: ephemeralKeySecret,
            paymentIntentClientSecret: paymentIntentClientSecret,
            publishableKey: publishableKey
        )
    }
}

private enum PaymentSheetFactory {
    static func makePaymentSheet(from checkout: CheckoutResponse) -> PaymentSheet {
        STPAPIClient.shared.publishableKey = checkout.publishableKey

        var configuration = PaymentSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.customer = .init(
            id: checkout.customerId,
            ephemeralKeySecret: checkout.ephemeralKeySecret
        )
        configuration.allowsDelayedPaymentMethods = true
        configuration.paymentMethodLayout = .horizontal
        configuration.link.display = .never

        return PaymentSheet(
            paymentIntentClientSecret: checkout.paymentIntentClientSecret,
            configuration: configuration
        )
    }
}

private extension CheckoutResponse {
    var paymentIntentId: String {
        guard let secretRange = paymentIntentClientSecret.range(of: "_secret") else {
            return paymentIntentClientSecret
        }
        return String(paymentIntentClientSecret[..<secretRange.lowerBound])
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow?
    private let presentingViewController = StripePaymentSheet.UIViewController()
    private var paymentSheet: PaymentSheet?
    private let statusLabel = NSTextField(labelWithString: "")
    private let presentButton = NSButton(title: "Open PaymentSheet", target: nil, action: nil)
    private let automaticallyOpenPaymentSheet: Bool

    init(automaticallyOpenPaymentSheet: Bool = false) {
        self.automaticallyOpenPaymentSheet = automaticallyOpenPaymentSheet
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 260),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Stripe macOS Native Example"

        let titleLabel = NSTextField(labelWithString: "Stripe macOS Native Example")
        titleLabel.font = .boldSystemFont(ofSize: 22)

        statusLabel.stringValue = "Loading checkout from \(ExampleBackend.checkoutURL.host ?? "example backend")..."
        statusLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        statusLabel.lineBreakMode = .byWordWrapping
        statusLabel.maximumNumberOfLines = 0

        presentButton.target = self
        presentButton.action = #selector(openPaymentSheet)
        presentButton.bezelStyle = .rounded
        presentButton.isEnabled = false

        let stackView = NSStackView(views: [titleLabel, statusLabel, presentButton])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 18
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let contentView = NSView()
        contentView.addSubview(stackView)
        presentingViewController.view = contentView
        window.contentViewController = presentingViewController

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 28),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -28),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 28),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -28),
        ])

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)

        Task {
            await loadPaymentSheet()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    @MainActor
    private func loadPaymentSheet() async {
        do {
            let checkout = try await ExampleBackend.loadCheckout()
            print("Loaded backend checkout; constructing PaymentSheet")
            fflush(stdout)
            paymentSheet = PaymentSheetFactory.makePaymentSheet(from: checkout)
            print("Constructed PaymentSheet")
            fflush(stdout)
            statusLabel.stringValue = [
                "Loaded PaymentSheet from example backend.",
                "Stripe SDK \(STPAPIClient.STPSDKVersion)",
                "Customer \(checkout.customerId)",
                "PaymentIntent \(checkout.paymentIntentId)",
            ].joined(separator: "\n")
            presentButton.isEnabled = true
            if automaticallyOpenPaymentSheet {
                openPaymentSheet()
            }
        } catch {
            statusLabel.stringValue = "Failed to load PaymentSheet:\n\(error.localizedDescription)"
            presentButton.isEnabled = false
        }
    }

    @objc private func openPaymentSheet() {
        guard let paymentSheet else {
            statusLabel.stringValue = "PaymentSheet is not loaded yet."
            return
        }

        statusLabel.stringValue = "Opening PaymentSheet..."
        print("Calling PaymentSheet.present")
        fflush(stdout)
        paymentSheet.present(from: presentingViewController) { [weak self] result in
            DispatchQueue.main.async {
                print("PaymentSheet completed with result: \(result)")
                fflush(stdout)
                switch result {
                case .completed:
                    self?.statusLabel.stringValue = "PaymentSheet completed."
                case .canceled:
                    self?.statusLabel.stringValue = "PaymentSheet canceled."
                case .failed(let error):
                    self?.statusLabel.stringValue = "PaymentSheet failed:\n\(error.localizedDescription)"
                }
            }
        }
    }
}

if CommandLine.arguments.contains("--smoke-test") {
    let semaphore = DispatchSemaphore(value: 0)
    Task {
        do {
            let checkout = try await ExampleBackend.loadCheckout()
            _ = PaymentSheetFactory.makePaymentSheet(from: checkout)
            print("Loaded PaymentSheet for customer \(checkout.customerId)")
            print("Stripe SDK \(STPAPIClient.STPSDKVersion)")
        } catch {
            fputs("Smoke test failed: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
        semaphore.signal()
    }
    semaphore.wait()
} else {
    let app = NSApplication.shared
    let delegate = AppDelegate(
        automaticallyOpenPaymentSheet: CommandLine.arguments.contains("--auto-open")
    )
    app.delegate = delegate
    if CommandLine.arguments.contains("--auto-open") {
        Timer.scheduledTimer(withTimeInterval: 30, repeats: false) { _ in
            NSApplication.shared.terminate(nil)
        }
    }
    app.run()
}
