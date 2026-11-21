//
//  InlineLinkOTPHostsDemo.swift
//  PaymentSheet Example
//
// Hosts a returning Link customer's EmbeddedPaymentElement in different merchant layouts, to show where the inline Link
// code is typed in the card and where the SDK falls back to the Link dialog because the keyboard would cover the code.
//  Note: Do not import Stripe using `@_spi(InternalOnlyAPI)` in production.

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripePaymentSheet
import SwiftUI
import UIKit

// MARK: - Scenarios

enum InlineLinkOTPHost: String, CaseIterable, Identifiable {
    case uiKitScrollView
    case uiKitScrollViewBelowTallContent
    case uiKitNoScrollViewTop
    case uiKitNoScrollViewBottom
    case swiftUIScrollView
    case swiftUINoScrollViewBottom

    enum Expectation {
        case inline
        case dialog

        var description: String {
            switch self {
            case .inline: return "Expected: typed in the card"
            case .dialog: return "Expected: Link dialog"
            }
        }
    }

    var id: String { rawValue }

    var isSwiftUI: Bool {
        switch self {
        case .swiftUIScrollView, .swiftUINoScrollViewBottom: return true
        case .uiKitScrollView, .uiKitScrollViewBelowTallContent, .uiKitNoScrollViewTop, .uiKitNoScrollViewBottom: return false
        }
    }

    var title: String {
        switch self {
        case .uiKitScrollView: return "Scroll view"
        case .uiKitScrollViewBelowTallContent: return "Scroll view, below tall content"
        case .uiKitNoScrollViewTop: return "No scroll view, near the top"
        case .uiKitNoScrollViewBottom: return "No scroll view, at the bottom"
        case .swiftUIScrollView: return "ScrollView"
        case .swiftUINoScrollViewBottom: return "No ScrollView, at the bottom"
        }
    }

    var detail: String {
        switch self {
        case .uiKitScrollView:
            return "The element sits near the top of a UIScrollView."
        case .uiKitScrollViewBelowTallContent:
            return "The element is below the fold of a UIScrollView. Scroll down to it; the code is sent once it's on screen. The SDK scrolls the code above the keyboard."
        case .uiKitNoScrollViewTop:
            return "No scroll view, but the code already sits above where the keyboard will be."
        case .uiKitNoScrollViewBottom:
            return "No scroll view, and the element is pinned to the bottom of the screen, so the keyboard would cover the code and nothing can move it."
        case .swiftUIScrollView:
            return "The element sits in a SwiftUI ScrollView."
        case .swiftUINoScrollViewBottom:
            return "No ScrollView, and the element is pushed to the bottom of the screen by a Spacer."
        }
    }

    var expectation: Expectation {
        switch self {
        case .uiKitScrollView, .uiKitScrollViewBelowTallContent, .uiKitNoScrollViewTop, .swiftUIScrollView: return .inline
        case .uiKitNoScrollViewBottom, .swiftUINoScrollViewBottom: return .dialog
        }
    }
}

// MARK: - Scenario list

