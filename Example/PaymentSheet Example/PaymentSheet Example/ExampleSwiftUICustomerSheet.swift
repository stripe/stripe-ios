//
//  ExampleSwiftUICustomerSheet.swift
//  PaymentSheet Example
//

import StripePaymentSheet
import SwiftUI
struct ExampleSwiftUICustomerSheet: View {
    @State private var showingCustomerSheet = false
    @ObservedObject var model = MyBackendCustomerSheetModel()

    var body: some View {
        VStack {
            Image(systemName: "arrow.clockwise.circle")
                .resizable()
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .onTapGesture {
                    model.customerSheet = nil
                    model.prepareCustomerSheet()
                }

            Spacer().frame(height: 50)
            if model.shouldUseNewCustomer {
                Button("Using New Customer (Tap to Switch)") {
                    model.toggleUseNewCustomer()
                    model.prepareCustomerSheet()
                }
            } else {
                Button("Using Returning Customer (Tap to Switch)") {
                    model.toggleUseNewCustomer()
                    model.prepareCustomerSheet()
                }
            }
            Spacer().frame(height: 50)

            if let customerSheet = model.customerSheet {
                Button(action: {
                    showingCustomerSheet = true
                }) {
                    Text("Present Customer Sheet")
                }.customerSheet(
                    isPresented: $showingCustomerSheet,
                    customerSheet: customerSheet,
                    onCompletion: model.onCompletion)
            } else {
                ExampleLoadingView()
            }
            if let customerSheetStatusViewModel = model.customerSheetStatusViewModel {
                ExampleCustomerSheetPaymentMethodView(customerSheetStatusViewModel: customerSheetStatusViewModel)
            }
        }.onAppear {
            model.prepareCustomerSheet()
        }
    }
}

class MyBackendCustomerSheetModel: ObservableObject {
    // An example backend endpoint
    let backendCheckoutUrl = URL(string: "https://stp-mobile-playground-backend-v7.stripedemos.com")!

    @Published var customerSheet: CustomerSheet?
    @Published var customerSheetStatusViewModel: CustomerSheetStatusViewModel?
    var shouldUseNewCustomer = false

    func prepareCustomerSheet() {
        let customer_type = shouldUseNewCustomer ? "new" : "returning"
        let body = [
            "customer_type": customer_type
        ] as [String: Any]

        let url = URL(string: "\(backendCheckoutUrl)/customer_ephemeral_key")!
        let session = URLSession.shared

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let task = session.dataTask(with: urlRequest) { data, _, error in
            guard
                error == nil,
                let data = data,
                let json = try? JSONDecoder().decode([String: String].self, from: data) else {
                print(error as Any)
                self.configureCustomerSheet(response: nil)
                return
            }
            self.configureCustomerSheet(response: json)
        }
        task.resume()
    }

    func toggleUseNewCustomer() {
        shouldUseNewCustomer = !shouldUseNewCustomer
    }

    func onCompletion(result: CustomerSheet.CustomerSheetResult) {
        switch result {
        case .selected(let selection):
            self.customerSheetStatusViewModel = .selected(selection)
        case .canceled(let selection):
            self.customerSheetStatusViewModel = .canceled(selection)
        case .error(let error):
            self.customerSheetStatusViewModel = .error(error)
        }
    }

    func createSetupIntent(customerId: String) async throws -> String {
        let body = [ "customer_id": customerId,
        ] as [String: Any]
        let url = URL(string: "\(backendCheckoutUrl)/create_setup_intent")!
        let session = URLSession.shared

        let json = try! JSONSerialization.data(withJSONObject: body, options: [])
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = json
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-type")
        let (data, _) = try await session.data(for: urlRequest)
        let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        guard let secret = jsonResponse?["client_secret"] as? String else {
            throw NSError(domain: "test", code: 0, userInfo: nil) // Throw more specific error
        }
        return secret
    }

    func configureCustomerSheet(response: [String: String]?) {
        guard let json = response,
              let ephemeralKey = json["customerEphemeralKeySecret"], !ephemeralKey.isEmpty,
              let customerId = json["customerId"], !customerId.isEmpty,
              let publishableKey = json["publishableKey"] else {
            return
        }
        STPAPIClient.shared.publishableKey = publishableKey

        // Create Customer Sheet
        var configuration = CustomerSheet.Configuration()
        configuration.merchantDisplayName = "Example, Inc."
        configuration.applePayEnabled = true
        configuration.returnURL = "payments-example://stripe-redirect"

        let customerAdapter = StripeCustomerAdapter(customerEphemeralKeyProvider: {
            // This should be a block that fetches this from your server
            .init(customerId: customerId, ephemeralKeySecret: ephemeralKey)
        }, setupIntentClientSecretProvider: {
            return try await self.createSetupIntent(customerId: customerId)
        })
        DispatchQueue.main.async {
            self.customerSheet = CustomerSheet(configuration: configuration,
                                               customer: customerAdapter)
        }

        Task {
            do {
                let selection = try await customerAdapter.retrievePaymentOptionSelection()
                DispatchQueue.main.async {
                    self.customerSheetStatusViewModel = .loaded(selection)
                }
            } catch {
                throw error
            }
        }
    }
}
