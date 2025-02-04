//Below is a single-file SwiftUI example demonstrating how you might set up a “Midnight Market” PaymentSheet with a horizontally scrolling payment method carousel, Apple Pay, support for delayed payment methods, and automatic saving of payment methods. The code includes minimal backend communication (fetching a PaymentIntent client secret and Customer details) and the front-end SwiftUI code required to present PaymentSheet.

import SwiftUI
import StripePaymentSheet

// MARK: - MidnightMarketHorizontalPaymentMethods

/// A SwiftUI view demonstrating a PaymentSheet with a horizontally scrolling payment method carousel,
/// Apple Pay support, and delayed-payment-method allowances.
/// This example uses an example backend at https://stripe-mobile-payment-sheet.glitch.me,
/// which returns test PaymentIntent and Customer data.
/// You should replace that URL with your own backend endpoint in production.
@available(iOS 15.0, *)
struct MidnightMarketHorizontalPaymentMethods: View {
    @ObservedObject private var model = MidnightMarketBackendModel()
    
    var body: some View {
        VStack {
            // If the PaymentSheet has been successfully prepared, show a button to present it.
            if let paymentSheet = model.paymentSheet {
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: model.onCompletion
                ) {
                    Text("Pay with Midnight Market")
                        .font(.headline)
                        .padding()
                }
            } else {
                // Show a simple loading indicator while we fetch data from the backend
                HStack {
                    ProgressView()
                    Text("Loading PaymentSheet…")
                }
            }
            
            // Show the result of any payment attempt
            if let result = model.paymentResult {
                ExamplePaymentStatusView(result: result)
            }
        }
        .padding()
        // Fetch the PaymentIntent data as soon as the view appears
        .onAppear {
            model.preparePaymentSheet()
        }
    }
}

// MARK: - Example UI Elements (for a simpler demo experience)

// MARK: - Model to handle backend communications and store the PaymentSheet

class MidnightMarketBackendModel: ObservableObject {
    // Replace with your real backend endpoint that creates a PaymentIntent and returns
    // JSON including `customer`, `ephemeralKey`, `paymentIntent`, and `publishableKey`.
    private let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!
    
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    
    /// Fetches PaymentIntent and Customer details from the backend,
    /// then configures our PaymentSheet.
    func preparePaymentSheet() {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        
        let task = URLSession.shared.dataTask(with: request) { (data, _, error) in
            guard error == nil,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let customerId = json["customer"] as? String,
                  let ephemeralKeySecret = json["ephemeralKey"] as? String,
                  let paymentIntentClientSecret = json["paymentIntent"] as? String,
                  let publishableKey = json["publishableKey"] as? String
            else {
                // In a real app, you’d want to handle errors here.
                return
            }
            
            // 1. Set your Stripe publishable key so the SDK can make requests to the Stripe API for your account.
            STPAPIClient.shared.publishableKey = publishableKey
            
            // 2. Create a PaymentSheet.Configuration to specify PaymentSheet options
            var configuration = PaymentSheet.Configuration()
            
            // (a) Branding and merchant information
            configuration.merchantDisplayName = "Midnight Market"
            
            // (b) Apple Pay configuration
            configuration.applePay = .init(
                merchantId: "merchant.com.stripe.midnight-market", // Replace with your Apple Pay merchant ID
                merchantCountryCode: "US"
            )
            
            // (c) Attach the customer (for returning payment methods)
            configuration.customer = .init(
                id: customerId,
                ephemeralKeySecret: ephemeralKeySecret
            )
            
            // (d) Let the PaymentSheet know where to return after 3DS
            configuration.returnURL = "midnight-market://stripe-redirect"
            
            // (e) Enable delayed payment methods. Great if you also want bank debits or buy now/pay later.
            configuration.allowsDelayedPaymentMethods = true
            
            // (f) Use a horizontally scrolling carousel
            configuration.paymentMethodLayout = .horizontal
            
            // (g) Automatically match system light/dark mode
            configuration.style = .automatic
            
            // (h) Automatically handle the default state of "save payment method" checkboxes
            configuration.savePaymentMethodOptInBehavior = .automatic
            
            // 3. Create the PaymentSheet object
            let paymentSheet = PaymentSheet(
                paymentIntentClientSecret: paymentIntentClientSecret,
                configuration: configuration
            )
            
            // 4. Update our published property on the main thread
            DispatchQueue.main.async {
                self.paymentSheet = paymentSheet
            }
        }
        
        task.resume()
    }
    
    /// Handle the PaymentSheet completion, storing the result to show the user.
    func onCompletion(result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result
        }
        // If you’d like to allow repeated payments in the same session after success,
        // you can re-fetch a new PaymentIntent from your server here.
    }
}
//--------------------------------------------------------------------------------
//
//Explanation of key configuration choices:
//• paymentMethodLayout = .horizontal
//  This sets the payment method carousel to a horizontal layout.
//• style = .automatic
//  The PaymentSheet user interface will automatically adapt to light or dark mode.
//• allowsDelayedPaymentMethods = true
//  Allows bank debits and buy now, pay later methods that take extra time to finalize.
//• applePay = ApplePayConfiguration(...)
//  Enables adding Apple Pay at the top of the PaymentSheet.
//• savePaymentMethodOptInBehavior = .automatic
//  The “Save this payment method” checkbox state will be automatically controlled by PaymentSheet.
//
//To use in your actual app:
//1. Replace the backendCheckoutUrl with your own endpoint that creates a PaymentIntent (or SetupIntent).
//2. Change the merchantId in the ApplePayConfiguration to your registered Apple Pay merchant ID.
//3. Adjust merchantDisplayName, returnURL, or any other PaymentSheetConfiguration values as needed.
//4. Embed the MidnightMarketHorizontalPaymentMethods() view in your SwiftUI hierarchy.
