import SwiftUI
import Stripe
@_spi(EmbeddedPaymentElementPrivateBeta) import StripePaymentSheet

// MARK: - ViewModel
class EmbeddedPaymentViewModel: ObservableObject {
    @Published var embeddedPaymentElement: EmbeddedPaymentElement?
    @Published var isLoading = false
    @Published var paymentResult: PaymentSheetResult?

    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
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
            alertTitle = "Success"
            alertMessage = "Payment completed!"
        case .failed(let error):
            alertTitle = "Error"
            alertMessage = "Payment failed with error: \(error.localizedDescription)"
        case .canceled:
            alertTitle = "Cancelled"
            alertMessage = "Payment canceled by user."
        }

        showAlert = true
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
// TOOD(porter) Make this public?
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
        
        viewModel.embeddedPaymentElement?.presentingViewController = context.coordinator.visibleViewController
        
        DispatchQueue.main.async {
            let newHeight = uiView.systemLayoutSizeFitting(CGSize(width: uiView.bounds.width, height: UIView.layoutFittingCompressedSize.height)).height
            self.height = newHeight
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
        let bottomConstraint = paymentElementView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        bottomConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            paymentElementView.topAnchor.constraint(equalTo: containerView.topAnchor),
            paymentElementView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            paymentElementView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bottomConstraint
        ])

    }

    class Coordinator: NSObject, EmbeddedPaymentElementDelegate {
        var parent: EmbeddedPaymentElementView
        
        init(_ parent: EmbeddedPaymentElementView) {
            self.parent = parent
        }

        func embeddedPaymentElementDidUpdateHeight(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
            self.parent.viewModel.objectWillChange.send()
        }

        func embeddedPaymentElementDidUpdatePaymentOption(embeddedPaymentElement: StripePaymentSheet.EmbeddedPaymentElement) {
            self.parent.viewModel.objectWillChange.send()
        }
        
        var visibleViewController: UIViewController {
            // Same logic as before to find the top-most VC
            guard var rootViewController = UIApplication.shared.windows.first?.rootViewController else {
                return UIViewController()
            }
            while let presentedViewController = rootViewController.presentedViewController {
                rootViewController = presentedViewController
            }
            if let navigationController = rootViewController as? UINavigationController {
                return navigationController.visibleViewController ?? navigationController
            }
            if let tabBarController = rootViewController as? UITabBarController,
               let selectedViewController = tabBarController.selectedViewController {
                return selectedViewController
            }
            return rootViewController
        }
    }
}

// MARK: - SwiftUI Checkout View

@available(iOS 15.0, *)
struct MyEmbeddedCheckoutView: View {
    @StateObject var viewModel = EmbeddedPaymentViewModel()
    @State private var embeddedViewHeight: CGFloat = 0
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            if let _ = viewModel.embeddedPaymentElement {
                ScrollView {
                    EmbeddedPaymentElementView(viewModel: viewModel, height: $embeddedViewHeight)
                        .frame(height: embeddedViewHeight)
                    
                    // Payment option row
                    if let paymentOption = viewModel.embeddedPaymentElement?.paymentOption {
                        HStack {
                            Image(uiImage: paymentOption.image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 30)
                            Text(paymentOption.label)
                            Spacer()
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    // Confirm Payment button
                    Button(action: {
                        Task {
                            await viewModel.confirmPayment()
                        }
                    }) {
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
                    
                    // Test height change button
                    Button(action: {
                        viewModel.embeddedPaymentElement?.testHeightChange()
                    }) {
                        Text("Test height change")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.orange)
                    .cornerRadius(6)
                }
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
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("Ok"), action: {
                    dismiss()
                })
            )
        }
    }
}


// MARK: - SwiftUI Preview
@available(iOS 15.0, *)
struct MyEmbeddedCheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        MyEmbeddedCheckoutView()
    }
}
