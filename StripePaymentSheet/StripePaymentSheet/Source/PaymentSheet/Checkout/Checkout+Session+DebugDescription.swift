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
        var writer = CheckoutSessionDebugDescriptionWriter()
        writer.write(self)
        return writer.description
    }
}

private struct CheckoutSessionDebugDescriptionWriter {
    private(set) var lines: [String] = []
    private var indentation = 0

    var description: String {
        lines.joined(separator: "\n")
    }

    mutating func write(_ session: Checkout.Session) {
        block("Checkout.Session", isProperty: false) { writer in
            writer.property("id", string: session.id)
            writer.property("businessName", optionalString: session.businessName)
            writer.property("currency", optionalString: session.currency)
            writer.writeCurrencyOptions(session.currencyOptions)
            writer.writeDiscountAmounts(session.discountAmounts)
            writer.maskedEmailProperty("email", value: session.email)
            writer.writeOrderSummaryItems(session.orderSummaryItems)
            writer.property("livemode", value: String(session.livemode))
            writer.property("minorUnitsAmountDivisor", optionalValue: session.minorUnitsAmountDivisor)
            writer.writePaymentOption(session.paymentOption)
            writer.writeShippingAddress(session.shippingAddress)
            writer.property("status", value: session.status.debugCaseName)
            writer.writeTax(session.tax)
            writer.writeTaxAmounts("taxAmounts", session.taxAmounts)
            writer.writeTotals(session.totals)
        }
    }

    private mutating func writeCurrencyOptions(_ currencyOptions: [Checkout.CurrencyOption]) {
        array("currencyOptions", currencyOptions) { writer, currencyOption in
            writer.block { writer in
                writer.writeAmount("amount", currencyOption.amount)
                writer.property("currency", string: currencyOption.currency)
                if let conversion = currencyOption.currencyConversion {
                    writer.block("currencyConversion") { writer in
                        writer.property("fxRate", string: conversion.fxRate)
                        writer.property("sourceCurrency", string: conversion.sourceCurrency)
                    }
                } else {
                    writer.property("currencyConversion", value: "nil")
                }
            }
        }
    }

    private mutating func writeDiscountAmounts(_ discountAmounts: [Checkout.DiscountAmount]) {
        array("discountAmounts", discountAmounts) { writer, discountAmount in
            writer.block { writer in
                writer.writeAmount("amount", discountAmount.amount)
                writer.property("displayName", string: discountAmount.displayName)
                writer.redactedProperty("promotionCode", isPresent: discountAmount.promotionCode != nil)
            }
        }
    }

    private mutating func writeOrderSummaryItems(_ orderSummaryItems: [Checkout.Session.OrderSummaryItem]) {
        array("orderSummaryItems", orderSummaryItems) { writer, orderSummaryItem in
            switch orderSummaryItem {
            case .oneTimePrice(let oneTimePrice):
                writer.block(".oneTimePrice", isProperty: false) { writer in
                    writer.property("key", string: oneTimePrice.key)
                    writer.property("description", optionalString: oneTimePrice.description)
                    writer.array("items", oneTimePrice.items) { writer, item in
                        writer.block { writer in
                            writer.property("key", string: item.key)
                            writer.property("displayName", string: item.displayName)
                            writer.redactedCollectionProperty("images", count: item.images.count)
                            writer.writeAmount("unitAmount", item.unitAmount)
                            if let unitAmountDecimal = item.unitAmountDecimal {
                                writer.writeAmount("unitAmountDecimal", unitAmountDecimal)
                            } else {
                                writer.property("unitAmountDecimal", value: "nil")
                            }
                            writer.property("unitLabel", optionalString: item.unitLabel)
                            writer.property("quantity", value: String(item.quantity))
                            if let adjustableQuantity = item.adjustableQuantity {
                                writer.block("adjustableQuantity") { writer in
                                    writer.property("enabled", value: String(adjustableQuantity.enabled))
                                    writer.property("maximum", value: String(adjustableQuantity.maximum))
                                    writer.property("minimum", value: String(adjustableQuantity.minimum))
                                }
                            } else {
                                writer.property("adjustableQuantity", value: "nil")
                            }
                        }
                    }
                    writer.block("amountDetails") { writer in
                        writer.writeAmount("total", oneTimePrice.amountDetails.total)
                        writer.writeAmount("subtotal", oneTimePrice.amountDetails.subtotal)
                        writer.writeTaxAmounts("taxAmounts", oneTimePrice.amountDetails.taxAmounts)
                        writer.writeAmount("discount", oneTimePrice.amountDetails.discount)
                        writer.writeAmount("taxInclusive", oneTimePrice.amountDetails.taxInclusive)
                        writer.writeAmount("taxExclusive", oneTimePrice.amountDetails.taxExclusive)
                    }
                }
            }
        }
    }

