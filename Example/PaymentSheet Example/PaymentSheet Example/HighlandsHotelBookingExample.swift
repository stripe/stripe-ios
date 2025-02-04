//Below is a complete, single–file SwiftUI example demonstrating a hotel booking–style PaymentSheet integration that requires a shipping address and uses the configuration options you specified (alwaysLight style, allowsPaymentMethodsRequiringShippingAddress = true, allowsDelayedPaymentMethods = false, savePaymentMethodOptInBehavior = .automatic, and a shippingDetails closure). Replace the backendCheckoutUrl with the URL of your own backend that creates Customer, PaymentIntent, and Ephemeral Key objects, then returns them in JSON:

//
//  HighlandsHotelBookingExample.swift
//  PaymentSheet Example
//
//  Created by Stripe Example on 10/10/23.
//

import SwiftUI
import StripePaymentSheet
@available(iOS 15.0, *)
struct HighlandsHotelBookingExample: View {
    @ObservedObject private var model = HotelBookingModel()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Highlands Hotel Booking")
                    .font(.title)
                    .padding(.top)

                // Example shipping address form
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Full Name", text: $model.shippingName)
                        .textFieldStyle(.roundedBorder)
                    TextField("Phone", text: $model.shippingPhone)
                        .textFieldStyle(.roundedBorder)
                    TextField("Address Line 1", text: $model.shippingLine1)
                        .textFieldStyle(.roundedBorder)
                    TextField("Address Line 2", text: $model.shippingLine2)
                        .textFieldStyle(.roundedBorder)
                    TextField("City", text: $model.shippingCity)
                        .textFieldStyle(.roundedBorder)
                    TextField("State/Province", text: $model.shippingState)
                        .textFieldStyle(.roundedBorder)
                    TextField("Zip/Postal", text: $model.shippingPostalCode)
                        .textFieldStyle(.roundedBorder)
                    TextField("Country (2-letter code)", text: $model.shippingCountry)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                // If we have a PaymentSheet, show the PaymentButton
                if let paymentSheet = model.paymentSheet {
                    PaymentSheet.PaymentButton(
                        paymentSheet: paymentSheet,
                        onCompletion: model.onPaymentCompletion
                    ) {
                        Text("Confirm Booking")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .foregroundColor(.white)
                            .background(Color.blue)
                            .cornerRadius(6)
                    }
                    .padding(.horizontal)
                } else {
                    ProgressView("Loading PaymentSheet…")
                        .padding()
                }

                // Show the result of a payment attempt
                if let paymentResult = model.paymentResult {
                    ExamplePaymentStatusView(result: paymentResult)
                }

                Spacer()
            }
            .onAppear {
                model.preparePaymentSheet()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Our model that talks to a backend, stores shipping info, and configures PaymentSheet
class HotelBookingModel: ObservableObject {
    // Replace with your own backend endpoint that creates:
    // - A PaymentIntent
    // - A Customer (optionally)
    // - An Ephemeral Key
    // Returns { paymentIntent: string, ephemeralKey: string, customer: string, publishableKey: string }
    private let backendCheckoutUrl = URL(string: "https://stripe-mobile-payment-sheet.glitch.me/checkout")!

    // UI state
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?

    // Shipping details stored from user input
    @Published var shippingName: String = ""
    @Published var shippingPhone: String = ""
    @Published var shippingLine1: String = ""
    @Published var shippingLine2: String = ""
    @Published var shippingCity: String = ""
    @Published var shippingState: String = ""
    @Published var shippingPostalCode: String = ""
    @Published var shippingCountry: String = ""

    // MARK: - Create PaymentSheet
    func preparePaymentSheet() {
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data,
                  error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let customerId = json["customer"] as? String,
                  let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                  let paymentIntentClientSecret = json["paymentIntent"] as? String,
                  let publishableKey = json["publishableKey"] as? String else {
                print("Error fetching PaymentIntent or Customer info from the backend.")
                return
            }

            // Pass the publishable key to the Stripe SDK
            STPAPIClient.shared.publishableKey = publishableKey

            // Build our PaymentSheet configuration
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Highlands Hotels"
            
            // This allows Affirm, Afterpay, or other shipping-address PMs to appear
            configuration.allowsPaymentMethodsRequiringShippingAddress = true

            // Provide a closure that returns the shipping address.
            // If `name` and `line1` are present, PaymentSheet attaches shipping to the PaymentIntent metadata.
            configuration.shippingDetails = { [weak self] in
                guard let self = self else { return .init(address: .init(country: "US", line1: "line12")) }
                let address = PaymentSheet.Address(
                    city: self.shippingCity,
                    country: self.shippingCountry,
                    line1: self.shippingLine1,
                    line2: self.shippingLine2,
                    postalCode: self.shippingPostalCode,
                    state: self.shippingState
                )
                let addressDetails = AddressViewController.AddressDetails(
                    address: .init(country: self.shippingCountry, line1: self.shippingLine1), name: self.shippingName,
                    phone: self.shippingPhone
                )
                return addressDetails
            }

            // No delayed-payment methods (requires immediate confirmation)
            configuration.allowsDelayedPaymentMethods = false

            // Always use light mode
            configuration.style = .alwaysLight

            // Let PaymentSheet use regional defaults when offering to save a PM
            configuration.savePaymentMethodOptInBehavior = .automatic

            // Provide a return URL for certain payment flows (3DS, etc.)
            configuration.returnURL = "payments-example://stripe-redirect"

            // If you want to remember the customer's payment methods, set them:
            configuration.customer = .init(
                id: customerId,
                ephemeralKeySecret: customerEphemeralKeySecret
            )

            // Create and store the PaymentSheet
            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(
                    paymentIntentClientSecret: paymentIntentClientSecret,
                    configuration: configuration
                )
            }
        }.resume()
    }

    // MARK: - PaymentSheet Completion
    func onPaymentCompletion(_ result: PaymentSheetResult) {
        DispatchQueue.main.async {
            self.paymentResult = result
        }

        // If the payment was successful, you typically cannot reuse the same PaymentIntent.
        // You might want to fetch a new PaymentIntent if you allow multiple bookings in one session:
        if case .completed = result {
            // Reset and fetch a new PaymentIntent for demonstration:
            DispatchQueue.main.async {
                self.paymentSheet = nil
                self.preparePaymentSheet()
            }
        }
    }
}


// ----------------------------------------------------------------------------
// SwiftUI Preview
@available(iOS 15.0, *)
struct HighlandsHotelBookingExample_Previews: PreviewProvider {
    static var previews: some View {
        HighlandsHotelBookingExample()
    }
}
//-------------------------------------------------------------------------------
//
//Usage Notes:
// • Replace backendCheckoutUrl with your own endpoint that creates a PaymentIntent and ephemeral key for the customer.
// • This example sets allowsPaymentMethodsRequiringShippingAddress = true so that methods like Afterpay or Affirm can appear.
// • style = .alwaysLight keeps the PaymentSheet in a bright theme.
// • allowsDelayedPaymentMethods = false ensures we only accept immediate confirmations.
// • savePaymentMethodOptInBehavior = .automatic follows Stripe’s default per-region rules.
//
//You can adapt this code to your actual booking flow UI, which might prefill or require a shipping address for record-keeping or in-room delivery. After running the example, PaymentSheet will display relevant payment methods requiring a shipping address, and upon successful confirmation, you can update your UI or navigate away as desired.
