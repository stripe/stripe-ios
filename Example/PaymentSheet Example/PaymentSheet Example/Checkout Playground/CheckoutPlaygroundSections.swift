//
//  CheckoutPlaygroundSections.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

import SwiftUI

@available(iOS 15.0, *)
struct CheckoutPlaygroundConfigurationSection: View {
    @Binding var mode: CheckoutPlayground.SessionMode
    @Binding var currency: CheckoutPlayground.Currency
    @Binding var customerType: CheckoutPlayground.CustomerType
    @Binding var checkoutEndpoint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CheckoutPlayground.SectionHeader(title: "Configuration", icon: "gearshape.fill")
            VStack(spacing: 1) {
                CheckoutPlayground.PickerRow(
                    title: "Mode",
                    icon: "arrow.triangle.2.circlepath",
                    selection: $mode,
                    tooltip: "Determines the type of checkout session.\n\n• Payment: One-time payment.\n• Subscription: Recurring payment.\n• Setup: Save payment details for future use.",
                    displayText: { $0.rawValue.capitalized }
                )
                CheckoutPlayground.PickerRow(
                    title: "Currency",
                    icon: "banknote",
                    selection: $currency,
                    displayText: { $0.rawValue.uppercased() }
                )
                CheckoutPlayground.PickerRow(
                    title: "Customer",
                    icon: "person.fill",
                    selection: $customerType,
                    tooltip: "Simulates different customer states.\n\n• Guest: No customer object attached.\n• New: Creates a new Customer object.\n• Returning: Attaches a pre-existing Customer ID.",
                    displayText: { $0.rawValue.capitalized }
                )
                HStack(spacing: 8) {
                    Image(systemName: "network")
                        .font(.system(size: 16))
                        .frame(width: 24)
                        .foregroundColor(.blue)

                    TextField("Checkout Endpoint", text: $checkoutEndpoint)
                        .font(.subheadline)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

@available(iOS 15.0, *)
struct CheckoutPlaygroundLineItemsSection: View {
    let lineItems: [CheckoutPlayground.LineItemConfig]
    let currency: CheckoutPlayground.Currency

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CheckoutPlayground.SectionHeader(title: "Line Items", icon: "cart.fill")

            VStack(spacing: 12) {
                ForEach(lineItems) { item in
                    CheckoutPlaygroundLineItemCard(
                        item: item,
                        currency: currency
                    )
                }
            }
        }
    }
}

@available(iOS 15.0, *)
struct CheckoutPlaygroundLineItemCard: View {
    let item: CheckoutPlayground.LineItemConfig
    let currency: CheckoutPlayground.Currency

