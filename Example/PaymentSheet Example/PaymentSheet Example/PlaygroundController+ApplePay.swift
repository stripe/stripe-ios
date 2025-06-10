//
//  PlaygroundController+ApplePay.swift
//  PaymentSheet Example
//
//  Created by John Woo on 6/10/25.
//

import UIKit
import PassKit

extension PlaygroundController {
    // Helper function for creating consistent summary items used by both handlers
    func createSummaryItems(shippingMethod: PKShippingMethod, taxRate: Double, taxName: String) -> [PKPaymentSummaryItem] {
        let baseProductPrice = NSDecimalNumber(string: "50.99")
        // Create summary items
        var summaryItems = [PKPaymentSummaryItem]()

        // Base product price is always the same
        summaryItems.append(PKPaymentSummaryItem(
            label: "Product",
            amount: baseProductPrice
        ))

        // Shipping cost from the selected method
        summaryItems.append(PKPaymentSummaryItem(
            label: shippingMethod.label,
            amount: shippingMethod.amount
        ))

        // Calculate subtotal for tax calculation
        let subtotal = baseProductPrice.adding(shippingMethod.amount)

        // Calculate tax with the appropriate rate and round to 2 decimal places
        let taxDecimal = NSDecimalNumber(value: taxRate)
        let taxAmount = roundToTwoDecimalPlaces(subtotal.multiplying(by: taxDecimal))
        summaryItems.append(PKPaymentSummaryItem(
            label: taxName,
            amount: taxAmount
        ))

        // Calculate the final total and round to 2 decimal places
        let totalAmount = roundToTwoDecimalPlaces(subtotal.adding(taxAmount))
        summaryItems.append(PKPaymentSummaryItem(
            label: "Example, Inc.",
            amount: totalAmount
        ))

        return summaryItems
    }
    // Helper function to round NSDecimalNumber to exactly 2 decimal places
    func roundToTwoDecimalPlaces(_ amount: NSDecimalNumber) -> NSDecimalNumber {
        let handler = NSDecimalNumberHandler(
            roundingMode: .plain,
            scale: 2,
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: true
        )

        return amount.rounding(accordingToBehavior: handler)
    }
    func determineTaxRate(contact: PKContact) -> (String, Double) {
        // Determine tax rate based on zip code
        var taxRate = 0.05  // Default 5% tax rate
        var taxName = "Sales Tax (5%)"

        if let postalCode = contact.postalAddress?.postalCode, postalCode == "00010" {
            taxRate = 0.10  // 10% tax for 00010
            taxName = "Sales Tax (10%)"
        }
        return (taxName, taxRate)
    }
    func shippingMethods() -> [PKShippingMethod] {
        let freeShipping = PKShippingMethod(label: "Free Shipping", amount: NSDecimalNumber(string: "0"))
        freeShipping.identifier = "freeshipping"
        freeShipping.detail = "Arrives in 6-8 weeks"

        let expressShipping = PKShippingMethod(label: "Express Shipping", amount: NSDecimalNumber(string: "10.00"))
        expressShipping.identifier = "expressshipping"
        expressShipping.detail = "Arrives in 2-3 days"
        return [freeShipping, expressShipping]
    }

}
