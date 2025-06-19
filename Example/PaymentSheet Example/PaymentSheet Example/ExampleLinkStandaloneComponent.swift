//
//  ExampleLinkStandaloneComponent.swift
//  PaymentSheet Example
//
//  Created by Till Hellmund on 6/19/25.
//

@_spi(STP) import StripePaymentSheet
import SwiftUI

@available(iOS 14.0, *)
struct ExampleLinkStandaloneComponent: View {
    @State private var selectedPaymentMethod: PaymentMethod?
    @State private var tipAmount: Double = 2.0
    @State private var hasPresentedLink = false
    @State private var paymentOption: PaymentSheet.FlowController.PaymentOptionDisplayData?

    @StateObject private var linkController = LinkController.create()

    private var subtotal: Double = 15.50
    private var tax: Double = 1.55
    private var total: Double {
        subtotal + tax + tipAmount
    }

    private var hasValidSelection: Bool {
        selectedPaymentMethod != nil || paymentOption != nil
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ride Summary")
                                .font(.title)
                                .fontWeight(.bold)

                            Text("123 Main St → 456 Oak Ave")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }

                    // Trip details
                    VStack(spacing: 12) {
                        TripDetailRow(title: "Base fare", amount: "$12.50")
                        TripDetailRow(title: "Distance (2.3 mi)", amount: "$3.00")
                        Divider()
                        TripDetailRow(title: "Subtotal", amount: String(format: "$%.2f", subtotal))
                        TripDetailRow(title: "Tax", amount: String(format: "$%.2f", tax))
                    }
                }
                .padding()
                .background(Color(.systemBackground))

                // Tip section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tip your driver")
                        .font(.headline)
                        .padding(.horizontal)

                    HStack(spacing: 12) {
                        ForEach([0.0, 1.0, 2.0, 3.0, 5.0], id: \.self) { tip in
                            TipButton(
                                amount: tip,
                                isSelected: tipAmount == tip,
                                action: { tipAmount = tip }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(Color(.systemGray6))

                // Payment method section
                VStack(alignment: .leading, spacing: 0) {
                    Text("Payment Method")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.vertical, 16)
                        .background(Color(.systemBackground))

                    VStack(spacing: 0) {
                        // Only show Card option if no Link payment option is selected
                        if paymentOption == nil {
                            PaymentMethodListRow(
                                method: .card,
                                isSelected: selectedPaymentMethod == .card,
                                action: { selectedPaymentMethod = .card }
                            )

                            Divider()
                                .padding(.leading, 56)
                        }

                        // Show Link option if a payment option is selected
                        if let paymentOption {
                            PaymentMethodListRow(
                                method: .link,
                                isSelected: true,
                                subtitle: paymentOption.labels.sublabel ?? paymentOption.label,
                                action: { presentLink() }
                            )
                        } else {
                            PaymentMethodListRow(
                                method: .link,
                                isSelected: selectedPaymentMethod == .link,
                                action: { presentLink() }
                            )
                        }
                    }
                    .background(Color(.systemBackground))
                }

                Spacer()

                // Total and Pay button
                VStack(spacing: 16) {
                    VStack(spacing: 8) {
                        HStack {
                            Text("Total")
                                .font(.headline)
                            Spacer()
                            Text(String(format: "$%.2f", total))
                                .font(.title)
                                .fontWeight(.bold)
                        }

                        Text("You'll be charged after your ride")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    Button(action: {
                        if linkController.paymentOption != nil {
                            // Link payment option is selected, proceed with payment
                            print("Processing Link payment...")
                        } else if selectedPaymentMethod == .link {
                            presentLink()
                        } else {
                            // Handle card payment
                            print("Processing card payment...")
                        }
                    }) {
                        HStack {
                            Text("Pay")
                                .font(.headline)
                                .fontWeight(.semibold)
                            Text(String(format: "$%.2f", total))
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(hasValidSelection ? Color.black : Color.gray)
                        .cornerRadius(25)
                    }
                    .disabled(!hasValidSelection)
                    .padding(.horizontal)
                    .padding(.bottom, 34) // Safe area
                }
                .background(Color(.systemBackground))
            }
        }
        .onAppear {
            if !hasPresentedLink {
                hasPresentedLink = true
                presentLink()
            }
        }
    }

    private func presentLink() {
        guard let viewController = findViewController() else {
            return
        }

        STPAPIClient.shared.publishableKey = "pk_test_51HvTI7Lu5o3P18Zp6t5AgBSkMvWoTtA0nyA7pVYDqpfLkRtWun7qZTYCOHCReprfLM464yaBeF72UFfB7cY9WG4a00ZnDtiC2C"

        linkController.present(from: viewController, with: "email@email.com") {
            self.paymentOption = linkController.paymentOption
        }
    }
}

// MARK: - Supporting Views

struct TripDetailRow: View {
    let title: String
    let amount: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(amount)
                .fontWeight(.medium)
        }
    }
}

struct TipButton: View {
    let amount: Double
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(amount == 0 ? "No tip" : String(format: "$%.0f", amount))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .black)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(isSelected ? Color.black : Color(.systemGray5))
                .cornerRadius(20)
        }
    }
}

struct PaymentMethodListRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let subtitle: String?
    let action: () -> Void

    init(method: PaymentMethod, isSelected: Bool, subtitle: String? = nil, action: @escaping () -> Void) {
        self.method = method
        self.isSelected = isSelected
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: method.iconName)
                    .foregroundColor(method.iconColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle ?? method.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PaymentMethodRow: View {
    let method: PaymentMethod
    let isSelected: Bool
    let subtitle: String?
    let action: () -> Void

    init(method: PaymentMethod, isSelected: Bool, subtitle: String? = nil, action: @escaping () -> Void) {
        self.method = method
        self.isSelected = isSelected
        self.subtitle = subtitle
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: method.iconName)
                    .foregroundColor(method.iconColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text(subtitle ?? method.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? Color(.systemBlue).opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Supporting Types

enum PaymentMethod: CaseIterable {
    case card
    case link

    var displayName: String {
        switch self {
        case .card:
            return "Card"
        case .link:
            return "Link"
        }
    }

    var description: String {
        switch self {
        case .card:
            return "Credit or debit card"
        case .link:
            return "Pay with Link"
        }
    }

    var iconName: String {
        switch self {
        case .card:
            return "creditcard"
        case .link:
            return "link"
        }
    }

    var iconColor: Color {
        switch self {
        case .card:
            return .blue
        case .link:
            let uiColor = UIColor(red: 0, green: 0.84, blue: 0.44, alpha: 1.0) // #00D670
            if #available(iOS 15.0, *) {
                return Color(uiColor: uiColor)
            } else {
                return .green
            }
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

struct ExampleLinkStandaloneComponent_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ExampleLinkStandaloneComponent()
        } else {
            // Fallback on earlier versions
        }
    }
}
