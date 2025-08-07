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

    public enum RequirementsOption: Equatable, Codable {
        case only([String])
        case exclude([String])

        // Without this specific encoder, Swift will encode as `only: {_0: ["requirement.name"]}` as opposed to `only: ["requirement.name"]`
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            switch self {
            case .only(let array):
                try container.encode(array, forKey: .only)
            case .exclude(let array):
                try container.encode(array, forKey: .exclude)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case only, exclude
        }
    }

    /// Customizes collecting `currently_due` or `eventually_due` requirements
    public var fields: FieldOption = .currentlyDue

    /// Controls whether to include [future requirements](https://docs.stripe.com/api/accounts/object#account_object-future_requirements)
    public var futureRequirements: FutureRequirementOption = .omit

    /// Specifies which requirements to collect or exclude
    public var requirements: RequirementsOption?

    public init() {}
}