    private mutating func writePaymentOption(_ paymentOption: Checkout.Session.PaymentOptionDisplayData?) {
        guard let paymentOption else {
            property("paymentOption", value: "nil")
            return
        }

        block("paymentOption") { writer in
            writer.property("paymentMethodType", string: paymentOption.paymentMethodType)
            writer.property("label", string: paymentOption.label)
            writer.writeBillingDetails(paymentOption.billingDetails)
            writer.redactedProperty("mandateText", isPresent: paymentOption.mandateText != nil)
        }
    }

    private mutating func writeBillingDetails(_ billingDetails: PaymentSheet.BillingDetails?) {
        guard let billingDetails else {
            property("billingDetails", value: "nil")
            return
        }

        block("billingDetails") { writer in
            writer.redactedProperty("name", isPresent: billingDetails.name != nil)
            writer.maskedEmailProperty("email", value: billingDetails.email)
            writer.redactedProperty("phone", isPresent: billingDetails.phone != nil)
            writer.block("address") { writer in
                writer.property("country", optionalString: billingDetails.address.country)
                writer.redactedProperty("line1", isPresent: billingDetails.address.line1 != nil)
                writer.redactedProperty("line2", isPresent: billingDetails.address.line2 != nil)
                writer.redactedProperty("city", isPresent: billingDetails.address.city != nil)
                writer.property("state", optionalString: billingDetails.address.state)
                writer.maskedPostalCodeProperty("postalCode", value: billingDetails.address.postalCode)
            }
        }
    }

    private mutating func writeShippingAddress(_ shippingAddress: Checkout.Session.ShippingAddress?) {
        guard let shippingAddress else {
            property("shippingAddress", value: "nil")
            return
        }

        block("shippingAddress") { writer in
            writer.redactedProperty("name", isPresent: shippingAddress.name != nil)
            writer.block("address") { writer in
                writer.property("country", string: shippingAddress.address.country)
                writer.redactedProperty("line1", isPresent: shippingAddress.address.line1 != nil)
                writer.redactedProperty("line2", isPresent: shippingAddress.address.line2 != nil)
                writer.redactedProperty("city", isPresent: shippingAddress.address.city != nil)
                writer.property("state", optionalString: shippingAddress.address.state)
                writer.maskedPostalCodeProperty("postalCode", value: shippingAddress.address.postalCode)
            }
        }
    }

    private mutating func writeTax(_ tax: Checkout.Session.Tax?) {
        guard let tax else {
            property("tax", value: "nil")
            return
        }

        block("tax") { writer in
            writer.property("status", value: tax.status.debugCaseName)
        }
    }

    private mutating func writeTaxAmounts(_ name: String, _ taxAmounts: [Checkout.Session.TaxAmount]?) {
        guard let taxAmounts else {
            property(name, value: "nil")
            return
        }

        array(name, taxAmounts) { writer, taxAmount in
            writer.block { writer in
                writer.property("amount", string: taxAmount.amount)
                writer.property("minorUnitsAmount", value: String(taxAmount.minorUnitsAmount))
                writer.property("inclusive", value: String(taxAmount.inclusive))
                writer.property("displayName", string: taxAmount.displayName)
                writer.property("percentage", optionalValue: taxAmount.percentage)
            }
        }
    }

