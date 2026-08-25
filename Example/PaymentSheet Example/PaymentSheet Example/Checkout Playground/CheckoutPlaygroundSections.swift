//
//  CheckoutPlaygroundSections.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutPlaygroundConfigurationSection: View {
    @Binding var uiFramework: CheckoutPlayground.UIFramework
    @Binding var integrationType: CheckoutPlayground.IntegrationType
    @Binding var currency: CheckoutPlayground.Currency
    @Binding var customerType: CheckoutPlayground.CustomerType
    @Binding var checkoutEndpointOption: CheckoutPlayground.EndpointOption
    @Binding var checkoutEndpoint: String
    @Binding var delayPaymentPagesRequests: Bool
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                CheckoutPlayground.SectionHeader(title: "Configuration", icon: "gearshape.fill")
                Spacer()
                Button("Reset", action: onReset)
                    .font(.callout.smallCaps())
                    .buttonStyle(.bordered)
            }
            VStack(spacing: 1) {
                CheckoutPlayground.PickerRow(
                    title: "UI Framework",
                    icon: "rectangle.3.group.fill",
                    selection: $uiFramework,
                    displayText: { $0.displayName }
                )
                CheckoutPlayground.PickerRow(
                    title: "PaymentElement",
                    icon: "square.stack.3d.up.fill",
                    selection: $integrationType,
                    tooltip: "Choose the PaymentElement presentation.\n\n• sheet: Presents PaymentElement as a payment method selector.\n• view: Displays PaymentElement in the checkout flow.\n• none: Hides PaymentElement.",
                    displayText: { $0.displayName }
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
                CheckoutPlayground.PickerRow(
                    title: "Backend Endpoint",
                    icon: "network",
                    selection: Binding(
                        get: { checkoutEndpointOption },
                        set: { newValue in
                            checkoutEndpointOption = newValue
                            if let endpoint = newValue.endpoint {
                                checkoutEndpoint = endpoint
                            }
                        }
                    ),
                    displayText: { $0.displayName }
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
                        .onChange(of: checkoutEndpoint) { newValue in
                            checkoutEndpointOption = CheckoutPlayground.EndpointOption.from(endpoint: newValue)
                        }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                CheckoutPlayground.ToggleRow(
                    title: "Delay Payment Pages Requests",
                    isOn: $delayPaymentPagesRequests,
                    tooltip: "Adds a 1-second delay before Payment Pages API requests except the initial /init request so loading states are easier to inspect."
                )
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

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

struct CheckoutPlaygroundFeaturesSection: View {
    let customerType: CheckoutPlayground.CustomerType
    @Binding var shippingAddressCollection: Bool
    @Binding var defaultShippingAddressOption: CheckoutPlayground.DefaultShippingAddressOption
    @Binding var customDefaultShippingAddress: CheckoutPlayground.DefaultShippingAddress
    @Binding var billingAddressCollection: CheckoutPlayground.BillingAddressCollection
    @Binding var automaticTax: Bool
    @Binding var checkoutSessionPaymentMethodSave: Bool
    @Binding var checkoutSessionPaymentMethodRemove: Bool
    @Binding var automaticPaymentMethods: Bool

    private var shouldShowAutomaticTax: Bool {
        return customerType != .new
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CheckoutPlayground.SectionHeader(title: "Features", icon: "slider.horizontal.3")
            VStack(spacing: 1) {
                CheckoutPlayground.ToggleRow(
                    title: "Collect Shipping Address",
                    isOn: $shippingAddressCollection,
                    tooltip: "Sets `shipping_address_collection` to allow specific countries (US, CA, GB, AU). Necessary for physical goods."
                )
                CheckoutPlayground.PickerRow(
                    title: "Default Shipping Address",
                    selection: $defaultShippingAddressOption,
                    tooltip: "Sets `CheckoutController.Configuration.defaults.shippingDetails` before loading Checkout.",
                    displayText: { $0.displayName }
                )
                switch defaultShippingAddressOption {
                case .none:
                    EmptyView()
                case .usTestAddress:
                    CheckoutPlaygroundShippingAddressPreview(address: .usTestAddress)
                case .custom:
                    CheckoutPlaygroundShippingAddressEditor(address: $customDefaultShippingAddress)
                }
                CheckoutPlayground.PickerRow(
                    title: "Billing Address",
                    selection: $billingAddressCollection,
                    tooltip: "Sets `billing_address_collection` to `auto` or `required`.",
                    displayText: { $0.displayName }
                )
                CheckoutPlayground.ToggleRow(
                    title: "Automatic Payment Methods",
                    isOn: $automaticPaymentMethods,
                    tooltip: "Sends `automatic_payment_methods: true` instead of an explicit `payment_method_types` array. Stripe selects the best payment methods for the session."
                )
                if shouldShowAutomaticTax {
                    CheckoutPlayground.ToggleRow(
                        title: "Automatic Tax",
                        isOn: $automaticTax,
                        tooltip: "Sets `automatic_tax: { enabled: true }`. Enables Stripe Tax for automatic tax calculation based on shipping/billing address. Prices must use `tax_behavior: 'exclusive'` or `'inclusive'`."
                    )
                }
                CheckoutPlayground.ToggleRow(
                    title: "Payment Method Offer Save",
                    isOn: $checkoutSessionPaymentMethodSave,
                    tooltip: "Sets `saved_payment_method_options.payment_method_save` to `enabled`. When on, Checkout can offer to save the payment method for future use."
                )
                CheckoutPlayground.ToggleRow(
                    title: "Payment Method Remove",
                    isOn: $checkoutSessionPaymentMethodRemove,
                    tooltip: "Sets `saved_payment_method_options.payment_method_remove` to `enabled`. When on, Checkout can allow customers to remove saved payment methods."
                )
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct CheckoutPlaygroundExpressCheckoutElementSection: View {
    @Binding var expressCheckoutElementOption: CheckoutPlayground.ExpressCheckoutElementOption
    @Binding var expressCheckoutElementShippingAddressRequired: Bool
    @Binding var applePayDisplay: ExpressCheckoutElement.ApplePayConfiguration.Display
    @Binding var linkDisplay: ExpressCheckoutElement.LinkConfiguration.Display
    var onCustomizeBillingDetailsCollection: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CheckoutPlayground.SectionHeader(title: "ExpressCheckoutElement", icon: "bolt.fill")
            VStack(spacing: 1) {
                CheckoutPlayground.PickerRow(
                    title: "Show / Hide",
                    icon: "eye.fill",
                    selection: $expressCheckoutElementOption,
                    displayText: { $0.displayName }
                )
                if expressCheckoutElementOption == .show {
                    CheckoutPlayground.ToggleRow(
                        title: "Requires Shipping Address",
                        isOn: $expressCheckoutElementShippingAddressRequired,
                        tooltip: "Sets `ExpressCheckoutElement.Configuration.shippingAddressRequired`. When on, wallets like Apple Pay require the customer to provide a shipping address."
                    )
                    CheckoutPlayground.PickerRow(
                        title: "Apple Pay Display",
                        icon: "apple.logo",
                        selection: $applePayDisplay,
                        tooltip: "Sets `ExpressCheckoutElement.Configuration.applePayConfiguration.display`.",
                        displayText: { $0.rawValue.capitalized }
                    )
                    CheckoutPlayground.PickerRow(
                        title: "Link Display",
                        icon: "link",
                        selection: $linkDisplay,
                        tooltip: "Sets `ExpressCheckoutElement.Configuration.linkConfiguration.display`.",
                        displayText: { $0.rawValue.capitalized }
                    )

                    Button(action: onCustomizeBillingDetailsCollection) {
                        HStack {
                            Image(systemName: "person.text.rectangle.fill")
                                .font(.system(size: 16))
                                .frame(width: 24)
                                .foregroundColor(.blue)
                            Text("Billing Details Collection")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct CheckoutPlaygroundShippingAddressPreview: View {

    let address: CheckoutPlayground.DefaultShippingAddress

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 3) {
                Text(address.name)
                    .font(.subheadline.weight(.semibold))
                Text(address.line1)
                Text("\(address.city), \(address.state) \(address.postalCode)")
                Text(address.country)
            }
            .font(.subheadline)
            .foregroundColor(.secondary)

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

private struct CheckoutPlaygroundShippingAddressEditor: View {

    @Binding var address: CheckoutPlayground.DefaultShippingAddress

    var body: some View {
        VStack(spacing: 12) {
            CheckoutPlaygroundShippingAddressField(
                title: "Name",
                placeholder: "Jenny Rosen",
                text: $address.name
            )
            CheckoutPlaygroundShippingAddressField(
                title: "Address line 1",
                placeholder: "510 Townsend St",
                text: $address.line1
            )
            CheckoutPlaygroundShippingAddressField(
                title: "Address line 2",
                placeholder: "Apartment, suite, etc.",
                text: $address.line2
            )
            CheckoutPlaygroundShippingAddressField(
                title: "City",
                placeholder: "San Francisco",
                text: $address.city
            )
            CheckoutPlaygroundShippingAddressField(
                title: "State",
                placeholder: "CA",
                text: $address.state
            )
            CheckoutPlaygroundShippingAddressField(
                title: "ZIP / postal code",
                placeholder: "94103",
                text: $address.postalCode
            )
            CheckoutPlaygroundShippingAddressField(
                title: "Country",
                placeholder: "US",
                text: $address.country
            )
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

private struct CheckoutPlaygroundShippingAddressField: View {

    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: $text)
                .font(.body)
                .padding(.horizontal, 12)
                .frame(height: 40)
                .background(Color(uiColor: .tertiarySystemFill))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel(title)
        }
    }
}

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

struct CheckoutPlaygroundPaymentMethodSelectionSheet: View {
    @Binding var selectedMethods: Set<String>
    let availableMethods: [String]
    @Environment(\.dismiss) var dismiss
    @State private var customMethodType = ""

    private var customMethods: [String] {
        selectedMethods
            .subtracting(availableMethods)
            .sorted()
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
                            selectedMethods = selectedMethods.union([trimmed])
                            customMethodType = ""
                        }
                        .disabled(customMethodType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    ForEach(customMethods, id: \.self) { method in
                        HStack {
                            Text(method)
                            Spacer()
                            Button {
                                selectedMethods = selectedMethods.subtracting([method])
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Remove \(method)")
                        }
                    }
                }

                Section("Available") {
                    ForEach(availableMethods, id: \.self) { method in
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
