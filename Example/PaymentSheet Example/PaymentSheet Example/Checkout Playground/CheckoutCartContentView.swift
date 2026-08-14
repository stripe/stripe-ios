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
    var showsShippingAddressSection: Bool
    var errorMessage: String?

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
                if showsShippingAddressSection {
                    shippingAddressSection
                }
                orderSummarySection

                Spacer().frame(height: 160)
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

            let items = checkout.session.orderSummaryItems.flatMap { orderSummaryItem in
                switch orderSummaryItem {
                case .oneTimePrice(let oneTimePrice):
                    return oneTimePrice.items
                }
            }
            if items.isEmpty {
                Text("No items")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(items, id: \.key) { item in
                        HStack(alignment: .top, spacing: 16) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.displayName)
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text(item.unitAmount.amount)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text("Qty: \(item.quantity)")
                                    .font(.body).bold()
                            }
                            Spacer()
                        }
                        .padding()

                        if item.key != items.last?.key {
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
    private var shippingAddressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Shipping Address")
                .font(.title2).bold()
                .padding(.horizontal)

            if let override = checkout.session.shippingAddress {
                addressCard(
                    name: override.name,
                    address: override.address,
                    onEdit: presentShippingAddressElement
                )
            } else {
                emptyAddressCard(label: "Add shipping address", onAdd: presentShippingAddressElement)
            }
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

    @ViewBuilder
    private var currencySelectorSection: some View {
        if let currencySelectorElement = checkout.getCurrencySelectorElement() {
            currencySelectorElement.view
                .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var orderSummarySection: some View {
        let totals = checkout.session.totals
        VStack(alignment: .leading, spacing: 16) {
            Text("Order Summary")
                .font(.title2).bold()
                .padding(.horizontal)

            VStack(spacing: 12) {
                HStack {
                    Text("Subtotal")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(totals.subtotal.amount)
                        .foregroundColor(.primary)
                }
                if totals.discount.minorUnitsAmount > 0 {
                    HStack {
                        Text("Discount")
                            .foregroundColor(.green)
                        Spacer()
                        Text("-" + totals.discount.amount)
                            .foregroundColor(.green)
                    }
                }

                if totals.taxExclusive.minorUnitsAmount > 0 {
                    HStack {
                        Text("Tax")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(totals.taxExclusive.amount)
                            .foregroundColor(.primary)
                    }
                }

                Divider()
                    .padding(.vertical, 4)

                HStack {
                    Text("Total")
                        .font(.title3).bold()
                    Spacer()
                    Text(totals.total.amount)
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

    private func presentShippingAddressElement() {
        Task {
            await checkout.getShippingAddressElement().present()
        }
    }

}

struct CheckoutCartSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var checkout: Checkout

    var body: some View {
        NavigationView {
            ZStack {
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()

                CheckoutCartContentView(
                    checkout: checkout,
                    showsShippingAddressSection: true,
                    errorMessage: nil
                )
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
