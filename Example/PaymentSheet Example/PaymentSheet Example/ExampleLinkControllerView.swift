//
//  ExampleLinkControllerView.swift
//  PaymentSheet Example
//
//  Created by Mat Schmid on 7/11/25.
//

import SwiftUI
import UIKit

@_spi(STP) import StripePaymentSheet

@available(iOS 16.0, *)
struct ExampleLinkControllerView: View {
    @State private var linkController: LinkController?
    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var authenticationResult: String?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("LinkController Demo")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Email Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        TextField("Enter email address", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        authenticateButton
                        collectPaymentMethodButton
                        resetButton
                    }

                    // Status Messages
                    if let statusMessage = statusMessage {
                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }

                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }

                    if let authenticationResult {
                        Text("Authentication Result: \(authenticationResult)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                    }

                    if let linkController {
                        LinkAccountView(linkController: linkController)
                        PaymentMethodPreviewView(linkController: linkController)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear {
                initializeLinkController()
            }
            .overlay(
                Group {
                    if isLoading {
                        ProgressView("Loading...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.black.opacity(0.3))
                    }
                }
            )
        }
    }

    @ViewBuilder
    private var authenticateButton: some View {
        if linkController?.linkAccount == nil {
            Button("Authenticate") {
                Task {
                    await authenticateUser()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
        } else {
            Button("Authenticate") {
                Task {
                    await authenticateUser()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var collectPaymentMethodButton: some View {
        if linkController?.linkAccount == nil {
            Button("Collect Payment Method") {
                Task {
                    await collectPaymentMethod()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isLoading)
        } else {
            Button("Collect Payment Method") {
                Task {
                    await collectPaymentMethod()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var resetButton: some View {
        Button("Reset LinkController") {
            resetLinkController()
        }
        .buttonStyle(TertiaryButtonStyle())
        .disabled(isLoading)
    }

    private func initializeLinkController() {
        STPAPIClient.shared.publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"

        isLoading = true
        errorMessage = nil
        statusMessage = "Initializing LinkController..."

        Task {
            do {
                let controller = try await LinkController.create(mode: .setup)
                await MainActor.run {
                    self.linkController = controller
                    self.isLoading = false
                    self.statusMessage = "LinkController initialized successfully"
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Failed to initialize LinkController: \(error.localizedDescription)"
                    self.statusMessage = nil
                }
            }
        }
    }

    private func authenticateUser() async {
        guard let linkController else {
            await MainActor.run {
                self.errorMessage = "LinkController not initialized"
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.statusMessage = "Authenticating user..."
            self.authenticationResult = nil
        }

        guard let rootViewController = findViewController() else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Could not find root view controller"
                self.statusMessage = nil
            }
            return
        }

        do {
            let result = try await linkController.presentForAuthentication(
                email: email,
                from: rootViewController
            )

            await MainActor.run {
                self.isLoading = false
                self.statusMessage = "Authentication completed"
                switch result {
                case .completed:
                    self.authenticationResult = "Completed"
                case .canceled:
                    self.authenticationResult = "Canceled"
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
                self.statusMessage = nil
            }
        }
    }

    private func collectPaymentMethod() async {
        guard let linkController else {
            await MainActor.run {
                self.errorMessage = "LinkController not initialized"
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.statusMessage = "Collecting payment method..."
        }

        guard let rootViewController = findViewController() else {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Could not find root view controller"
                self.statusMessage = nil
            }
            return
        }

        let paymentMethodPreview = await linkController.presentForPayment(
            from: rootViewController,
            with: email
        )

        await MainActor.run {
            self.isLoading = false
            if paymentMethodPreview != nil {
                self.statusMessage = "Payment method collected successfully"
            } else {
                self.statusMessage = "Payment method collection canceled"
            }
        }
    }

    private func resetLinkController() {
        // Clear all state
        linkController = nil
        errorMessage = nil
        statusMessage = nil
        authenticationResult = nil
        email = ""

        initializeLinkController()
    }

    private func findViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        var topController = keyWindow?.rootViewController
        while let presentedViewController = topController?.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}

struct LinkAccountView: View {
    @ObservedObject var linkController: LinkController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Link Account")
                .font(.headline)

            if let linkAccount = linkController.linkAccount {
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Email", value: linkAccount.email)
                    InfoRow(label: "Redacted Phone", value: linkAccount.redactedPhoneNumber ?? "N/A")
                    InfoRow(label: "Is Registered", value: linkAccount.isRegistered ? "Yes" : "No")
                    InfoRow(label: "Session State", value: linkAccount.sessionState.rawValue)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("No Link account available")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PaymentMethodPreviewView: View {
    @ObservedObject var linkController: LinkController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method Preview")
                .font(.headline)

            if let paymentMethodPreview = linkController.paymentMethodPreview {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(uiImage: paymentMethodPreview.icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                        Text("Icon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    InfoRow(label: "Label", value: paymentMethodPreview.label)
                    InfoRow(label: "Sublabel", value: paymentMethodPreview.sublabel ?? "N/A")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            } else {
                Text("No payment method preview available")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text("\(label):")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(configuration.isPressed ? Color.gray.opacity(0.6) : Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.clear)
    }
}

@available(iOS 16.0, *)
#Preview {
    ExampleLinkControllerView()
}
