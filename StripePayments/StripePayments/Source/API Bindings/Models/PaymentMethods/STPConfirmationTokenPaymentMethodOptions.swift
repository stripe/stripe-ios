//
//  STPConfirmationTokenPaymentMethodOptions.swift
//  StripePayments
//
//  Created by Nick Porter on 8/25/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

/// Payment-method-specific configuration for a ConfirmationToken.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
public class STPConfirmationTokenPaymentMethodOptions: NSObject, STPFormEncodable {
    
    /// Configuration for any card payments confirmed using this ConfirmationToken.
    @objc public var card: STPConfirmationTokenCardOptions?
    
    /// Additional API parameters
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
    
    public override init() {
        super.init()
    }
    
    /// Convenience initializer for card-specific options.
    /// - Parameter card: Card payment method options
    @objc public convenience init(card: STPConfirmationTokenCardOptions?) {
        self.init()
        self.card = card
    }
    
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPConfirmationTokenPaymentMethodOptions.self), self),
            "card = \(String(describing: card))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }
    
    // MARK: - STPFormEncodable
    
    @objc
    public static func rootObjectName() -> String? {
        return nil
    }
    
    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: card)): "card",
        ]
    }
}

/// Card-specific options for ConfirmationToken.
public class STPConfirmationTokenCardOptions: NSObject, STPFormEncodable {
    
    /// Installment configuration for payments confirmed using this ConfirmationToken.
    @objc public var installments: STPConfirmationTokenInstallments?
    
    /// Additional API parameters
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
    
    public override init() {
        super.init()
    }
    
    /// Convenience initializer for card options with installments.
    /// - Parameter installments: Installment configuration
    @objc public convenience init(installments: STPConfirmationTokenInstallments?) {
        self.init()
        self.installments = installments
    }
    
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPConfirmationTokenCardOptions.self), self),
            "installments = \(String(describing: installments))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }
    
    // MARK: - STPFormEncodable
    
    @objc
    public static func rootObjectName() -> String? {
        return nil
    }
    
    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: installments)): "installments",
        ]
    }
}

/// Installment configuration for ConfirmationToken card payments.
public class STPConfirmationTokenInstallments: NSObject, STPFormEncodable {
    
    /// The selected installment plan to use for this payment attempt.
    @objc public var plan: STPConfirmationTokenInstallmentsPlan?
    
    /// Additional API parameters
    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]
    
    public override init() {
        super.init()
    }
    
    /// Convenience initializer for installments with a plan.
    /// - Parameter plan: The installment plan
    @objc public convenience init(plan: STPConfirmationTokenInstallmentsPlan?) {
        self.init()
        self.plan = plan
    }
    
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPConfirmationTokenInstallments.self), self),
            "plan = \(String(describing: plan))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }
    
    // MARK: - STPFormEncodable
    
    @objc
    public static func rootObjectName() -> String? {
        return nil
    }
    
    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: plan)): "plan",
        ]
    }
}

/// Installment plan configuration for ConfirmationToken.
public class STPConfirmationTokenInstallmentsPlan: NSObject, STPFormEncodable {
    
    /// Type of installment plan.
    public enum PlanType: String, CaseIterable {
        case fixedCount = "fixed_count"
        case bonus = "bonus" 
        case revolving = "revolving"
    }
    
    /// Interval between installment payments.
    public enum Interval: String, CaseIterable {
        case month = "month"
    }
    
    /// Type of installment plan (required).
    @objc public var type: STPConfirmationTokenInstallmentsPlanType = .unknown
    
    /// For fixed_count installment plans, the number of installment payments.
    @objc public var count: NSNumber?
    
    /// For fixed_count installment plans, the interval between installment payments.
    @objc public var interval: STPConfirmationTokenInstallmentsPlanInterval = .unknown
    
    /// Additional API parameters storage
    private var _additionalAPIParameters: [AnyHashable: Any] = [:]
    
    public override init() {
        super.init()
    }
    
    /// Convenience initializer for installment plan.
    /// - Parameters:
    ///   - type: Type of installment plan
    ///   - count: Number of installments (required for fixed_count)
    ///   - interval: Interval between payments (required for fixed_count) 
    @objc public convenience init(type: STPConfirmationTokenInstallmentsPlanType, count: NSNumber? = nil, interval: STPConfirmationTokenInstallmentsPlanInterval = .unknown) {
        self.init()
        self.type = type
        self.count = count
        self.interval = interval
    }
    
    /// :nodoc:
    @objc public override var description: String {
        let props = [
            String(format: "%@: %p", NSStringFromClass(STPConfirmationTokenInstallmentsPlan.self), self),
            "type = \(String(describing: type))",
            "count = \(String(describing: count))",
            "interval = \(String(describing: interval))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }
    
    // MARK: - STPFormEncodable
    
    @objc
    public static func rootObjectName() -> String? {
        return nil
    }
    
    @objc
    public static func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [:]
    }
    
    @objc public var additionalAPIParameters: [AnyHashable: Any] {
        get {
            var params = _additionalAPIParameters
            
            // Add type
            switch type {
            case .fixedCount:
                params["type"] = "fixed_count"
            case .bonus:
                params["type"] = "bonus"
            case .revolving:
                params["type"] = "revolving"
            case .unknown:
                break
            }
            
            // Add count if provided
            if let count = count {
                params["count"] = count
            }
            
            // Add interval
            switch interval {
            case .month:
                params["interval"] = "month"
            case .unknown:
                break
            }
            
            return params
        }
        set {
            _additionalAPIParameters = newValue
        }
    }
}

/// Type of installment plan.
@objc public enum STPConfirmationTokenInstallmentsPlanType: Int {
    case unknown = 0
    case fixedCount = 1
    case bonus = 2
    case revolving = 3
}

/// Interval between installment payments.
@objc public enum STPConfirmationTokenInstallmentsPlanInterval: Int {
    case unknown = 0
    case month = 1
}