struct InlineLinkOTPHostsDemoView: View {
    var body: some View {
        List {
            Section {
                Text("Each screen loads EmbeddedPaymentElement for a returning Link customer (foo@bar.com, testmode code 000000). Tap the code boxes once they're enabled and compare where the code is entered with the expectation.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Section("UIKit") {
                ForEach(InlineLinkOTPHost.allCases.filter { !$0.isSwiftUI }) { host in
                    row(for: host)
                }
            }
            Section("SwiftUI") {
                ForEach(InlineLinkOTPHost.allCases.filter(\.isSwiftUI)) { host in
                    row(for: host)
                }
            }
        }
        .navigationTitle("Inline Link OTP hosts")
    }

    private func row(for host: InlineLinkOTPHost) -> some View {
        NavigationLink(destination: InlineLinkOTPHostScreen(host: host)) {
            VStack(alignment: .leading, spacing: 2) {
                Text(host.title)
                Text(host.expectation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityIdentifier(host.rawValue)
    }
}

/// One scenario: the host layout plus a banner describing what should happen and what did.
struct InlineLinkOTPHostScreen: View {
    let host: InlineLinkOTPHost
    @StateObject private var outcome = InlineLinkOTPOutcomeObserver()

    var body: some View {
        Group {
            if host.isSwiftUI {
                InlineLinkOTPSwiftUIHost(host: host, outcome: outcome)
            } else {
                InlineLinkOTPUIKitHost(host: host, outcome: outcome)
                    .ignoresSafeArea(.keyboard)
            }
        }
        .navigationTitle(host.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { outcome.start() }
        .onDisappear { outcome.stop() }
    }
}

// MARK: - Backend

@MainActor
enum InlineLinkOTPDemoBackend {
    struct DemoError: LocalizedError {
        let errorDescription: String?
    }

    /// Registered with Link in testmode.
    static let returningLinkEmail = "foo@bar.com"
    private static var publishableKey: String?

    /// Prepares a fresh element: inline verification on, and no memory of codes sent or cards closed by earlier scenarios.
    static func makeConfiguration() async throws -> EmbeddedPaymentElement.Configuration {
        STPAPIClient.shared.publishableKey = try await loadPublishableKey()
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationEnabledOverride = true
        PaymentSheet.LinkFeatureFlags.embeddedInlineVerificationForcesDialogOverride = false
        PaymentSheet.LinkFeatureFlags.resetEmbeddedInlineVerificationSession()

        var configuration = EmbeddedPaymentElement.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.returnURL = "payments-example://stripe-redirect"
        configuration.allowsLinkInlineVerification = true
        configuration.defaultBillingDetails.email = returningLinkEmail
        configuration.defaultBillingDetails.phone = "+13105551234"
        return configuration
    }

    /// Card and Link only, so the list stays short and the card's position depends on the host layout.
    static var intentConfiguration: PaymentSheet.IntentConfiguration {
        PaymentSheet.IntentConfiguration(
            mode: .payment(amount: 5099, currency: "USD"),
            paymentMethodTypes: ["card", "link"]
        ) { _, _ in
            throw DemoError(errorDescription: "This demo doesn't take payments.")
        }
    }

    /// The test playground backend's publishable key for a US merchant with native Link.
    private static func loadPublishableKey() async throws -> String {
        if let publishableKey {
            return publishableKey
        }
        var request = URLRequest(url: URL(string: PaymentSheetTestPlaygroundSettings.defaultCheckoutEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "customer": "guest",
            "currency": "usd",
            "amount": 5099,
            "merchant_country_code": "US",
            "mode": "payment",
            "automatic_payment_methods": false,
            "use_link": true,
            "link_mode": "native",
            "use_manual_confirmation": false,
            "require_cvc_recollection": false,
            "is_confirmation_token": false,
        ] as [String: Any])
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let key = (try JSONSerialization.jsonObject(with: data) as? [String: Any])?["publishableKey"] as? String else {
            throw DemoError(errorDescription: "The playground backend didn't return a publishable key.")
        }
        publishableKey = key
        return key
    }
}

// MARK: - Outcome

/// Reports where the last tap on the code went, from the SDK's inline Link verification analytics.
@MainActor
final class InlineLinkOTPOutcomeObserver: ObservableObject, STPAnalyticsClientDelegate {
    @Published private(set) var lastEntry: String?
    @Published var loadError: String?
    private weak var previousDelegate: STPAnalyticsClientDelegate?

    func start() {
        guard STPAnalyticsClient.sharedClient.delegate !== self else { return }
        previousDelegate = STPAnalyticsClient.sharedClient.delegate
        STPAnalyticsClient.sharedClient.delegate = self
    }

    func stop() {
        if STPAnalyticsClient.sharedClient.delegate === self {
            STPAnalyticsClient.sharedClient.delegate = previousDelegate
        }
    }

    nonisolated func analyticsClientDidLog(analyticsClient: STPAnalyticsClient, payload: [String: Any]) {
        let event = payload["event"] as? String
        let reason = payload["reason"] as? String
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.previousDelegate?.analyticsClientDidLog(analyticsClient: analyticsClient, payload: payload)
            switch event {
            case "link.embedded_inline_auth.focused":
                self.lastEntry = "Typed in the card"
            case "link.embedded_inline_auth.dialog_shown":
                self.lastEntry = "Link dialog (\(reason ?? "unknown"))"
            default:
                break
            }
        }
    }
}

/// What should happen in this scenario, and what happened on the last tap.
struct InlineLinkOTPBanner: View {
    let host: InlineLinkOTPHost
    @ObservedObject var outcome: InlineLinkOTPOutcomeObserver

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(host.detail)
                .font(.footnote)
            Text(host.expectation.description)
                .font(.footnote.weight(.semibold))
            Text("Last tap: \(outcome.lastEntry ?? "–")")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.accentColor)
                .accessibilityIdentifier("inline_link_otp_outcome")
            if let loadError = outcome.loadError {
                Text(loadError)
                    .font(.footnote)
                    .foregroundColor(.red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - UIKit hosts

struct InlineLinkOTPUIKitHost: UIViewControllerRepresentable {
    let host: InlineLinkOTPHost
    let outcome: InlineLinkOTPOutcomeObserver

    func makeUIViewController(context: Context) -> InlineLinkOTPUIKitHostViewController {
        InlineLinkOTPUIKitHostViewController(host: host, outcome: outcome)
    }

    func updateUIViewController(_ uiViewController: InlineLinkOTPUIKitHostViewController, context: Context) {}
}

/// Lays the element out the way a merchant's UIKit screen might.
final class InlineLinkOTPUIKitHostViewController: UIViewController, EmbeddedPaymentElementDelegate {
    private let host: InlineLinkOTPHost
    private let outcome: InlineLinkOTPOutcomeObserver
    private var embeddedPaymentElement: EmbeddedPaymentElement?
    private let elementContainer = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    init(host: InlineLinkOTPHost, outcome: InlineLinkOTPOutcomeObserver) {
        self.host = host
        self.outcome = outcome
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layOut()
        loadingIndicator.startAnimating()
        Task { await loadElement() }
    }

    private func layOut() {
        let banner = UIHostingController(rootView: InlineLinkOTPBanner(host: host, outcome: outcome))
        addChild(banner)
        banner.view.backgroundColor = .clear
        banner.didMove(toParent: self)
        elementContainer.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: elementContainer.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: elementContainer.topAnchor, constant: 16),
            loadingIndicator.bottomAnchor.constraint(lessThanOrEqualTo: elementContainer.bottomAnchor, constant: -16),
        ])

        let margins: CGFloat = 16
        switch host {
        case .uiKitScrollView, .uiKitScrollViewBelowTallContent:
            let scrollView = UIScrollView()
            scrollView.keyboardDismissMode = .interactive
            let stackView = UIStackView(arrangedSubviews: [banner.view])
            stackView.axis = .vertical
            stackView.spacing = 16
            if host == .uiKitScrollViewBelowTallContent {
                stackView.addArrangedSubview(makeFiller(title: "Order summary", height: 700))
            }
            stackView.addArrangedSubview(elementContainer)
            stackView.addArrangedSubview(makeFiller(title: "More checkout content", height: 160))
            view.addSubview(scrollView)
            scrollView.addSubview(stackView)
            [scrollView, stackView].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: margins),
                stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -margins),
                stackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: margins),
                stackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -margins),
            ])
        case .uiKitNoScrollViewTop, .uiKitNoScrollViewBottom:
            [banner.view, elementContainer].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                view.addSubview($0)
            }
            NSLayoutConstraint.activate([
                banner.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: margins),
                banner.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margins),
                banner.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margins),
                elementContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margins),
                elementContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margins),
            ])
            if host == .uiKitNoScrollViewTop {
                elementContainer.topAnchor.constraint(equalTo: banner.view.bottomAnchor, constant: margins).isActive = true
            } else {
                elementContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -margins).isActive = true
            }
        case .swiftUIScrollView, .swiftUINoScrollViewBottom:
            assertionFailure("SwiftUI scenarios use InlineLinkOTPSwiftUIHost")
        }
    }

    private func makeFiller(title: String, height: CGFloat) -> UIView {
        let label = UILabel()
        label.text = title
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.backgroundColor = .secondarySystemBackground
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.heightAnchor.constraint(equalToConstant: height).isActive = true
        return label
    }

    @MainActor
    private func loadElement() async {
        do {
            let configuration = try await InlineLinkOTPDemoBackend.makeConfiguration()
            let embeddedPaymentElement = try await EmbeddedPaymentElement.create(
                intentConfiguration: InlineLinkOTPDemoBackend.intentConfiguration,
                configuration: configuration
            )
            embeddedPaymentElement.delegate = self
            embeddedPaymentElement.presentingViewController = self
            self.embeddedPaymentElement = embeddedPaymentElement
            loadingIndicator.removeFromSuperview()
            elementContainer.addAndPinSubview(embeddedPaymentElement.view)
        } catch {
            loadingIndicator.stopAnimating()
            outcome.loadError = error.localizedDescription
        }
    }

    func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: EmbeddedPaymentElement) {
        view.layoutIfNeeded()
    }
}

