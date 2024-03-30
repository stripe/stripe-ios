//
//  STPConnectAccountParams.swift
//  StripePayments
//
//  Created by Daniel Jackson on 1/4/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

/// The business type of the Connect account.
@objc public enum STPConnectAccountBusinessType: Int {
    /// This Connect account represents an individual.
    case individual
    /// This Connect account represents a company.
    case company
    /// No value was provided.
    /// - Note: This value is used instead of `nil` for Obj-C compatibility.
    case none
}

/// Parameters for creating a Connect Account token.
/// - seealso: https://stripe.com/docs/api/tokens/create_account
public class STPConnectAccountParams: NSObject {

    /// Boolean indicating that the Terms Of Service were shown to the user &
    /// the user accepted them.
    @objc public var tosShownAndAccepted: NSNumber?

    /// The business type.
    @objc public var businessType: STPConnectAccountBusinessType

    /// Information about the individual represented by the account.
    @objc public var individual: STPConnectAccountIndividualParams?

    /// Information about the company or business.
    @objc public var company: STPConnectAccountCompanyParams?

    @objc public var additionalAPIParameters: [AnyHashable: Any] = [:]

    /// Initialize `STPConnectAccountParams` with tosShownAndAccepted = YES
    /// This method cannot be called with `wasAccepted == NO`, guarded by a `NSParameterAssert()`.
    /// Use this init method if you want to set the `tosShownAndAccepted` parameter. If you
    /// don't, use the `initWithIndividual:` version instead.
    /// - Parameters:
    ///   - wasAccepted: Must be YES, but only if the user was shown & accepted the ToS
    ///   - individual: Information about the person represented by the account. See `STPConnectAccountIndividualParams`.
    @objc public init?(
        tosShownAndAccepted wasAccepted: Bool,
        individual: STPConnectAccountIndividualParams
    ) {
        // It is an error to call this method with wasAccepted == NO
        guard wasAccepted == true else {
            return nil
        }
        self.tosShownAndAccepted = wasAccepted as NSNumber
        self.individual = individual
        self.company = nil
        self.businessType = .individual
        super.init()
    }

    /// Initialize `STPConnectAccountParams` with tosShownAndAccepted = YES
    /// This method cannot be called with `wasAccepted == NO`, guarded by a `NSParameterAssert()`.
    /// Use this init method if you want to set the `tosShownAndAccepted` parameter. If you
    /// don't, use the `initWithCompany:` version instead.
    /// - Parameters:
    ///   - wasAccepted: Must be YES, but only if the user was shown & accepted the ToS
    ///   - company: Information about the company or business. See `STPConnectAccountCompanyParams`.
    @objc public init?(
        tosShownAndAccepted wasAccepted: Bool,
        company: STPConnectAccountCompanyParams
    ) {
        // It is an error to call this method with wasAccepted == NO
        guard wasAccepted == true else {
            return nil
        }
        self.tosShownAndAccepted = wasAccepted as NSNumber
        self.individual = nil
        self.company = company
        self.businessType = .company
        super.init()
    }

    /// Initialize `STPConnectAccountParams` with the provided `individual` dictionary.
    /// - Parameter individual: Information about the person represented by the account
    /// This init method cannot change the `tosShownAndAccepted` parameter. Use
    /// `initWithTosShownAndAccepted:individual:` instead if you need to do that.
    @objc
    public init(
        individual: STPConnectAccountIndividualParams
    ) {
        tosShownAndAccepted = false
        self.individual = individual
        self.company = nil
        businessType = .individual
        super.init()

    }

    /// Initialize `STPConnectAccountParams` with the provided `company` dictionary.
    /// - Parameter company: Information about the company or business
    /// This init method cannot change the `tosShownAndAccepted` parameter. Use
    /// `initWithTosShownAndAccepted:company:` instead if you need to do that.
    @objc
    public init(
        company: STPConnectAccountCompanyParams
    ) {
        tosShownAndAccepted = false
        self.individual = nil
        self.company = company
        businessType = .company
        super.init()
    }

    @objc public override init() {
        tosShownAndAccepted = false
        businessType = .none
        individual = nil
        company = nil
        super.init()
    }

    // MARK: - description
    /// :nodoc:
    @objc public override var description: String {
        let props: [String] = [
            String(format: "%@: %p", NSStringFromClass(STPConnectAccountParams.self), self),
            // We use NSParameterAssert to block this being NO:
            "tosShownAndAccepted = \(String(describing: tosShownAndAccepted))",
            "individual = \(String(describing: individual))",
            "company = \(String(describing: company))",
            "business_type = \(STPConnectAccountParams.string(from: businessType) ?? "nil")",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    // MARK: - STPConnectAccountBusinessType
    class func string(from businessType: STPConnectAccountBusinessType) -> String? {
        switch businessType {
        case .individual:
            return "individual"
        case .company:
            return "company"
        case .none:
            return nil
        }
    }

}

// MARK: - STPFormEncodable
extension STPConnectAccountParams: STPFormEncodable {

    @objc var businessTypeString: String? {
        return STPConnectAccountParams.string(from: businessType)
    }

    @objc
    public class func rootObjectName() -> String? {
        return "account"
    }

    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: tosShownAndAccepted)): "tos_shown_and_accepted",
            NSStringFromSelector(#selector(getter: individual)): "individual",
            NSStringFromSelector(#selector(getter: company)): "company",
            NSStringFromSelector(#selector(getter: businessTypeString)): "business_type",
        ]
    }
}
