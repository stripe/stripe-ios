//
//  Checkout+Session+DebugDescription.swift
//  StripePaymentSheet
//

import Foundation

extension Checkout.Session: CustomDebugStringConvertible {
    /// A human-readable description of the Checkout Session for debugging.
    ///
    /// Customer information and other potentially sensitive values are masked or redacted.
    public var debugDescription: String {
        var lines = [
            "Checkout.Session {",
            "  id: \(String(reflecting: id))",
            "  status: \(status.debugDescription)",
            "  livemode: \(livemode)",
            "  businessName: \(businessName.debugValue)",
            "  currency: \(currency.debugValue)",
        ]

        lines.append(contentsOf: presentmentDetailsDebugDescriptionLines)
        lines.append(contentsOf: discountAmountsDebugDescriptionLines)
        lines.append(contentsOf: [
            "  email: \(email.maskedEmailDebugValue)",
            "  minorUnitsAmountDivisor: \(minorUnitsAmountDivisor.debugValue)",
        ])
        lines.append(contentsOf: paymentOptionDebugDescriptionLines)
        if let shippingAddress {
            lines.append(contentsOf: addressDebugDescriptionLines(
                name: "shippingAddress",
                country: shippingAddress.address.country,
                indentation: 1
            ))
        } else {
            lines.append("  shippingAddress: nil")
        }
        lines.append(contentsOf: orderSummaryDebugDescriptionLines)
        lines.append(contentsOf: [
            "  taxStatus: \(tax?.status.debugDescription ?? "nil")",
            "  taxAmountCount: \(taxAmounts.map { String($0.count) } ?? "nil")",
            "  totals: {",
            "    subtotal: \(totals.subtotal.debugValue)",
            "    taxExclusive: \(totals.taxExclusive.debugValue)",
            "    taxInclusive: \(totals.taxInclusive.debugValue)",
            "    discount: \(totals.discount.debugValue)",
            "    total: \(totals.total.debugValue)",
            "  }",
            "}",
        ])
        return lines.joined(separator: "\n")
    }

    private var presentmentDetailsDebugDescriptionLines: [String] {
        guard let presentmentDetails else {
            return ["  presentmentDetails: nil"]
        }
        return [
            "  presentmentDetails: {",
            "    presentmentCurrency: \(String(reflecting: presentmentDetails.presentmentCurrency))",
            "  }",
        ]
    }

    private var discountAmountsDebugDescriptionLines: [String] {
        guard !discountAmounts.isEmpty else {
            return ["  discountAmounts: []"]
        }

        var lines = ["  discountAmounts: ["]
        for discount in discountAmounts {
            lines.append(contentsOf: [
                "    {",
                "      amount: \(String(reflecting: discount.amount))",
                "      minorUnitsAmount: \(discount.minorUnitsAmount)",
                "      displayName: \(String(reflecting: discount.displayName))",
                "      promotionCode: \(discount.promotionCode == nil ? "nil" : "<redacted>")",
                "      percentOff: \(discount.percentOff.debugValue)",
                "    }",
            ])
        }
        lines.append("  ]")
        return lines
    }

    private var paymentOptionDebugDescriptionLines: [String] {
        guard let paymentOption else {
            return ["  paymentOption: nil"]
        }

        var lines = [
            "  paymentOption: {",
            "    paymentMethodType: \(String(reflecting: paymentOption.paymentMethodType))",
            "    label: \(String(reflecting: paymentOption.label))",
        ]
        if let billingDetails = paymentOption.billingDetails {
            lines.append(contentsOf: addressDebugDescriptionLines(
                name: "billingDetails",
                country: billingDetails.address.country,
                indentation: 2
            ))
        } else {
            lines.append("    billingDetails: nil")
        }
        lines.append(contentsOf: [
            "    mandateText: \(paymentOption.mandateText == nil ? "nil" : "<redacted>")",
            "  }",
        ])
        return lines
    }

    private func addressDebugDescriptionLines(
        name: String,
        country: String?,
        indentation: Int
    ) -> [String] {
        let indent = String(repeating: "  ", count: indentation)
        return [
            "\(indent)\(name): {",
            "\(indent)  country: \(country.debugValue)",
            "\(indent)}",
        ]
    }