    private mutating func writeTotals(_ totals: Checkout.Session.Totals) {
        block("totals") { writer in
            writer.writeAmount("subtotal", totals.subtotal)
            writer.writeAmount("taxExclusive", totals.taxExclusive)
            writer.writeAmount("taxInclusive", totals.taxInclusive)
            writer.writeAmount("discount", totals.discount)
            writer.writeAmount("total", totals.total)
        }
    }

    private mutating func writeAmount(_ name: String, _ amount: Checkout.Session.Amount) {
        block(name) { writer in
            writer.property("amount", string: amount.amount)
            writer.property("minorUnitsAmount", value: String(amount.minorUnitsAmount))
        }
    }

    private mutating func property(_ name: String, string: String) {
        property(name, value: String(reflecting: string))
    }

    private mutating func property(_ name: String, optionalString: String?) {
        if let optionalString {
            property(name, string: optionalString)
        } else {
            property(name, value: "nil")
        }
    }

    private mutating func property<Value>(_ name: String, optionalValue: Value?) {
        property(name, value: optionalValue.map(String.init(describing:)) ?? "nil")
    }

    private mutating func redactedProperty(_ name: String, isPresent: Bool) {
        property(name, value: isPresent ? "<redacted>" : "nil")
    }

    private mutating func maskedEmailProperty(_ name: String, value: String?) {
        guard let value else {
            property(name, value: "nil")
            return
        }
        property(name, string: value.maskedEmailForCheckoutSessionDebugDescription)
    }

    private mutating func maskedPostalCodeProperty(_ name: String, value: String?) {
        guard let value else {
            property(name, value: "nil")
            return
        }
        property(name, string: String(value.prefix(2)) + "***")
    }

    private mutating func redactedCollectionProperty(_ name: String, count: Int) {
        property(name, value: count == 0 ? "[]" : "<redacted: \(count) values>")
    }

    private mutating func property(_ name: String, value: String) {
        line("\(name): \(value)")
    }

    private mutating func array<Element>(
        _ name: String,
        _ elements: [Element],
        writeElement: (inout Self, Element) -> Void
    ) {
        guard !elements.isEmpty else {
            property(name, value: "[]")
            return
        }

        line("\(name): [")
        indentation += 1
        for element in elements {
            writeElement(&self, element)
        }
        indentation -= 1
        line("]")
    }

    private mutating func block(
        _ name: String? = nil,
        isProperty: Bool = true,
        body: (inout Self) -> Void
    ) {
        line(name.map { "\($0)\(isProperty ? ":" : "") {" } ?? "{")
        indentation += 1
        body(&self)
        indentation -= 1
        line("}")
    }

    private mutating func line(_ value: String) {
        lines.append(String(repeating: "  ", count: indentation) + value)
    }
}

private extension String {
    var maskedEmailForCheckoutSessionDebugDescription: String {
        let emailParts = split(separator: "@", maxSplits: 1, omittingEmptySubsequences: false)
        guard emailParts.count == 2, let first = emailParts[0].first else {
            return "<redacted>"
        }

        let localPart: String
        if emailParts[0].count == 1 {
            localPart = "*"
        } else if emailParts[0].count == 2 {
            localPart = "\(first)*"
        } else {
            localPart = "\(first)**\(emailParts[0].last ?? first)"
        }
        return "\(localPart)@\(emailParts[1])"
    }
}

private extension Checkout.Session.Status {
    var debugCaseName: String {
        switch self {
        case .open:
            return ".open"
        case .expired:
            return ".expired"
        case .complete(let paymentStatus):
            return ".complete(\(paymentStatus.debugCaseName))"
        }
    }
}

private extension Checkout.Session.Status.PaymentStatus {
    var debugCaseName: String {
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

private extension Checkout.Session.Tax.Status {
    var debugCaseName: String {
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
