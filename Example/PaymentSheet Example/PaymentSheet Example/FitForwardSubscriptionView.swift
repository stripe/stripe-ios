//Below is a single SwiftUI file demonstrating a “FitFlow” subscription app that uses the example backend at https://stp-mobile-playground-backend-v7.stripedemos.com/. It implements recurring billing via SetupIntents, supports monthly and yearly plans, and shows a dynamic UI based on the user’s active plan. A simple “free trial” style flow can be simulated by creating a SetupIntent and “activating” the plan only if the user’s payment method was successfully set up.
//
//NOTE: This is only a demo. In a real-world scenario, you must handle actual subscription creation and trial management on your backend (e.g. creating a subscription object with a free trial and attaching the payment method to the Customer).
//
//--------------------------------------------------------------------------------

import SwiftUI
import StripePaymentSheet

struct FitFlowContentView: View {
    @StateObject private var viewModel = FitFlowViewModel()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("FitFlow")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Display payment sheet buttons when ready
                if let paymentSheet = viewModel.paymentSheet {
                    VStack(spacing: 16) {
                        Text("Select your plan:")
                            .font(.headline)

                        Button("Monthly Plan - $19.99/month") {
                            viewModel.selectedPlan = .monthly
                            viewModel.presentPaymentSheet()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Yearly Plan - $199.99/year") {
                            viewModel.selectedPlan = .yearly
                            viewModel.presentPaymentSheet()
                        }
                        .buttonStyle(.borderedProminent)

                        // Simulate a free trial (requires card authentication)
                        Button("Free Trial with Card Auth") {
                            viewModel.selectedPlan = .freeTrial
                            viewModel.presentPaymentSheet()
                        }
                        .buttonStyle(.bordered)
                    }
                } else if viewModel.isLoading {
                    ProgressView("Loading…")
                } else {
                    Text("Failed to load payment sheet.")
                        .foregroundColor(.red)
                }

