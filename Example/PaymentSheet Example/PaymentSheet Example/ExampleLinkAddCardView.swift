//
//  ExampleLinkAddCardView.swift
//  PaymentSheet Example
//

import SwiftUI
import UIKit

import StripePayments
@_spi(LinkAddCardPreview) import StripePaymentSheet

/// A chatbot-style demo of `LinkAgentWalletViewController`. The settings are behind the gear icon in the toolbar.
struct ExampleLinkAddCardView: View {
    @StateObject private var settings = ExampleLinkAddCardSettings()
    @State private var isShowingSettings = false
    @State private var messages: [ChatMessage] = [
        ChatMessage(.user("I'm almost out of coffee. Find me a good medium roast.")),
        ChatMessage(.assistantText("How about this?")),
        ChatMessage(.product(name: "Jupiter Cosmic Roast", size: "12 oz", price: "$18.99")),
        ChatMessage(.user("Buy it!")),
        ChatMessage(.status(
            title: "Shipping details",
            subtitle: "Filled into the page. Secret values were never shown to your Bot.",
            status: "Submitted"
        )),
        ChatMessage(.addCard(text: "Great! I'll need you to add a card to make this purchase.", detail: nil)),
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        Text("Today \(Date().formatted(date: .omitted, time: .shortened))")
                            .font(.footnote)
                            .foregroundColor(ChatColors.secondaryText)
                        ForEach(messages) { message in
                            ChatMessageView(message: message) {
                                presentAddCard()
                            }
                            .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .onChange(of: messages.count) { _ in
                    if let lastMessage = messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            ChatInputBar(placeholder: "Ask \(settings.merchantDisplayName)")
        }
        .background(ChatColors.background.ignoresSafeArea())
        .environment(\.colorScheme, .dark)
        .navigationTitle(settings.merchantDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            ExampleLinkAddCardSettingsView(settings: settings)
        }
    }

    private func presentAddCard() {
        guard let presentingViewController = findViewController() else {
            messages.append(ChatMessage(.assistantText("I couldn't open the card form. Please try again.")))
            return
        }

        let apiClient = STPAPIClient(publishableKey: settings.publishableKey)
        var navigationController: UINavigationController?
        let addCardViewController = LinkAgentWalletViewController(
            merchantDisplayName: settings.merchantDisplayName,
            email: settings.email,
            phoneNumber: settings.phoneNumber,
            fullName: settings.fullName,
            appearance: settings.linkAppearance,
            apiClient: apiClient
        ) { result in
            navigationController?.dismiss(animated: true)
            switch result {
            case .completed(let paymentDetailsID):
                appendMessagesAfterDismissal([
                    ChatMessage(.status(
                        title: "Payment method",
                        subtitle: "Added through Link. Your card details were never shown to your Bot.\n\(paymentDetailsID)",
                        status: "Card added"
                    )),
                    ChatMessage(.assistantText("Thanks! I'll use this card to buy your Jupiter Cosmic Roast.")),
                ])
            case .canceled:
                appendMessagesAfterDismissal([
                    ChatMessage(.addCard(
                        text: "No problem. Let me know when you're ready to add a card.",
                        detail: nil
                    )),
                ])
            case .failed(let error):
                appendMessagesAfterDismissal([
                    ChatMessage(.addCard(
                        text: "Sorry, something went wrong while adding your card.",
                        detail: "\(error)"
                    )),
                ])
            }
        }
        navigationController = UINavigationController(rootViewController: addCardViewController)
        presentingViewController.present(navigationController!, animated: true)
    }

    /// Adds the bot's replies one at a time, starting after the Link view controller finishes dismissing,
    /// so the customer sees each new message arrive.
    private func appendMessagesAfterDismissal(_ newMessages: [ChatMessage]) {
        let dismissalDelay = 0.6
        let delayBetweenMessages = 0.8
        for (index, message) in newMessages.enumerated() {
            let delay = dismissalDelay + Double(index) * delayBetweenMessages
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation {
                    messages.append(message)
                }
            }
        }
    }
}

// MARK: - Chat

private enum ChatColors {
    static let background = Color(white: 0.07)
    static let assistantBubble = Color(white: 0.12)
    static let userBubble = Color(white: 0.3)
    static let inputField = Color(white: 0.16)
    static let secondaryText = Color(white: 0.55)
    static let success = Color(red: 0.13, green: 0.68, blue: 0.38)
    static let successBackground = Color(red: 0.1, green: 0.2, blue: 0.14)
}

private struct ChatMessage: Identifiable {
    enum Kind {
        case user(String)
        case assistantText(String)
        case product(name: String, size: String, price: String)
        case status(title: String, subtitle: String, status: String)
        case addCard(text: String, detail: String?)
    }

    let id = UUID()
    let kind: Kind

    init(_ kind: Kind) {
        self.kind = kind
    }
}

private struct ChatMessageView: View {
    let message: ChatMessage
    let didTapAddCard: () -> Void

