//
//  STPConfirmationToken.swift
//  StripePayments
//
//  Created by Nick Porter on 9/4/25.
//

import Foundation

/// A ConfirmationToken object represents a client-side confirmation token that can be used to confirm a PaymentIntent or SetupIntent.
/// - seealso: https://stripe.com/docs/api/confirmation_tokens
@_spi(ConfirmationTokensPublicPreview) public class STPConfirmationToken: NSObject, STPAPIResponseDecodable {
    /// You cannot directly instantiate an `STPConfirmationToken`. You should only use one that is returned from the Stripe API.
    required internal override init() {
        super.init()
    }

    /// The unique identifier for the ConfirmationToken.
    @objc public private(set) var stripeId: String = ""
    /// String representing the object's type. Objects of the same type share the same value.
    @objc public private(set) var object: String = ""
    /// Has the value `true` if the object exists in live mode or the value `false` if the object exists in test mode.
    @objc public private(set) var livemode: Bool = false
    /// Time at which the object was created. Measured in seconds since the Unix epoch.
    @objc public private(set) var created: Date = Date()

    /// :nodoc:
    @objc public private(set) var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - STPAPIResponseDecodable

    @objc
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }

        let confirmationToken = self.init()
        confirmationToken.allResponseFields = response

        // Parse basic fields
        confirmationToken.stripeId = response["id"] as? String ?? ""
        confirmationToken.object = response["object"] as? String ?? ""
        confirmationToken.livemode = response["livemode"] as? Bool ?? false

        // Parse created timestamp
        if let createdTimestamp = response["created"] as? TimeInterval {
            confirmationToken.created = Date(timeIntervalSince1970: createdTimestamp)
        }

        return confirmationToken
    }

    // MARK: - NSObject

    /// :nodoc:
    @objc public override var description: String {
        let props = [
            // Object
            String(format: "%@: %p", NSStringFromClass(STPConfirmationToken.self), self),
            // ConfirmationToken details
            "id = \(stripeId)",
            "object = \(object)",
            "livemode = \(livemode ? "YES" : "NO")",
            "created = \(created)",
        ]

        return "<\(props.joined(separator: "; "))>"
    }
}
