//
//  AccountCollectionOptions.swift
//  StripeConnect
//
//  Created by Chris Mays on 9/20/24.
//

import Foundation

/// Collection options for account onboarding
public struct AccountCollectionOptions: Equatable, Codable {

    public enum FieldOption: String, Codable {
        case currentlyDue = "currently_due"
        case eventuallyDue = "eventually_due"
    }

    public enum FutureRequirementOption: String, Codable {
        case omit
        case include
    }

    /// Customizes collecting `currently_due` or `eventually_due` requirements
    public var fields: FieldOption = .currentlyDue

    /// Controls whether to include [future requirements](https://docs.stripe.com/api/accounts/object#account_object-future_requirements)
    public var futureRequirements: FutureRequirementOption = .omit

    public init() {}
}