    private var orderSummaryDebugDescriptionLines: [String] {
        guard !orderSummaryItems.isEmpty else {
            return ["  orderSummaryItems: []"]
        }

        var lines = ["  orderSummaryItems: ["]
        for (groupIndex, orderSummaryItem) in orderSummaryItems.enumerated() {
            switch orderSummaryItem {
            case .oneTimePrice(let group):
                lines.append(contentsOf: [
                    "    [\(groupIndex)] oneTimePrice {",
                    "      key: \(String(reflecting: group.key))",
                    "      items: [",
                ])

                for (itemIndex, item) in group.items.enumerated() {
                    lines.append(contentsOf: [
                        "        [\(itemIndex)] {",
                        "          key: \(String(reflecting: item.key))",
                        "          quantity: \(item.quantity)",
                        "          unitAmount: \(item.unitAmount.debugValue)",
                        "          unitAmountDecimal: \(item.unitAmountDecimal?.debugValue ?? "nil")",
                        "          adjustableQuantity: \(item.adjustableQuantity.debugValue)",
                        "        }",
                    ])
                }

                lines.append(contentsOf: [
                    "      ]",
                    "      subtotal: \(group.amountDetails.subtotal.debugValue)",
                    "      discount: \(group.amountDetails.discount.debugValue)",
                    "      taxExclusive: \(group.amountDetails.taxExclusive.debugValue)",
                    "      taxInclusive: \(group.amountDetails.taxInclusive.debugValue)",
                    "      taxAmountCount: \(group.amountDetails.taxAmounts.map { String($0.count) } ?? "nil")",
                    "      total: \(group.amountDetails.total.debugValue)",
                    "    }",
                ])
            }
        }
        lines.append("  ]")
        return lines
    }
}

private extension Optional where Wrapped == String {
    var debugValue: String {
        map { String(reflecting: $0) } ?? "nil"
    }

    /// Example: `franz@<domain>` becomes `"f***z@<domain>"`.
    var maskedEmailDebugValue: String {
        guard let email = self else { return "nil" }
        guard
            let atSign = email.firstIndex(of: "@"),
            let first = email.first,
            let last = email[..<atSign].last
        else {
            return "<redacted>"
        }
        return String(reflecting: "\(first)***\(last)\(email[atSign...])")
    }
}

private extension Optional where Wrapped == Int {
    /// Example: `100`; `nil` remains `nil`.
    var debugValue: String {
        map(String.init) ?? "nil"
    }
}

private extension Optional where Wrapped == Double {
    /// Example: `25.5`; `nil` remains `nil`.
    var debugValue: String {
        map { String($0) } ?? "nil"
    }
}

private extension Optional where Wrapped == Checkout.Session.AdjustableQuantity {
    /// Example: `1...99 (enabled: true)`; `nil` remains `nil`.
    var debugValue: String {
        guard let value = self else {
            return "nil"
        }
        return "\(value.minimum)...\(value.maximum) (enabled: \(value.enabled))"
    }
}

private extension Checkout.Session.Amount {
    var debugValue: String {
        String(reflecting: amount)
    }
}

extension Checkout.Session.Status: CustomDebugStringConvertible {
    /// Examples: `.open`, `.expired`, or `.complete(.paid)`.
    public var debugDescription: String {
        switch self {
        case .open:
            return ".open"
        case .expired:
            return ".expired"
        case .complete(let paymentStatus):
            return ".complete(\(paymentStatus.debugDescription))"
        }
    }
}

extension Checkout.Session.Status.PaymentStatus: CustomDebugStringConvertible {
    /// Examples: `.paid`, `.unpaid`, or `.noPaymentRequired`.
    public var debugDescription: String {
        switch self {
        case .paid:
            return ".paid"
        case .unpaid:
            return ".unpaid"
        case .noPaymentRequired:
            return ".noPaymentRequired"
        }
    }
}

extension Checkout.Session.Tax.Status: CustomDebugStringConvertible {
    /// Examples: `.ready`, `.requiresShippingAddress`, or `.requiresBillingAddress`.
    public var debugDescription: String {
        switch self {
        case .ready:
            return ".ready"
        case .requiresShippingAddress:
            return ".requiresShippingAddress"
        case .requiresBillingAddress:
            return ".requiresBillingAddress"
        }
    }
}
