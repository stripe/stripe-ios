//
//  STPUSPaperCheck.swift
//  StripePayments
//
//  Created by Martin Gordon on 8/8/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation

/// Represents a US Paper Check object returned from the Stripe API
@_spi(STP) public class STPUSPaperCheck: NSObject, Decodable {
    
    /// The unique identifier for the paper check
    @objc public let stripeID: String
    
    /// The amount for the paper check in cents
    @objc public let amount: Int64
    
    /// Three-letter ISO currency code
    @objc public let currency: String
    
    /// The status of the paper check
    @objc public let status: String
    
    /// The front image file ID of the paper check
    @objc public let frontImage: String
    
    /// The back image file ID of the paper check
    @objc public let backImage: String
    
    /// Optional description for the paper check
    @objc public let checkDescription: String?
    
    /// Timestamp when the paper check was created
    @objc public let created: Date
    
    // MARK: - STPAPIResponseDecodable
    @objc public class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response,
              let stripeID = response["id"] as? String,
              let amount = response["amount"] as? Int64,
              let currency = response["currency"] as? String,
              let status = response["status"] as? String,
              let frontImage = response["front_image"] as? String,
              let backImage = response["back_image"] as? String,
              let createdTimestamp = response["created"] as? NSNumber else {
            return nil
        }
        
        let paperCheck = self.init(
            stripeID: stripeID,
            amount: amount,
            currency: currency,
            status: status,
            frontImage: frontImage,
            backImage: backImage,
            description: response["description"] as? String,
            created: Date(timeIntervalSince1970: createdTimestamp.doubleValue)
        )
        
        return paperCheck
    }
    
    @objc required init(
        stripeID: String,
        amount: Int64,
        currency: String,
        status: String,
        frontImage: String,
        backImage: String,
        description: String?,
        created: Date
    ) {
        self.stripeID = stripeID
        self.amount = amount
        self.currency = currency
        self.status = status
        self.frontImage = frontImage
        self.backImage = backImage
        self.checkDescription = description
        self.created = created
        super.init()
    }
}

@_spi(STP) public typealias STPUSPaperCheckCompletionBlock = (STPUSPaperCheck?, Error?) -> Void
