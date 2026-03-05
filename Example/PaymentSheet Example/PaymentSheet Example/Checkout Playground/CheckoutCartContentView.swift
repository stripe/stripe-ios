//
//  CheckoutCartContentView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

@_spi(STP) import StripePayments
@_spi(CheckoutSessionsPreview) @_spi(STP) import StripePaymentSheet
import SwiftUI

@available(iOS 15.0, *)
struct CheckoutCartContentView: View {
    @ObservedObject var checkout: Checkout
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    @State private var promoCodeInput = ""
    @State private var showShippingAddressSheet = false
    @State private var showBillingAddressSheet = false
    @State private var shippingAddressDetails: AddressElement.AddressDetails?
    @State private var billingAddressDetails: AddressElement.AddressDetails?

    @ViewBuilder
    var body: some View {
        if let session = checkout.session {
            ScrollView {
                VStack(spacing: 24) {
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8).cornerRadius(10))
                            .padding(.horizontal)
                    }

                    // Line Items
                    lineItemsSection(session: session)

                    // Shipping Options
                    shippingOptionsSection(session: session)

                    if session.requiresShippingAddress {
                        // Shipping Address
                        shippingAddressSection(session: session)
                    }

                    if session.requiresBillingAddress {
                        // Billing Address
                        billingAddressSection(session: session)
                    }

                    // Promotion Code
                    promotionCodeSection(session: session)

                    // Order Summary
                    orderSummarySection(session: session)

                    Spacer().frame(height: 100)
                }
                .padding(.top, 20)
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func lineItemsSection(session: STPCheckoutSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Items")
                .font(.title2).bold()
                .padding(.horizontal)

            let items = session.lineItems
            if items.isEmpty {
                Text("No items")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(items, id: \.id) { item in
                        HStack(alignment: .top, spacing: 16) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.name)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(formatCartCurrency(amount: item.amount, currency: item.currency))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                // Custom Stepper
                                HStack {
                                    Button(action: {
                                        if item.quantity > 0 {
                                            updateQuantity(for: item.id, to: item.quantity - 1)
                                        }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(item.quantity > 0 ? .primary : .gray.opacity(0.5))
                                            .font(.system(size: 24))
                                    }
                                    .buttonStyle(PlainButtonStyle())

                                    Text("\(item.quantity)")
                                        .font(.body).bold()
                                        .frame(minWidth: 24, alignment: .center)

                                    Button(action: {
                                        updateQuantity(for: item.id, to: item.quantity + 1)
                                    }) {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.primary)
                                            .font(.system(size: 24))
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            Spacer()
                            Text(formatCartCurrency(amount: item.amount * item.quantity, currency: item.currency))
                                .font(.headline)
                        }
                        .padding()

                        if item.id != items.last?.id {
                            Divider().padding(.leading, 112)
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
        }
    }

    @ViewBuilder
    private func shippingOptionsSection(session: STPCheckoutSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shipping Options")
                .font(.title2).bold()
                .padding(.horizontal)

            let options = session.shippingOptions
            if options.isEmpty {
                Text("No shipping options available")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                let selectedId = session.selectedShippingOptionId ?? ""
                VStack(spacing: 0) {
                    ForEach(options, id: \.id) { option in
                        Button(action: {
                            selectShippingOption(option.id)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(formatCartCurrency(amount: option.amount, currency: option.currency))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if option.id == selectedId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: 24))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundColor(.gray.opacity(0.5))
                                        .font(.system(size: 24))
                                }
                            }
                            .padding()
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())

                        if option.id != options.last?.id {
                            Divider().padding(.leading, 16)
                        }
                    }
                }
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
        }
    }

    @ViewBuilder
    private func shippingAddressSection(session: STPCheckoutSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shipping Address")
                .font(.title2).bold()
                .padding(.horizontal)

            if let override = session.shippingAddressOverride {
                addressCard(
                    name: override.name,
                    address: override.address,
                    onEdit: { showShippingAddressSheet = true }
                )
            } else {
                emptyAddressCard(label: "Add shipping address", onAdd: { showShippingAddressSheet = true })
            }
        }
        .sheet(isPresented: $showShippingAddressSheet) {
            handleShippingAddressDismiss()
        } content: {
            AddressElement(
                address: $shippingAddressDetails,
                configuration: makeShippingAddressConfiguration(session: session),
            )
        }
    }

    @ViewBuilder
    private func billingAddressSection(session: STPCheckoutSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Billing Address")
                .font(.title2).bold()
                .padding(.horizontal)

            if let override = session.billingAddressOverride {
                addressCard(
                    name: override.name,
                    address: override.address,
                    onEdit: { showBillingAddressSheet = true }
                )
            } else {
                emptyAddressCard(label: "Add billing address", onAdd: { showBillingAddressSheet = true })
            }
        }
        .sheet(isPresented: $showBillingAddressSheet) {
            handleBillingAddressDismiss()
        } content: {
            AddressElement(
                address: $billingAddressDetails,
                configuration: makeBillingAddressConfiguration(session: session)
            )
        }
    }

    // MARK: - Address Helpers

    @ViewBuilder
    private func addressCard(name: String?, address: Checkout.Address, onEdit: @escaping () -> Void) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 4) {
                if let name, !name.isEmpty {
                    Text(name)
                        .font(.headline)
                }
                if let line1 = address.line1, !line1.isEmpty {
                    Text(line1)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let line2 = address.line2, !line2.isEmpty {
                    Text(line2)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                let cityStateZip = [address.city, address.state, address.postalCode].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                if !cityStateZip.isEmpty {
                    Text(cityStateZip)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Text(address.country)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Edit", action: onEdit)
                .foregroundColor(.blue)
                .font(.subheadline)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private func emptyAddressCard(label: String, onAdd: @escaping () -> Void) -> some View {
        Button(action: onAdd) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 24))
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    // MARK: - Address Configuration

    private func makeShippingAddressConfiguration(session: STPCheckoutSession) -> AddressElement.Configuration {
        var config = AddressElement.Configuration()
        config.title = "Shipping Address"
        config.buttonTitle = "Save Address"
        config.allowedCountries = session.allowedShippingCountries ?? []
        if let override = session.shippingAddressOverride {
            config.defaultValues = .init(
                address: .init(
                    city: override.address.city,
                    country: override.address.country,
                    line1: override.address.line1 ?? "",
                    line2: override.address.line2,
                    postalCode: override.address.postalCode,
                    state: override.address.state
                ),
                name: override.name
            )
        }
        return config
    }

    private func makeBillingAddressConfiguration(session: STPCheckoutSession) -> AddressElement.Configuration {
        var config = AddressElement.Configuration()
        config.title = "Billing Address"
        config.buttonTitle = "Save Address"
        if let override = session.billingAddressOverride {
            config.defaultValues = .init(
                address: .init(
                    city: override.address.city,
                    country: override.address.country,
                    line1: override.address.line1 ?? "",
                    line2: override.address.line2,
                    postalCode: override.address.postalCode,
                    state: override.address.state
                ),
                name: override.name
            )
        }
        return config
    }

    @ViewBuilder
    private func promotionCodeSection(session: STPCheckoutSession) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Promotion Code")
                .font(.title2).bold()
                .padding(.horizontal)

            VStack {
                if let appliedCode = session.appliedPromotionCode {
                    HStack {
                        Image(systemName: "tag.fill")
                            .foregroundColor(.green)
                        Text(appliedCode)
                            .font(.headline)
                            .foregroundColor(.green)
                        Spacer()
                        Button("Remove") {
                            removePromotionCode()
                        }
                        .foregroundColor(.red)
                        .font(.subheadline)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "tag")
                                .foregroundColor(.secondary)
                            TextField("Enter code", text: $promoCodeInput)
                                .autocapitalization(.allCharacters)
                                .font(.body)
                            Spacer()
                            Button("Apply") {
                                applyPromotionCode(promoCodeInput)
                            }
                            .foregroundColor(.blue)
                            .font(.headline)
                            .disabled(promoCodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                Button(action: { applyPromotionCode("IOSVIP25") }) {
                                    Text("25% off")
                                        .font(.caption).bold()
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                                Button(action: { applyPromotionCode("IOSWELCOME10") }) {
                                    Text("10% off")
                                        .font(.caption).bold()
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func orderSummarySection(session: STPCheckoutSession) -> some View {
        if let summary = session.totalSummary {
            VStack(alignment: .leading, spacing: 16) {
                Text("Order Summary")
                    .font(.title2).bold()
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    HStack {
                        Text("Subtotal")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCartCurrency(amount: summary.subtotal, currency: session.currency))
                            .foregroundColor(.primary)
                    }
                    let discount = session.totalDiscountAmount
                    if discount > 0 {
                        HStack {
                            Text("Discount")
                                .foregroundColor(.green)
                            Spacer()
                            Text("-" + formatCartCurrency(amount: discount, currency: session.currency))
                                .foregroundColor(.green)
                        }
                    }

                    let shipping = session.totalShippingAmount
                    if shipping > 0 {
                        HStack {
                            Text("Shipping")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCartCurrency(amount: shipping, currency: session.currency))
                                .foregroundColor(.primary)
                        }
                    }

                    let tax = session.totalTaxAmount
                    if tax > 0 {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(session.taxAmounts.first?.taxRate?.displayName ?? "Tax")
                                    .foregroundColor(.secondary)
                                if let rateDesc = session.taxAmounts.first?.taxRate?.rateDescription, !rateDesc.isEmpty {
                                    Text(rateDesc)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Text(formatCartCurrency(amount: tax, currency: session.currency))
                                .foregroundColor(.primary)
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)
                    HStack {
                        Text("Total")
                            .font(.title3).bold()
                        Spacer()
                        Text(formatCartCurrency(amount: summary.total, currency: session.currency))
                            .font(.title3).bold()
                    }
                }
                .padding()
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .padding(.horizontal)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            }
        }
    }

    // MARK: - Actions

    private func updateQuantity(for lineItemId: String, to quantity: Int) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.updateQuantity(with: .init(lineItemId: lineItemId, quantity: quantity))
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func selectShippingOption(_ optionId: String) {
        guard !optionId.isEmpty else { return }
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.selectShippingOption(optionId)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func applyPromotionCode(_ code: String) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.applyPromotionCode(code)
                promoCodeInput = ""
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func convertToAddressUpdate(_ details: AddressElement.AddressDetails) -> Checkout.AddressUpdate {
        let line1 = details.address.line1.isEmpty ? nil : details.address.line1
        return Checkout.AddressUpdate(
            name: details.name,
            address: Checkout.Address(
                country: details.address.country,
                line1: line1,
                line2: details.address.line2,
                city: details.address.city,
                state: details.address.state,
                postalCode: details.address.postalCode
            )
        )
    }

    private func handleShippingAddressDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let details = shippingAddressDetails else { return }
            let update = convertToAddressUpdate(details)
            updateShippingAddress(update)
        }
    }

    private func handleBillingAddressDismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            guard let details = billingAddressDetails else { return }
            let update = convertToAddressUpdate(details)
            updateBillingAddress(update)
        }
    }

    private func updateShippingAddress(_ update: Checkout.AddressUpdate) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.updateShippingAddress(update)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func updateBillingAddress(_ update: Checkout.AddressUpdate) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.updateBillingAddress(update)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func removePromotionCode() {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.removePromotionCode()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