    private var formattedPrice: String {
        if currency.isZeroDecimal {
            return "\(currency.symbol)\(item.unitAmount)"
        }
        return String(format: "%@%.2f", currency.symbol, Double(item.unitAmount) / 100.0)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(uiColor: .systemGray5))
                    .frame(width: 48, height: 48)
                Image(systemName: "tag.fill")
                    .foregroundColor(.gray)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(size: 16, weight: .medium))

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("Qty")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(item.quantity)")
                            .font(.subheadline)
                    }

                    HStack(spacing: 4) {
                        Text("Price")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(formattedPrice)
                            .font(.subheadline)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

@available(iOS 15.0, *)
struct CheckoutPlaygroundFeaturesSection: View {
    let mode: CheckoutPlayground.SessionMode
    let customerType: CheckoutPlayground.CustomerType
    @Binding var enableShipping: Bool
    @Binding var shippingAddressCollection: Bool
    @Binding var billingAddressCollection: Bool
    @Binding var phoneNumberCollection: Bool
    @Binding var allowPromotionCodes: Bool
    @Binding var automaticTax: Bool

    private var supportsSetupRestrictedFeatures: Bool {
        return mode != .setup
    }

    private var shouldShowAutomaticTax: Bool {
        return supportsSetupRestrictedFeatures && customerType != .new
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CheckoutPlayground.SectionHeader(title: "Features", icon: "slider.horizontal.3")
            VStack(spacing: 1) {
                CheckoutPlayground.ToggleRow(
                    title: "Shipping Options",
                    isOn: $enableShipping,
                    tooltip: "Populates `shipping_options` with sample rates (e.g., $5.99 Standard). Requires `shipping_address_collection`."
                )
                CheckoutPlayground.ToggleRow(
                    title: "Collect Shipping Address",
                    isOn: $shippingAddressCollection,
                    tooltip: "Sets `shipping_address_collection` to allow specific countries (US, CA, GB, AU). Necessary for physical goods."
                )
                CheckoutPlayground.ToggleRow(
                    title: "Collect Billing Address",
                    isOn: $billingAddressCollection,
                    tooltip: "Sets `billing_address_collection: 'required'`. If off, defaults to 'auto' (only collected if the payment method needs it)."
                )
                if supportsSetupRestrictedFeatures {
                    CheckoutPlayground.ToggleRow(
                        title: "Collect Phone Number",
                        isOn: $phoneNumberCollection,
                        tooltip: "Sets `phone_number_collection: { enabled: true }`. Useful for SMS notifications or 3DS authentication fallback."
                    )
                    CheckoutPlayground.ToggleRow(
                        title: "Allow Promo Codes",
                        isOn: $allowPromotionCodes,
                        tooltip: "Sets `allow_promotion_codes: true`. Adds a coupon code input field to the checkout page."
                    )
                    if shouldShowAutomaticTax {
                        CheckoutPlayground.ToggleRow(
                            title: "Automatic Tax",
                            isOn: $automaticTax,
                            tooltip: "Sets `automatic_tax: { enabled: true }`. Enables Stripe Tax for automatic tax calculation based on shipping/billing address. Prices must use `tax_behavior: 'exclusive'` or `'inclusive'`."
                        )
                    }
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

@available(iOS 15.0, *)
struct CheckoutPlaygroundPaymentMethodSection: View {
    @Binding var selectedMethods: Set<String>
    let availableMethods: [String]
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CheckoutPlayground.SectionHeader(title: "Payment Methods", icon: "creditcard.fill")
                Spacer()
                Button(action: { isPresented = true }) {
                    Text("Edit")
                        .font(.subheadline.weight(.medium))
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                if selectedMethods.isEmpty {
                    Text("No payment methods selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(selectedMethods).sorted(), id: \.self) { method in
                                HStack(spacing: 6) {
                                    Image(systemName: icon(for: method))
                                        .font(.caption)
                                    Text(method.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.subheadline.weight(.medium))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(uiColor: .systemFill))
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                            }
                        }
                        .padding(16)
                    }
                }

            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .sheet(isPresented: $isPresented) {
            CheckoutPlaygroundPaymentMethodSelectionSheet(
                selectedMethods: $selectedMethods,
                availableMethods: availableMethods
            )
        }
    }

    private func icon(for method: String) -> String {
        switch method {
        case "card":
            return "creditcard.fill"
        case "us_bank_account":
            return "building.columns.fill"
        case "cashapp":
            return "dollarsign.circle.fill"
        case "affirm":
            return "a.circle.fill"
        case "klarna":
            return "k.circle.fill"
        default:
            return "banknote.fill"
        }
    }
}

@available(iOS 15.0, *)
struct CheckoutPlaygroundPaymentMethodSelectionSheet: View {
    @Binding var selectedMethods: Set<String>
    let availableMethods: [String]
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var customMethodType = ""

    var filteredMethods: [String] {
        if searchText.isEmpty {
            return availableMethods
        }
        return availableMethods.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationView {
            List {
                Section("Custom") {
                    HStack(spacing: 8) {
                        TextField("Custom payment method type", text: $customMethodType)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button("Add") {
                            let trimmed = customMethodType.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else {
                                return
                            }
                            selectedMethods.insert(trimmed)
                            customMethodType = ""
                        }
                        .disabled(customMethodType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                Section("Available") {
                    ForEach(filteredMethods, id: \.self) { method in
                        Button {
                            withAnimation {
                                if selectedMethods.contains(method) {
                                    selectedMethods.remove(method)
                                } else {
                                    selectedMethods.insert(method)
                                }
                            }
                        } label: {
                            HStack {
                                Text(method.replacingOccurrences(of: "_", with: " ").capitalized)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedMethods.contains(method) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                        .font(.body.weight(.semibold))
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle("Select Payment Methods")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
