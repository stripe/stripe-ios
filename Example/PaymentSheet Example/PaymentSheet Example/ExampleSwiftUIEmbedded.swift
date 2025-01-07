import SwiftUI
import Stripe
@_spi(EmbeddedPaymentElementPrivateBeta) import StripePaymentSheet

// MARK: - ViewModel
class EmbeddedPaymentViewModel: ObservableObject {
    @Published var embeddedPaymentElement: EmbeddedPaymentElement?
    @Published var isLoading = false
    @Published var paymentResult: PaymentSheetResult?

    let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!

    @MainActor
    func preparePaymentSheet() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await fetchPaymentIntentFromBackend()
            STPAPIClient.shared.publishableKey = response.publishableKey

            var configuration = EmbeddedPaymentElement.Configuration()
            configuration.merchantDisplayName = "Example, Inc."
            configuration.allowsDelayedPaymentMethods = true
            configuration.applePay = .init(
                merchantId: "merchant.com.stripe.umbrella.test",
                merchantCountryCode: "US"
            )
            configuration.customer = .init(
                id: response.customerID,
                ephemeralKeySecret: response.ephemeralKey
            )
            configuration.returnURL = "payments-example://stripe-redirect"

            let intentConfig = PaymentSheet.IntentConfiguration(mode: .payment(amount: 973, currency: "EUR")) { paymentMethod, shouldSavePaymentMethod, intentCreationCallback in
                intentCreationCallback(.success(response.paymentIntentClientSecret))
            }

            let element = try await EmbeddedPaymentElement.create(
                intentConfiguration: intentConfig,
                configuration: configuration
            )

            self.embeddedPaymentElement = element

        } catch {
            print("Error while preparing PaymentSheet: \(error)")
        }
    }

    @MainActor
    func confirmPayment() async {
        guard let element = embeddedPaymentElement else { return }
        isLoading = true
        defer { isLoading = false }

        let result = await element.confirm()
        self.paymentResult = result

        switch result {
        case .completed:
            print("Payment completed!")
        case .failed(let error):
            print("Payment failed with error: \(error)")
        case .canceled:
            print("Payment canceled by user.")
        }
    }

    private func fetchPaymentIntentFromBackend() async throws -> BackendResponse {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard
            let json = json,
            let customerId = json["customer"] as? String,
            let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
            let paymentIntentClientSecret = json["paymentIntent"] as? String,
            let publishableKey = json["publishableKey"] as? String
        else {
            throw URLError(.badServerResponse)
        }

        return BackendResponse(
            publishableKey: publishableKey,
            paymentIntentClientSecret: paymentIntentClientSecret,
            customerID: customerId,
            ephemeralKey: customerEphemeralKeySecret
        )
    }

    struct BackendResponse {
        let publishableKey: String
        let paymentIntentClientSecret: String
        let customerID: String
        let ephemeralKey: String
    }
}

// MARK: - UIViewRepresentable wrapper

struct EmbeddedPaymentElementView: UIViewRepresentable {
    @ObservedObject var viewModel: EmbeddedPaymentViewModel
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        if let element = viewModel.embeddedPaymentElement {
            attachEmbeddedPaymentElement(element, to: containerView, context: context)
        }
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let element = viewModel.embeddedPaymentElement,
           !uiView.subviews.contains(element.view) {
            attachEmbeddedPaymentElement(element, to: uiView, context: context)
        }
        
        DispatchQueue.main.async {
            self.height = uiView.systemLayoutSizeFitting(CGSize(width: uiView.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
        }
    }

    private func attachEmbeddedPaymentElement(
        _ element: EmbeddedPaymentElement,
        to containerView: UIView,
        context: Context
    ) {
        element.delegate = context.coordinator
        element.presentingViewController = context.coordinator.visibleViewController

        let paymentElementView = element.view
        containerView.addSubview(paymentElementView)
        paymentElementView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            paymentElementView.topAnchor.constraint(equalTo: containerView.topAnchor),
            paymentElementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            paymentElementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            paymentElementView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])
    }

    class Coordinator: NSObject, EmbeddedPaymentElementDelegate {
        var parent: EmbeddedPaymentElementView
        var visibleViewController: UIViewController {
            // Get the root view controller
            guard var rootViewController = UIApplication.shared.windows.first?.rootViewController else {
                return UIViewController()
            }
            
            // Navigate through presented view controllers
            while let presentedViewController = rootViewController.presentedViewController {
                rootViewController = presentedViewController
            }
            
            // Handle navigation controllers
            if let navigationController = rootViewController as? UINavigationController {
                return navigationController.visibleViewController ?? navigationController
            }
            
            // Handle tab bar controllers
            if let tabBarController = rootViewController as? UITabBarController,
               let selectedViewController = tabBarController.selectedViewController {
                return selectedViewController
            }
            
            return rootViewController
        }

        init(_ parent: EmbeddedPaymentElementView) {
            self.parent = parent
        }

        func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
            DispatchQueue.main.async {
                self.parent.viewModel.objectWillChange.send()
                if let containerView = embeddedPaymentElement.view.superview {
                    self.parent.height = containerView.systemLayoutSizeFitting(CGSize(width: containerView.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
                }
            }
        }

        func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
            DispatchQueue.main.async {
                self.parent.viewModel.objectWillChange.send()
            }
        }
    }
}

// MARK: - SwiftUI Checkout View

@available(iOS 14.0, *)
struct MyEmbeddedCheckoutView: View {
    @StateObject var viewModel = EmbeddedPaymentViewModel()
    @State private var embeddedViewHeight: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let _ = viewModel.embeddedPaymentElement {
                    EmbeddedPaymentElementView(viewModel: viewModel, height: $embeddedViewHeight)
                        .frame(height: embeddedViewHeight)
                    
                    // Confirm Payment button
                    Button {
                        Task {
                            await viewModel.confirmPayment()
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Confirm Payment")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(
                        viewModel.isLoading
                        || viewModel.embeddedPaymentElement?.paymentOption == nil
                    )
                    .padding()
                    .foregroundColor(.white)
                    .background(viewModel.embeddedPaymentElement?.paymentOption == nil ? Color.gray : Color.blue)
                    .cornerRadius(6)
                } else {
                    if viewModel.isLoading {
                        ProgressView("Preparing Payment...")
                    } else {
                        Text("Payment element not loaded.")
                    }
                }
            }
            .padding()
            .onAppear {
                Task {
                    await viewModel.preparePaymentSheet()
                }
            }
        }
    }
}

// MARK: - SwiftUI Preview
@available(iOS 14.0, *)
struct MyEmbeddedCheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        MyEmbeddedCheckoutView()
    }
}