    var body: some View {
        switch message.kind {
        case .user(let text):
            HStack {
                Spacer(minLength: 56)
                Text(text)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(ChatColors.userBubble)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        case .assistantText(let text):
            AssistantBubble {
                Text(text)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        case .product(let name, let size, let price):
            HStack {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(LinearGradient(
                            colors: [Color(red: 0.72, green: 0.38, blue: 0.2), Color(red: 0.42, green: 0.2, blue: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "cup.and.saucer.fill")
                                .font(.title2)
                                .foregroundColor(.white.opacity(0.9))
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text(name)
                            .foregroundColor(.white)
                        Text(size)
                            .foregroundColor(ChatColors.secondaryText)
                        Text(price)
                            .foregroundColor(ChatColors.secondaryText)
                    }
                }
                .padding(12)
                .background(ChatColors.assistantBubble)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                Spacer(minLength: 56)
            }
        case .status(let title, let subtitle, let status):
            AssistantBubble {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .foregroundColor(ChatColors.secondaryText)
                        .textSelection(.enabled)
                    Label(status, systemImage: "checkmark.circle.fill")
                        .foregroundColor(ChatColors.success)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(ChatColors.successBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(.top, 6)
                }
            }
        case .addCard(let text, let detail):
            AssistantBubble {
                VStack(alignment: .leading, spacing: 12) {
                    Text(text)
                        .foregroundColor(.white)
                    if let detail {
                        Text(detail)
                            .font(.caption.monospaced())
                            .foregroundColor(ChatColors.secondaryText)
                            .textSelection(.enabled)
                    }
                    Button(action: didTapAddCard) {
                        Text("Add card")
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
}

/// A dark, rounded container for the assistant's messages, leaving room on the trailing side like a chat bubble.
private struct AssistantBubble<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack {
            content
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(ChatColors.assistantBubble)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer(minLength: 56)
        }
    }
}

/// A non-functional message field that makes the demo look like a chat.
private struct ChatInputBar: View {
    let placeholder: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(ChatColors.inputField)
                .clipShape(Circle())
            HStack(spacing: 12) {
                Text(placeholder)
                    .foregroundColor(ChatColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "mic")
                    .foregroundColor(ChatColors.secondaryText)
                Image(systemName: "waveform")
                    .font(.body.weight(.semibold))
                    .foregroundColor(.black)
                    .frame(width: 36, height: 36)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding(.leading, 18)
            .padding(.trailing, 4)
            .frame(height: 44)
            .background(ChatColors.inputField)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .accessibilityHidden(true)
    }
}

// MARK: - Settings

private final class ExampleLinkAddCardSettings: ObservableObject {
    @Published var publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"
    @Published var merchantDisplayName = "Bufo Bot"
    @Published var email = ExampleLinkAddCardSettings.makeRandomEmail()
    @Published var phoneNumber = "+12015550123"
    @Published var fullName = "Jane Diaz"

    @Published var usesCustomColors = false
    @Published var primaryColor = Color.purple
    @Published var contentOnPrimaryColor = Color.white
    @Published var selectedBorderColor = Color.purple

    /// The appearance to pass to `LinkAgentWalletViewController`, or `nil` to use Link's defaults.
    var linkAppearance: LinkAppearance? {
        guard usesCustomColors else {
            return nil
        }
        return LinkAppearance(colors: .init(
            primary: UIColor(primaryColor),
            contentOnPrimary: UIColor(contentOnPrimaryColor),
            selectedBorder: UIColor(selectedBorderColor)
        ))
    }

    static func makeRandomEmail() -> String {
        "link-add-card-\(UUID().uuidString.prefix(8).lowercased())@example.com"
    }
}

private struct ExampleLinkAddCardSettingsView: View {
    @ObservedObject var settings: ExampleLinkAddCardSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Merchant") {
                    TextField("Publishable key", text: $settings.publishableKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    TextField("Merchant display name", text: $settings.merchantDisplayName)
                }

                Section {
                    HStack {
                        TextField("Email", text: $settings.email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        Button("Randomize") {
                            settings.email = ExampleLinkAddCardSettings.makeRandomEmail()
                        }
                    }
                    TextField("Phone number (E.164)", text: $settings.phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Full name", text: $settings.fullName)
                } header: {
                    Text("Customer")
                } footer: {
                    Text("Use a new email to sign up for Link and add a card. Use the email of an existing Link account to verify it and use its default card.")
                }

                Section {
                    Toggle("Custom colors", isOn: $settings.usesCustomColors)
                    if settings.usesCustomColors {
                        ColorPicker("Primary", selection: $settings.primaryColor, supportsOpacity: false)
                        ColorPicker("Content on primary", selection: $settings.contentOnPrimaryColor, supportsOpacity: false)
                        ColorPicker("Selected border", selection: $settings.selectedBorderColor, supportsOpacity: false)
                    }
                } header: {
                    Text("Colors")
                } footer: {
                    Text("Overrides Link's colors in LinkAgentWalletViewController. Turn off to use Link's default colors.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExampleLinkAddCardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ExampleLinkAddCardView()
        }
    }
}
