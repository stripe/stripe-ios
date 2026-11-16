//
//  CheckoutPlaygroundSections.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/24/26.

@_spi(InternalOnlyAPI) import StripePaymentSheet
import SwiftUI

// Settings are grouped by where they take effect:
// 1. Checkout Session (Backend): parameters sent to the backend when creating the session.
// 2. Checkout Elements Controller: `CheckoutElementsController.Configuration`.
// 3. Elements: per-element configuration.
// 4. Playground: harness-only settings and developer overrides.

// MARK: - Checkout Session

struct CheckoutPlaygroundSessionSection: View {
    @ObservedObject var viewModel: CheckoutPlayground.ViewModel

    private var shouldShowAutomaticTax: Bool {
        viewModel.customerType != .new
    }

    private var cartScenarioTooltip: String {
        let scenarios = CheckoutPlayground.CartScenario.allCases.map { scenario in
            let items = scenario.lineItems.map { "\($0.quantity)× \($0.name)" }.joined(separator: ", ")
            return "• \(scenario.displayName): \(items)"
        }
        return "Sets the session's `line_items`.\n\n" + scenarios.joined(separator: "\n")
    }

    var body: some View {
        CheckoutPlayground.SettingsGroup(
            title: "Checkout Session (Backend)",
            icon: "server.rack"
        ) {
            CheckoutPlayground.Subsection {
                CheckoutPlayground.PickerRow(
                    title: "Currency",
                    icon: "banknote",
                    selection: $viewModel.currency,
                    displayText: { $0.rawValue.uppercased() }
                )
                CheckoutPlayground.PickerRow(
                    title: "Cart Scenario",
                    icon: "cart.fill",
                    selection: $viewModel.cartScenario,
                    tooltip: cartScenarioTooltip,
                    displayText: { $0.displayName }
                )
                CheckoutPlaygroundCustomerRows(viewModel: viewModel)
                CheckoutPlayground.ToggleRow(
                    title: "Automatic Payment Methods",
                    isOn: $viewModel.automaticPaymentMethods,
                    tooltip: "Sends `automatic_payment_methods: true` instead of an explicit `payment_method_types` array. Stripe selects the best payment methods for the session."
                )
                if !viewModel.automaticPaymentMethods {
                    CheckoutPlaygroundPaymentMethodTypesRow(
                        selectedMethods: $viewModel.paymentMethodTypes,
                        availableMethods: CheckoutPlayground.ViewModel.availablePaymentMethods
                    )
                }
                CheckoutPlayground.ToggleRow(
                    title: "Payment Method Offer Save",
                    isOn: $viewModel.checkoutSessionPaymentMethodSave,
                    tooltip: "Sets `saved_payment_method_options.payment_method_save` to `enabled`. When on, Checkout can offer to save the payment method for future use."
                )
                CheckoutPlayground.ToggleRow(
                    title: "Payment Method Remove",
                    isOn: $viewModel.checkoutSessionPaymentMethodRemove,
                    tooltip: "Sets `saved_payment_method_options.payment_method_remove` to `enabled`. When on, Checkout can allow customers to remove saved payment methods."
                )
                CheckoutPlayground.ToggleRow(
                    title: "Collect Shipping Address",
                    isOn: $viewModel.shippingAddressCollection,
                    tooltip: "Sets `shipping_address_collection` to allow specific countries (US, CA, GB, AU) and configures Shipping Address Element. Necessary for physical goods."
                )
                CheckoutPlayground.PickerRow(
                    title: "Billing Address",
                    selection: $viewModel.billingAddressCollection,
                    tooltip: "Sets `billing_address_collection` to `auto` or `required`.",
                    displayText: { $0.displayName }
                )
                if shouldShowAutomaticTax {
                    CheckoutPlayground.ToggleRow(
                        title: "Automatic Tax",
                        isOn: $viewModel.automaticTax,
                        tooltip: "Sets `automatic_tax: { enabled: true }`. Enables Stripe Tax for automatic tax calculation based on shipping/billing address. Prices must use `tax_behavior: 'exclusive'` or `'inclusive'`."
                    )
                }
            }
        }
    }
}

