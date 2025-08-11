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
    @State private var fullName: String = ""
    @State private var phone: String = ""
    @State private var country: String = "US"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var statusMessage: String?
    @State private var authenticationResult: String?
    @State private var userExists: Bool?
    @FocusState private var isEmailFieldFocused: Bool

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

                    // User Information Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("User Information")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                            TextField("Enter email address", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .focused($isEmailFieldFocused)
                        }

                        if userExists == false {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                TextField("Enter full name (optional)", text: $fullName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.words)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Phone Number")
                                    .font(.subheadline)
                                TextField("Enter phone number (E.164 format)", text: $phone)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.phonePad)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Country Code")
                                    .font(.subheadline)
                                TextField("Enter country code", text: $country)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.allCharacters)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // User Lookup Section
                    VStack(spacing: 12) {
                        lookupUserButton

                        if let userExists {
                            Text(userExists ? "✅ Existing Link user found" : "❌ New user - registration required")
                                .font(.subheadline)
                                .foregroundColor(userExists ? .green : .orange)
                                .padding(.vertical, 4)
                        }
                    }

                    // Action Buttons
                    VStack(spacing: 12) {
                        registerNewUserButton
                        verifyUserButton

                        collectPaymentMethodButton
                        createPaymentMethodButton

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
    private var lookupUserButton: some View {
        if userExists == nil {
            Button("Lookup User") {
                Task {
                    await lookupUser()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading || email.isEmpty)
        } else {
            Button("Lookup User") {
                Task {
                    await lookupUser()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isLoading || email.isEmpty)
        }
    }

    @ViewBuilder
    private var verifyUserButton: some View {
        if case .requiresVerification = linkController?.linkAccount?.sessionState {
            Button("Verify Existing User") {
                Task {
                    await verifyUser()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
        } else {
            Button("Verify Existing User") {
                Task {
                    await verifyUser()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var registerNewUserButton: some View {
        if userExists == false {
            Button("Register New User") {
                Task {
                    await registerNewUser()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading || phone.isEmpty)
        } else {
            Button("Register New User") {
                Task {
                    await registerNewUser()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isLoading || phone.isEmpty)
        }
    }

    @ViewBuilder
    private var collectPaymentMethodButton: some View {
        if case .verified = linkController?.linkAccount?.sessionState {
            Button("Collect Payment Method") {
                Task {
                    await collectPaymentMethod()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
        } else {
            Button("Collect Payment Method") {
                Task {
                    await collectPaymentMethod()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(isLoading)
        }
    }

    @ViewBuilder
    private var createPaymentMethodButton: some View {
        if linkController?.paymentMethodPreview != nil {
            Button("Create Payment Method") {
                Task {
                    await createPaymentMethod()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
        } else {
            Button("Create Payment Method") {
                Task {
                    await createPaymentMethod()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
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
        STPAPIClient.shared.publishableKey = "pk_test_51K9W3OHMaDsveWq0oLP0ZjldetyfHIqyJcz27k2BpMGHxu9v9Cei2tofzoHncPyk3A49jMkFEgTOBQyAMTUffRLa00xzzARtZO"

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

    private func lookupUser() async {
        guard let linkController else {
            await MainActor.run {
                self.errorMessage = "LinkController not initialized"
            }
            return
        }

        guard !email.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Please enter an email address"
            }
            return
        }

        await MainActor.run {
            self.isEmailFieldFocused = false
            self.isLoading = true
            self.errorMessage = nil
            self.statusMessage = "Looking up user..."
            self.userExists = nil
        }

        do {
            let exists = try await linkController.lookupConsumer(with: email)
            await MainActor.run {
                self.isLoading = false
                self.userExists = exists
                self.statusMessage = exists ? "Existing Link user found" : "New user - registration available"
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "User lookup failed: \(error.localizedDescription)"
                self.statusMessage = nil
                self.userExists = nil
            }
        }
    }

    private func verifyUser() async {
        guard let linkController else {
            await MainActor.run {
                self.errorMessage = "LinkController not initialized"
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.statusMessage = "Presenting verification flow..."
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
            let result = try await linkController.presentForVerification(from: rootViewController)
            await MainActor.run {
                self.isLoading = false
                self.statusMessage = "Verification completed"
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
                self.errorMessage = "Verification failed: \(error.localizedDescription)"
                self.statusMessage = nil
            }
        }
    }

    private func registerNewUser() async {
        guard let linkController else {
            await MainActor.run {
                self.errorMessage = "LinkController not initialized"
            }
            return
        }

        guard !phone.isEmpty else {
            await MainActor.run {
                self.errorMessage = "Phone number is required for registration"
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.statusMessage = "Registering new Link user..."
            self.authenticationResult = nil
        }

        do {
            try await linkController.registerLinkUser(
                fullName: fullName.isEmpty ? nil : fullName,
                phone: phone,
                country: country,
                consentAction: .clicked_button_mobile_v1
            )
            await MainActor.run {
                self.isLoading = false
                self.statusMessage = "Registration completed successfully"
                self.authenticationResult = "Registered"
                // Update user exists state since they're now registered
                self.userExists = true
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Registration failed: \(error.localizedDescription)"
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
            self.isEmailFieldFocused = false
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

        let paymentMethodPreview = await linkController.collectPaymentMethod(
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

    private func createPaymentMethod() async {
        guard let linkController else {
            await MainActor.run {
                self.errorMessage = "LinkController not initialized"
            }
            return
        }

        await MainActor.run {
            self.isLoading = true
            self.errorMessage = nil
            self.statusMessage = "Creating payment method..."
        }

        do {
            let paymentMethod = try await linkController.createPaymentMethod()
            await MainActor.run {
                self.isLoading = false
                self.statusMessage = "Payment method created successfully (ID: \(paymentMethod.stripeId))"
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to create payment method: \(error.localizedDescription)"
                self.statusMessage = nil
            }
        }
    }

    private func resetLinkController() {
        // Clear all state
        linkController = nil
        errorMessage = nil
        statusMessage = nil
        authenticationResult = nil
        userExists = nil
        email = ""
        fullName = ""
        phone = ""
        country = "US"

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
                        Text("Icon:")
                            .fontWeight(.medium)
                        Spacer()
                        Image(uiImage: paymentMethodPreview.icon)
                            .resizable()
                            .frame(width: 24, height: 24)
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