private extension UIView {
    func addAndPinSubview(_ subview: UIView) {
        subview.translatesAutoresizingMaskIntoConstraints = false
        addSubview(subview)
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }
}

// MARK: - SwiftUI hosts

/// Lays the element out the way a merchant's SwiftUI screen might.
struct InlineLinkOTPSwiftUIHost: View {
    let host: InlineLinkOTPHost
    @ObservedObject var outcome: InlineLinkOTPOutcomeObserver
    @StateObject private var viewModel = EmbeddedPaymentElementViewModel()

    var body: some View {
        content
            .padding(16)
            .task {
                guard !viewModel.isLoaded else { return }
                do {
                    try await viewModel.load(
                        intentConfiguration: InlineLinkOTPDemoBackend.intentConfiguration,
                        configuration: try await InlineLinkOTPDemoBackend.makeConfiguration()
                    )
                } catch {
                    outcome.loadError = error.localizedDescription
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch host {
        case .swiftUIScrollView:
            ScrollView {
                VStack(spacing: 16) {
                    InlineLinkOTPBanner(host: host, outcome: outcome)
                    element
                    Color(.secondarySystemBackground)
                        .frame(height: 160)
                        .cornerRadius(8)
                        .overlay(Text("More checkout content").foregroundColor(.secondary))
                }
            }
        default:
            VStack(spacing: 16) {
                InlineLinkOTPBanner(host: host, outcome: outcome)
                Spacer()
                element
            }
        }
    }

    @ViewBuilder
    private var element: some View {
        if viewModel.isLoaded {
            EmbeddedPaymentElementView(viewModel: viewModel)
        } else {
            ProgressView()
        }
    }
}