                // Display active plan if any
                if let activePlan = viewModel.activePlan {
                    Text("Active Plan: \(activePlan.title)")
                        .font(.headline)
                        .padding()
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .onAppear {
                // Load PaymentSheet when the view appears
                viewModel.preparePaymentSheet()
            }
            .alert(isPresented: $viewModel.showAlert) {
                Alert(
                    title: Text(viewModel.alertTitle),
                    message: Text(viewModel.alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationTitle("FitFlow")
        }
    }
}

class FitFlowViewModel: ObservableObject {
    private let backendEndpoint = URL(string: "https://stp-mobile-playground-backend-v7.stripedemos.com/checkout")!
    
    // MARK: - Published Properties
    @Published var paymentSheet: PaymentSheet?
    @Published var activePlan: SubscriptionPlan?
    @Published var selectedPlan: SubscriptionPlan = .monthly

    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""

    // MARK: - Enum
    enum SubscriptionPlan {
        case monthly
        case yearly
        case freeTrial

        var title: String {
            switch self {
            case .monthly:   return "Monthly Plan"
            case .yearly:    return "Yearly Plan"
            case .freeTrial: return "Free Trial"
            }
        }
    }

    // MARK: - Main Flow

    /// Sets up the PaymentSheet using a SetupIntent from the stripedemos.com backend.
    /// This approach allows for collecting a user's payment method details once. Then
    /// your backend can create a subscription or handle recurring charges off-session.
    func preparePaymentSheet() {
        isLoading = true
        var request = URLRequest(url: backendEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // We'll request a SetupIntent by specifying `mode: "setup"`.
        let bodyDict: [String: Any] = [
            "mode": "setup",
            "customer": "new",               // Options: "returning" or "cus_xxx" to re-use a test customer
            "merchant_country_code": "US",   // You can change this if needed
            "automatic_payment_methods": true
            // If you need Link or other advanced config, add them here. E.g. "use_link": true
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: bodyDict)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isLoading = false
            }

            if let error = error {
                self?.showError("Failed to fetch SetupIntent: \(error.localizedDescription)")
                return
            }
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let clientSecret = json["intentClientSecret"] as? String,
                  let publishableKey = json["publishableKey"] as? String else {
                self?.showError("Invalid response from backend.")
                return
            }

            STPAPIClient.shared.publishableKey = publishableKey

            // Extract ephemeral key if present
            let ephemeralKeySecret = json["customerEphemeralKeySecret"] as? String
            let customerId = json["customerId"] as? String

            // Configure the PaymentSheet
            var config = PaymentSheet.Configuration()
            config.merchantDisplayName = "FitFlow"
            config.allowsDelayedPaymentMethods = true
            config.returnURL = "payments-example://stripe-redirect" // Adjust if needed

            // If you want Apple Pay, configure it here:
            // config.applePay = PaymentSheet.ApplePayConfiguration(
            //     merchantId: "merchant.com.stripe.umbrella.test",
            //     merchantCountryCode: "US"
            // )

            // If you retrieved a customer
            if let customerId = customerId, let ephemeralKeySecret = ephemeralKeySecret {
                config.customer = .init(id: customerId, ephemeralKeySecret: ephemeralKeySecret)
            }

            DispatchQueue.main.async {
                // Initialize PaymentSheet with the SetupIntent.
                let ps = PaymentSheet(setupIntentClientSecret: clientSecret, configuration: config)
                self?.paymentSheet = ps
            }
        }
        .resume()
    }

    /// Presents the PaymentSheet UI. If the user completes the setup, we mark the plan as active.
    func presentPaymentSheet() {
        guard let paymentSheet = paymentSheet else {
            showError("PaymentSheet not ready.")
            return
        }
        paymentSheet.present(from: UIApplication.currentViewController!) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .completed:
                // In a real app, you’d confirm on your backend that you’ve attached
                // the payment method to a subscription, etc. For now, we simulate success:
                self.activatePlan(for: self.selectedPlan)
                self.showMessage("Success", message: "\(self.selectedPlan.title) is now active!")
            case .canceled:
                self.showMessage("Canceled", message: "Subscription setup was canceled.")
            case .failed(let error):
                self.showError(error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers

    /// Mark the selected plan as active (simulate success).
    private func activatePlan(for plan: SubscriptionPlan) {
        DispatchQueue.main.async {
            self.activePlan = plan
        }
    }

    /// Show errors with an alert.
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.alertTitle = "Error"
            self.alertMessage = message
            self.showAlert = true
        }
    }

    /// Show a success or info message with an alert.
    private func showMessage(_ title: String, message: String) {
        DispatchQueue.main.async {
            self.alertTitle = title
            self.alertMessage = message
            self.showAlert = true
        }
    }
}

// MARK: - UI Helpers

extension UIApplication {
    /// Returns the current top-level view controller
    static var currentViewController: UIViewController? {
        let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        return scene?.windows.first?.rootViewController
    }
}

extension View {
    /// Helper to fetch the top-most UIViewController to present PaymentSheet from
    func currentViewController() -> UIViewController? {
        UIApplication.currentViewController
    }
}

//--------------------------------------------------------------------------------
//
//How It Works:
//
//• preparePaymentSheet()
//  - Posts to the /checkout endpoint on the example backend with "mode": "setup" for a SetupIntent.
//  - The backend returns your publishableKey and a “setupIntentClientSecret.”
//  - PaymentSheet is configured with the returned data.
//
//• presentPaymentSheet()
//  - Shows the PaymentSheet UI, lets the user authenticate a card (or other payment method), and sets up the payment details for future subscription charges.
//  - On success, we simulate an “Activate Plan” by simply saving which plan was selected.
//
//• Free Trial
//  - Tapping “Free Trial with Card Auth” also uses the same SetupIntent approach. In a real-world scenario, you’d combine a SetupIntent with your backend subscription logic to attach a free trial.
//
//This simple example uses ephemeral keys to retrieve and save payment methods if a customer was returned by the /checkout endpoint. Refer to the code and logs from the example backend to see how ephemeral keys, PaymentIntents, SetupIntents, and other parameters can be configured.
