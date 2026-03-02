//
//  CheckoutCartView.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 3/2/26.
//

import SwiftUI
@_spi(STP) import StripePayments
@_spi(CheckoutSessionsPreview) @_spi(CheckoutSessionPreview) import StripePaymentSheet

@available(iOS 15.0, *)
struct CheckoutCartView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var checkout: Checkout

    @State private var isLoading = false
    @State private var promoCodeInput = ""
    @State private var errorMessage: String?

    @State private var paymentResult: PaymentSheetResult?
    @State private var isShowingPaymentSheet = false

    init(clientSecret: String) {
        _checkout = StateObject(wrappedValue: Checkout(clientSecret: clientSecret))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                if let session = checkout.session {
                    cartContent(session: session)
                } else if isLoading {
                    ProgressView("Loading Cart...")
                } else {
                    VStack {
                        Text("Failed to load cart.")
                        Button("Retry") {
                            Task { await loadCheckout() }
                        }
                        .padding()
                    }
                }

                if isLoading && checkout.session != nil {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                    ProgressView()
                }
            }
            .navigationTitle("Your Cart")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .task {
                await loadCheckout()
            }
        }
    }

    private func loadCheckout() async {
        isLoading = true
        errorMessage = nil
        do {
            try await checkout.load()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @ViewBuilder
    private func cartContent(session: STPCheckoutSession) -> some View {
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
                                    // Placeholder image for Airbnb vibe
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
                                        Text(formatCurrency(amount: item.amount, currency: item.currency))
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
                                    Text(formatCurrency(amount: item.amount * item.quantity, currency: item.currency))
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

                // Shipping Options
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
                                            Text(formatCurrency(amount: option.amount, currency: option.currency))
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

                // Promotion Code
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

                // Totals Breakdown
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
                                Text(formatCurrency(amount: summary.subtotal, currency: session.currency))
                                    .foregroundColor(.primary)
                            }
                            let discount = session.totalDiscountAmount
                            if discount > 0 {
                                HStack {
                                    Text("Discount")
                                        .foregroundColor(.green)
                                    Spacer()
                                    Text("-" + formatCurrency(amount: discount, currency: session.currency))
                                        .foregroundColor(.green)
                                }
                            }
                            
                            let shipping = session.totalShippingAmount
                            if shipping > 0 {
                                HStack {
                                    Text("Shipping")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(formatCurrency(amount: shipping, currency: session.currency))
                                        .foregroundColor(.primary)
                                }
                            }
                            Divider()
                                .padding(.vertical, 4)
                            HStack {
                                Text("Total")
                                    .font(.title3).bold()
                                Spacer()
                                Text(formatCurrency(amount: summary.total, currency: session.currency))
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
                
                Spacer().frame(height: 100)
            }
            .padding(.top, 20)
        }
        .overlay(
            VStack {
                Spacer()
                if let summary = session.totalSummary {
                    VStack {
                        if let result = paymentResult {
                            switch result {
                            case .completed:
                                VStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.green)
                                    Text("Payment Successful!")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(
                                    Color(UIColor.systemBackground)
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                                )
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        dismiss()
                                    }
                                }
                            case .canceled:
                                Color.clear
                                    .onAppear { paymentResult = nil }
                            case .failed(let error):
                                VStack(spacing: 8) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 36))
                                        .foregroundColor(.red)
                                    Text(error.localizedDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    Color(UIColor.systemBackground)
                                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                                )
                            }
                        } else {
                            PaymentSheet.PaymentButton(
                                paymentSheet: makePaymentSheet(for: session),
                                onCompletion: { result in
                                    paymentResult = result
                                }
                            ) {
                                HStack {
                                    Text("Checkout")
                                    Spacer()
                                    Text(formatCurrency(amount: summary.total, currency: session.currency))
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(14)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 16)
                            .padding(.top, 16)
                            .background(
                                Color(UIColor.systemBackground)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
                            )
                        }
                    }
                }
            },
            alignment: .bottom
        )
    }

    // MARK: - Actions

    private func updateQuantity(for lineItemId: String, to quantity: Int) {
        Task {
            isLoading = true
            errorMessage = nil
            do {
                try await checkout.updateQuantity(.init(lineItemId: lineItemId, quantity: quantity))
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
                promoCodeInput = "" // Clear on success
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

    private func makePaymentSheet(for session: STPCheckoutSession) -> PaymentSheet {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "payments-example://stripe-redirect"
        configuration.billingDetailsCollectionConfiguration.email = .always
        configuration.defaultBillingDetails.email = "jenny@example.com"
        return PaymentSheet(checkoutSession: session, configuration: configuration)
    }

    // MARK: - Formatters

    private func formatCurrency(amount: Int, currency: String?) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency?.uppercased() ?? "USD"
        
        let decimalAmount = Decimal(amount) / 100.0
        return formatter.string(from: NSDecimalNumber(decimal: decimalAmount)) ?? "$\(decimalAmount)"
    }
}