struct CheckoutPlaygroundCustomerRows: View {
    @ObservedObject var viewModel: CheckoutPlayground.ViewModel

    private var usesLocationEmail: Bool {
        viewModel.email.source.isServer && viewModel.adaptivePricingCountry != .none
    }

    private static let emailSourceTooltip = """
        Where the customer's email comes from.

        • None: No email is set.
        • Server — Session: Sends `customer_email` when creating the session. Requires a Guest customer.
        • Server — Customer: Sets `email` on the Customer. Requires a New or Returning customer.
        • Local: Sets `CheckoutElementsController.Configuration.defaults.email`. The customer can update or clear it in checkout. Leave blank to start without an email.

        Server emails cannot be changed in checkout. When Adaptive Pricing Location is set, the server email is replaced with test+location_XX@example.com and can't be edited.
        """

    var body: some View {
        CheckoutPlayground.PickerRow(
            title: "Customer",
            icon: "person.fill",
            selection: $viewModel.customerType,
            tooltip: "Simulates different customer states.\n\n• Guest: No customer object attached.\n• New: Creates a new Customer object.\n• Returning: Attaches a pre-existing Customer ID.",
            displayText: { $0.rawValue.capitalized }
        )
        CheckoutPlayground.PickerRow(
            title: "Email",
            icon: "envelope.fill",
            selection: $viewModel.email.source,
            tooltip: Self.emailSourceTooltip,
            displayText: { $0.displayName }
        )
        if viewModel.email.source != .none {
            HStack(spacing: 8) {
                TextField("Email address", text: Binding(
                    get: { viewModel.resolvedEmail.value },
                    set: { viewModel.email.value = $0 }
                ))
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .disabled(usesLocationEmail)
                .foregroundColor(usesLocationEmail ? .secondary : .primary)
                .accessibilityIdentifier("checkout_email_value")
                if usesLocationEmail {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 40)
            .background(Color(uiColor: .tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            // Align with the row titles: 16pt row inset + 24pt icon + 12pt spacing.
            .padding(.leading, 52)
            .padding(.trailing, 16)
            .padding(.bottom, 12)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        if let error = viewModel.emailConfigurationError {
            Text(error)
                .font(.caption)
                .foregroundColor(.red)
                .accessibilityIdentifier("checkout_email_configuration_error")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 52)
                .padding(.trailing, 16)
                .padding(.bottom, 12)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        CheckoutPlayground.AdaptivePricingLocationRow(
            selection: $viewModel.adaptivePricingCountry
        )
    }
}

// MARK: - Checkout Elements Controller

struct CheckoutPlaygroundClientSection: View {
    @ObservedObject var viewModel: CheckoutPlayground.ViewModel

    var body: some View {
        CheckoutPlayground.SettingsGroup(
            title: "Checkout Elements Controller",
            icon: "iphone"
        ) {
            CheckoutPlayground.Subsection(title: "Defaults") {
                CheckoutPlayground.PickerRow(
                    title: "Shipping Address",
                    selection: $viewModel.defaultShippingAddressOption,
                    tooltip: "Sets `CheckoutElementsController.Configuration.defaults.shippingDetails` before loading Checkout.",
                    displayText: { $0.displayName }
                )
                CheckoutPlaygroundDefaultAddressDetail(
                    option: viewModel.defaultShippingAddressOption,
                    customAddress: $viewModel.customDefaultShippingAddress
                )
                CheckoutPlayground.PickerRow(
                    title: "Billing Details",
                    selection: $viewModel.defaultBillingAddressOption,
                    tooltip: "Sets `CheckoutElementsController.Configuration.defaults.billingDetails` before loading Checkout. Email is configured under Checkout Session › Email; phone is configured below.",
                    displayText: { $0.displayName }
                )
                CheckoutPlaygroundDefaultAddressDetail(
                    option: viewModel.defaultBillingAddressOption,
                    customAddress: $viewModel.customDefaultBillingAddress
                )
                HStack(spacing: 12) {
                    Text("Phone")
                        .font(.body)
                    CheckoutPlayground.InfoButton(
                        title: "Phone",
                        message: "Sets `CheckoutElementsController.Configuration.defaults.phone` before loading Checkout. Leave blank for no default."
                    )
                    TextField("+15555555555", text: $viewModel.defaultPhone)
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 12)
                        .frame(height: 36)
                        .background(Color(uiColor: .tertiarySystemFill))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .accessibilityIdentifier("checkout_default_phone")
                }
                .padding(.vertical, 8)
                .frame(minHeight: CheckoutPlayground.rowMinHeight)
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
            }

            CheckoutPlayground.Subsection(title: "Wallets") {
                CheckoutPlayground.ToggleRow(
                    title: "Apple Pay",
                    isOn: $viewModel.applePayEnabled,
                    tooltip: "Sets `CheckoutElementsController.Configuration.applePayMerchantId`, shared by Payment Element and Express Checkout Element."
                )
            }
        }
    }
}

private struct CheckoutPlaygroundDefaultAddressDetail: View {
    let option: CheckoutPlayground.DefaultAddressOption
    @Binding var customAddress: CheckoutPlayground.DefaultAddress

    var body: some View {
        switch option {
        case .none:
            EmptyView()
        case .usTestAddress:
            CheckoutPlaygroundAddressPreview(address: .usTestAddress)
        case .custom:
            CheckoutPlaygroundAddressEditor(address: $customAddress)
        }
    }
}

// MARK: - Elements

struct CheckoutPlaygroundElementsSection: View {
    @ObservedObject var viewModel: CheckoutPlayground.ViewModel
    let onCustomizePaymentElementAppearance: () -> Void
    let onCustomizeCurrencySelectorAppearance: () -> Void

    var body: some View {
        CheckoutPlayground.SettingsGroup(
            title: "Elements",
            icon: "square.stack.3d.up.fill"
        ) {
            CheckoutPlayground.Subsection(title: "Payment Element") {
                CheckoutPlayground.ToggleRow(
                    title: "Show Payment Element",
                    isOn: $viewModel.showsPaymentElement
                )
                if viewModel.showsPaymentElement {
                    CheckoutPlayground.PickerRow(
                        title: "Presentation",
                        icon: "square.stack.3d.up.fill",
                        selection: $viewModel.paymentElementPresentation,
                        tooltip: "Choose the Payment Element presentation.\n\n• sheet: Presents Payment Element as a payment method selector.\n• view: Displays Payment Element in the checkout flow.",
                        displayText: { $0.rawValue }
                    )
                    CheckoutPlaygroundNavigationRow(
                        title: "Customize Appearance",
                        action: onCustomizePaymentElementAppearance
                    )
                }
                if viewModel.showsPaymentElement && viewModel.applePayEnabled {
                    CheckoutPlayground.PickerRow(
                        title: "Apple Pay Display",
                        icon: "apple.logo",
                        selection: $viewModel.paymentElementApplePayDisplay,
                        tooltip: "Sets `PaymentElement.Configuration.ApplePayConfiguration.display`. Set to `never` to hide Apple Pay in Payment Element while continuing to show it in Express Checkout Element.",
                        displayText: { $0.rawValue.capitalized }
                    )
                }
            }

            CheckoutPlayground.Subsection(title: "Express Checkout Element") {
                CheckoutPlaygroundExpressCheckoutElementRows(
                    showExpressCheckoutElement: $viewModel.expressCheckoutElement.isEnabled,
                    applePayButtonType: $viewModel.expressCheckoutElement.applePayButtonType,
                    linkDisplay: $viewModel.expressCheckoutElement.linkDisplay,
                    appearance: $viewModel.expressCheckoutElement.appearance
                )
            }

            CheckoutPlayground.Subsection(title: "Currency Selector") {
                CheckoutPlaygroundNavigationRow(
                    title: "Customize Appearance",
                    action: onCustomizeCurrencySelectorAppearance
                )
            }
        }
    }
}

private struct CheckoutPlaygroundNavigationRow: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16))
                    .frame(width: 24)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            .frame(minHeight: CheckoutPlayground.rowMinHeight)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CheckoutPlaygroundExpressCheckoutElementRows: View {
    @Binding var showExpressCheckoutElement: Bool
    @Binding var applePayButtonType: CheckoutPlayground.ApplePayButtonType
    @Binding var linkDisplay: ExpressCheckoutElement.Configuration.LinkConfiguration.Display
    @Binding var appearance: ExpressCheckoutElement.Configuration.Appearance

    var body: some View {
        CheckoutPlayground.ToggleRow(
            title: "Show Express Checkout Element",
            isOn: $showExpressCheckoutElement
        )
        if showExpressCheckoutElement {
            CheckoutPlayground.PickerRow(
                title: "Apple Pay Button Type",
                icon: "apple.logo",
                selection: $applePayButtonType,
                tooltip: "Sets `ExpressCheckoutElement.Configuration.applePayConfiguration.buttonType`. `nil` leaves it unset so the SDK chooses the button type.",
                displayText: { $0.displayName }
            )
            CheckoutPlayground.PickerRow(
                title: "Link Display",
                icon: "link",
                selection: $linkDisplay,
                tooltip: "Sets `ExpressCheckoutElement.Configuration.linkConfiguration.display`.",
                displayText: { $0.rawValue.capitalized }
            )
            CheckoutPlayground.PickerRow(
                title: "Button Theme",
                icon: "paintpalette.fill",
                selection: $appearance.buttonTheme,
                tooltip: "Sets `ExpressCheckoutElement.Configuration.Appearance.buttonTheme`. Only affects the Apple Pay button; the Link button always uses Link's brand color.",
                displayText: { $0.displayName }
            )
            Stepper(value: cornerRadius, in: -1...30) {
                HStack {
                    Text("Corner Radius")
                    Spacer()
                    Text(appearance.cornerRadius.map { String(format: "%.0f pt", $0) } ?? "Automatic")
                        .foregroundColor(.secondary)
                }
            }
            .accessibilityIdentifier("checkout_ece_corner_radius")
            .padding(.vertical, 8)
            .frame(minHeight: CheckoutPlayground.rowMinHeight)
            .padding(.horizontal, 16)
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            CheckoutPlayground.PickerRow(
                title: "Max Columns",
                icon: "square.grid.2x2",
                selection: maxColumns,
                tooltip: "Sets `ExpressCheckoutElement.Configuration.Appearance.buttonLayout.maxColumns`.",
                displayText: { $0.displayName }
            )
            CheckoutPlayground.PickerRow(
                title: "Max Rows",
                icon: "rectangle.grid.1x2",
                selection: maxRows,
                tooltip: "Sets `ExpressCheckoutElement.Configuration.Appearance.buttonLayout.maxRows`.",
                displayText: { $0.displayName }
            )
        }
    }

    private var cornerRadius: Binding<CGFloat> {
        Binding(
            get: { appearance.cornerRadius ?? -1 },
            set: { appearance.cornerRadius = $0 < 0 ? nil : $0 }
        )
    }

    private var maxColumns: Binding<CheckoutPlayground.ExpressCheckoutElementButtonLayoutLimit> {
        Binding(
            get: { .init(intValue: appearance.buttonLayout.maxColumns) },
            set: { appearance.buttonLayout.maxColumns = $0.intValue }
        )
    }

    private var maxRows: Binding<CheckoutPlayground.ExpressCheckoutElementButtonLayoutLimit> {
        Binding(
            get: { .init(intValue: appearance.buttonLayout.maxRows) },
            set: { appearance.buttonLayout.maxRows = $0.intValue }
        )
    }
}

// MARK: - Playground

struct CheckoutPlaygroundHarnessSection: View {
    @ObservedObject var viewModel: CheckoutPlayground.ViewModel

