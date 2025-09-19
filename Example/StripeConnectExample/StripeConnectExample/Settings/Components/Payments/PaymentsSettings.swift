//
//  PaymentsSettings.swift
//  StripeConnect Example
//
//  Created by Torrance Yang on 8/7/25.
//

import Foundation
@_spi(PrivateBetaConnect) import StripeConnect

struct PaymentsSettings: Equatable {

    var amountFilterType: AmountFilterType = .none
    var amountValue: String = ""
    var amountLowerBound: String = ""
    var amountUpperBound: String = ""

    var dateFilterType: DateFilterType = .none
    var beforeDate: Date = Date()
    var afterDate: Date = Date()
    var startDate: Date = Date()
    var endDate: Date = Date()

    var selectedStatuses: Set<String> = []
    var selectedPaymentMethod: String?

    // Convert to SDK's PaymentsListDefaultFiltersOptions
    var paymentsListDefaultFiltersOptions: EmbeddedComponentManager.PaymentsListDefaultFiltersOptions {
        var options = EmbeddedComponentManager.PaymentsListDefaultFiltersOptions()

        // Convert amount filter
        switch amountFilterType {
        case .none:
            options.amount = nil
        case .equals:
            if let amount = Double(amountValue) {
                options.amount = .equals(amount)
            }
        case .greaterThan:
            if let amount = Double(amountValue) {
                options.amount = .greaterThan(amount)
            }
        case .lessThan:
            if let amount = Double(amountValue) {
                options.amount = .lessThan(amount)
            }
        case .between:
            if let lowerBound = Double(amountLowerBound),
               let upperBound = Double(amountUpperBound) {
                options.amount = .between(lowerBound: lowerBound, upperBound: upperBound)
            }
        }

        // Convert date filter
        switch dateFilterType {
        case .none:
            options.date = nil
        case .before:
            options.date = .before(beforeDate)
        case .after:
            options.date = .after(afterDate)
        case .between:
            options.date = .between(start: startDate, end: endDate)
        }

        // Convert status filter
        if !selectedStatuses.isEmpty {
            let sdkStatuses = selectedStatuses.compactMap { statusString -> EmbeddedComponentManager.PaymentsListDefaultFiltersOptions.Status? in
                return EmbeddedComponentManager.PaymentsListDefaultFiltersOptions.Status.allCases.first { status in
                    String(describing: status) == statusString
                }
            }
            if !sdkStatuses.isEmpty {
                options.status = sdkStatuses
            }
        }

        // Convert payment method filter
        if let paymentMethodString = selectedPaymentMethod {
            options.paymentMethod = EmbeddedComponentManager.PaymentsListDefaultFiltersOptions.PaymentMethod.allCases.first { paymentMethod in
                String(describing: paymentMethod) == paymentMethodString
            }
        }

        return options
    }
    // MARK: - Supporting Enums
    enum AmountFilterType: String, CaseIterable, Identifiable {
        case none
        case equals
        case greaterThan
        case lessThan
        case between

        var id: String { rawValue }

        var displayLabel: String {
            switch self {
            case .none: return "None"
            case .equals: return "Equals"
            case .greaterThan: return "Greater than"
            case .lessThan: return "Less than"
            case .between: return "Between"
            }
        }
    }

    enum DateFilterType: String, CaseIterable, Identifiable {
        case none
        case before
        case after
        case between

        var id: String { rawValue }

        var displayLabel: String {
            switch self {
            case .none: return "None"
            case .before: return "Before"
            case .after: return "After"
            case .between: return "Between"
            }
        }
    }
}

// MARK: - SDK Integration
extension PaymentsSettings {
    /// Get available status options from the SDK
    static var availableStatusOptions: [EmbeddedComponentManager.PaymentsListDefaultFiltersOptions.Status] {
        return EmbeddedComponentManager.PaymentsListDefaultFiltersOptions.Status.allCases
    }

    /// Get available status strings for UI
    static var availableStatusStrings: [String] {
        return availableStatusOptions.map { String(describing: $0) }
    }

    /// Convert status string to display name
    static func statusDisplayName(_ statusString: String) -> String {
        return statusString.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).capitalized
    }

    /// Get available payment method options from the SDK
    static var availablePaymentMethodOptions: [EmbeddedComponentManager.PaymentsListDefaultFiltersOptions.PaymentMethod] {
        return EmbeddedComponentManager.PaymentsListDefaultFiltersOptions.PaymentMethod.allCases
    }

    /// Get available payment method strings for UI
    static var availablePaymentMethodStrings: [String] {
        return availablePaymentMethodOptions.map { String(describing: $0) }
    }

    /// Convert payment method string to display name
    static func paymentMethodDisplayName(_ methodString: String) -> String {
        return methodString.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).capitalized
    }
}
