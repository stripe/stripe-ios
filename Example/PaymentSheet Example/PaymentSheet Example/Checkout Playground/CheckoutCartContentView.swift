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
