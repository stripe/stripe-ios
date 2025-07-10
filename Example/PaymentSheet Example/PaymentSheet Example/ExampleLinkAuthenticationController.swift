//
//  ExampleLinkAuthenticationController.swift
//  PaymentSheet Example
//
//  Created by Mat Schmid on 7/10/25.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct ExampleLinkAuthenticationController: View {
    @State private var email: String = ""

    var body: some View {
        if #available(iOS 16.0, *) {
            Form {
                Section("LinkAuthenticationController") {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Button("Authenticate") {
                    authenticate()
                }
            }
            .onAppear {
                STPAPIClient.shared.publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"
            }
        } else {
            Text("Use >= iOS 16.0")
        }
    }

    private func authenticate() {
        guard let viewController = findViewController() else {
            return
        }

        Task {
            let linkAuthenticationController = LinkAuthenticationController()
            let result = try await linkAuthenticationController.promptForLinkAuthentication(
                email: email,
                from: viewController
            )
            print("**** result: \(result)")
        }
    }
}

private func findViewController() -> UIViewController? {
    let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    var topController = keyWindow?.rootViewController
    while let presentedViewController = topController?.presentedViewController {
        topController = presentedViewController
    }
    return topController
}
