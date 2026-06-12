//
//  CheckoutCartContentView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/3/26.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentSheet
import SwiftUI

struct CheckoutCartContentView: View {
    @ObservedObject var checkout: Checkout
    var currencySelectorAppearance = Checkout.CurrencySelectorView.Appearance()
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    @State private var promoCodeInput = ""
    @State private var showShippingAddressSheet = false
    @State private var showBillingAddressSheet = false
    @State private var lastSelectedShippingOptionId: String?
    @State private var shippingAddressDetails: AddressElement.AddressDetails?
    @State private var billingAddressDetails: AddressElement.AddressDetails?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red.opacity(0.8).cornerRadius(10))
                        .padding(.horizontal)
                }

                currencySelectorSection
                lineItemsSection
                shippingOptionsSection
                shippingAddressSection
                billingAddressSection
                promotionCodeSection
                orderSummarySection

                Spacer().frame(height: 100)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var lineItemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Items")
                .font(.title2).bold()
                .padding(.horizontal)

            let items = checkout.state.session.lineItems
            if items.isEmpty {
                Text("No items")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(items) { item in
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
                                Text(item.unitAmount?.amount ?? "")
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
                            Text(formatCartCurrency(
                                amount: (item.unitAmount?.minorUnitsAmount ?? 0) * item.quantity,
                                currency: checkout.state.session.currency
                            ))
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
    private var shippingOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shipping Options")
                .font(.title2).bold()
                .padding(.horizontal)

            let options = checkout.state.session.shippingOptions
            if options.isEmpty {
                Text("No shipping options available")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                let selectedId = selectedShippingOptionId ?? ""
                VStack(spacing: 0) {
                    ForEach(options) { option in
                        Button(action: {
                            selectShippingOption(option.id)
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(option.displayName ?? "Shipping")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text(option.amount.amount)
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
    private var shippingAddressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shipping Address")
                .font(.title2).bold()
                .padding(.horizontal)

            if let override = checkout.state.session.shippingAddress {
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
            AddressElement(
                address: shippingAddressBinding,
                configuration: makeAddressConfiguration(
                    title: "Shipping Address",
                    override: checkout.state.session.shippingAddress
                )
            )
        }
    }

    @ViewBuilder
    private var billingAddressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Billing Address")
                .font(.title2).bold()
                .padding(.horizontal)

            if let override = checkout.state.session.billingAddress {
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
            AddressElement(
                address: billingAddressBinding,
                configuration: makeAddressConfiguration(
                    title: "Billing Address",
                    override: checkout.state.session.billingAddress
                )
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
                if !address.country.isEmpty {
                    Text(address.country)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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

    private func makeAddressConfiguration(
        title: String,
        override: Checkout.ContactAddress?
    ) -> AddressElement.Configuration {
        var config = AddressElement.Configuration()
        config.title = title
        config.buttonTitle = "Save Address"
        if let override {
            config.defaultValues = .init(
                address: .init(
                    city: override.address.city,
                    country: override.address.country,
                    line1: override.address.line1 ?? "",
                    line2: override.address.line2,
                    postalCode: override.address.postalCode,
                    state: override.address.state
                ),
                name: override.name,
                phone: override.phone
            )
        }
        return config
    }

    @ViewBuilder
    private var promotionCodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Promotion Code")
                .font(.title2).bold()
                .padding(.horizontal)

            VStack {
                if let appliedCode = appliedPromotionCode {
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
    private var currencySelectorSection: some View {
        Checkout.CurrencySelectorElement(checkout: checkout, appearance: currencySelectorAppearance)
            .padding(.horizontal)
    }

    @ViewBuilder
    private var orderSummarySection: some View {
        if let total = checkout.state.session.total {
            let currency = checkout.state.session.currency
            let taxAmount = total.taxExclusive.minorUnitsAmount + total.taxInclusive.minorUnitsAmount
            VStack(alignment: .leading, spacing: 16) {
                Text("Order Summary")
                    .font(.title2).bold()
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    HStack {
                        Text("Subtotal")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatCartCurrency(amount: total.subtotal.minorUnitsAmount, currency: currency))
                            .foregroundColor(.primary)
                    }
                    if total.discount.minorUnitsAmount > 0 {
                        HStack {
                            Text("Discount")
                                .foregroundColor(.green)
                            Spacer()
                            Text("-" + formatCartCurrency(amount: total.discount.minorUnitsAmount, currency: currency))
                                .foregroundColor(.green)
                        }
                    }

                    if total.shippingRate.minorUnitsAmount > 0 {
                        HStack {
                            Text("Shipping")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCartCurrency(amount: total.shippingRate.minorUnitsAmount, currency: currency))
                                .foregroundColor(.primary)
                        }
                    }

                    if taxAmount > 0 {
                        HStack {
                            Text("Tax")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatCartCurrency(amount: taxAmount, currency: currency))
                                .foregroundColor(.primary)
                        }
                    }

                    Divider()
                        .padding(.vertical, 4)

                    HStack {
                        Text("Total")
                            .font(.title3).bold()
                        Spacer()
                        Text(formatCartCurrency(amount: total.total.minorUnitsAmount, currency: currency))
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

    private var selectedShippingOptionId: String? {
        let options = checkout.state.session.shippingOptions
        guard !options.isEmpty else {
            return nil
        }
        guard let shippingAmount = checkout.state.session.total?.shippingRate.minorUnitsAmount else {
            return lastSelectedShippingOptionId
        }
        let matchingOptions = options.filter { $0.amount.minorUnitsAmount == shippingAmount }
        if matchingOptions.count == 1 {
            return matchingOptions[0].id
        }
        return lastSelectedShippingOptionId
    }

    private var appliedPromotionCode: String? {
        checkout.state.session.discountAmounts.first(where: { $0.promotionCode != nil })?.promotionCode
    }

    // MARK: - Actions

    private func updateQuantity(for lineItemId: String, to quantity: Int) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.updateQuantity(lineItemId: lineItemId, quantity: quantity)
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
                lastSelectedShippingOptionId = optionId
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

    private func checkoutAddress(from details: AddressElement.AddressDetails.Address) -> Checkout.Address {
        let line1 = details.line1.isEmpty ? nil : details.line1
        return Checkout.Address(
            country: details.country,
            line1: line1,
            line2: details.line2,
            city: details.city,
            state: details.state,
            postalCode: details.postalCode
        )
    }

    private var shippingAddressBinding: Binding<AddressElement.AddressDetails?> {
        Binding(
            get: { shippingAddressDetails },
            set: { newValue in
                shippingAddressDetails = newValue
                guard let details = newValue else { return }
                updateShippingAddress(details)
            }
        )
    }

    private var billingAddressBinding: Binding<AddressElement.AddressDetails?> {
        Binding(
            get: { billingAddressDetails },
            set: { newValue in
                billingAddressDetails = newValue
                guard let details = newValue else { return }
                updateBillingAddress(details)
            }
        )
    }

    private func updateShippingAddress(_ details: AddressElement.AddressDetails) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.updateShippingAddress(
                    name: details.name,
                    phone: details.phone,
                    address: checkoutAddress(from: details.address)
                )
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func updateBillingAddress(_ details: AddressElement.AddressDetails) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.updateBillingAddress(
                    name: details.name,
                    phone: details.phone,
                    address: checkoutAddress(from: details.address)
                )
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

struct CheckoutCartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var checkout: Checkout
    var currencySelectorAppearance = Checkout.CurrencySelectorView.Appearance()
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                CheckoutCartContentView(
                    checkout: checkout,
                    currencySelectorAppearance: currencySelectorAppearance,
                    isLoading: $isLoading,
                    errorMessage: $errorMessage
                )

                if isLoading {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}