    var body: some View {
        CheckoutPlayground.SettingsGroup(
            title: "Playground",
            icon: "hammer.fill"
        ) {
            CheckoutPlayground.Subsection {
                CheckoutPlayground.PickerRow(
                    title: "UI Framework",
                    icon: "rectangle.3.group.fill",
                    selection: $viewModel.uiFramework,
                    displayText: { $0.displayName }
                )
                CheckoutPlayground.PickerRow(
                    title: "Backend Endpoint",
                    icon: "network",
                    selection: Binding(
                        get: { viewModel.checkoutEndpointOption },
                        set: { newValue in
                            viewModel.checkoutEndpointOption = newValue
                            if let endpoint = newValue.endpoint {
                                viewModel.checkoutEndpoint = endpoint
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

                    TextField("Backend URL", text: $viewModel.checkoutEndpoint)
                        .font(.subheadline)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .onChange(of: viewModel.checkoutEndpoint) { newValue in
                            viewModel.checkoutEndpointOption = CheckoutPlayground.EndpointOption.from(endpoint: newValue)
                        }
                }
                .padding(.vertical, 8)
                .frame(minHeight: CheckoutPlayground.rowMinHeight)
                .padding(.horizontal, 16)
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                CheckoutPlayground.PickerRow(
                    title: "Link Mode",
                    selection: $viewModel.linkMode,
                    tooltip: "Overrides the internal `PaymentSheet.LinkFeatureFlags.nativeLinkEnabledOverride` flag to force Link's native or web flow.",
                    displayText: { $0.displayName }
                )
                CheckoutPlayground.ToggleRow(
                    title: "Delay Client Requests",
                    isOn: $viewModel.delayCheckoutClientRequests,
                    tooltip: "Adds a 1-second delay before Checkout Client API requests except the initial /init request so loading states are easier to inspect."
                )
            }
        }
    }
}

// MARK: - Shared rows

private struct CheckoutPlaygroundAddressPreview: View {

    let address: CheckoutPlayground.DefaultAddress

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

private struct CheckoutPlaygroundAddressEditor: View {

    @Binding var address: CheckoutPlayground.DefaultAddress

    var body: some View {
        VStack(spacing: 12) {
            CheckoutPlaygroundAddressField(
                title: "Name",
                placeholder: "Jenny Rosen",
                text: $address.name
            )
            CheckoutPlaygroundAddressField(
                title: "Address line 1",
                placeholder: "510 Townsend St",
                text: $address.line1
            )
            CheckoutPlaygroundAddressField(
                title: "Address line 2",
                placeholder: "Apartment, suite, etc.",
                text: $address.line2
            )
            CheckoutPlaygroundAddressField(
                title: "City",
                placeholder: "San Francisco",
                text: $address.city
            )
            CheckoutPlaygroundAddressField(
                title: "State",
                placeholder: "CA",
                text: $address.state
            )
            CheckoutPlaygroundAddressField(
                title: "ZIP / postal code",
                placeholder: "94103",
                text: $address.postalCode
            )
            CheckoutPlaygroundAddressField(
                title: "Country",
                placeholder: "US",
                text: $address.country
            )
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
    }
}

private struct CheckoutPlaygroundAddressField: View {

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

struct CheckoutPlaygroundPaymentMethodTypesRow: View {
    @Binding var selectedMethods: Set<String>
    let availableMethods: [String]
    @State private var isPresented = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Payment Method Types")
                    .font(.body)
                Spacer()
                Button("Edit") { isPresented = true }
                    .font(.subheadline.weight(.medium))
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)

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
