//
//  STPUSPaperCheckCreateParams.swift
//  StripePayments
//
//  Created by Martin Gordon on 8/8/25.
//  Copyright © 2025 Stripe, Inc. All rights reserved.
//

import Foundation

/// Parameters for creating a US Paper Check
@_spi(STP) public class STPUSPaperCheckCreateParams: NSObject, Encodable {
    
    /// The amount for the paper check in cents
    @objc public var amount: Int64
    
    /// Three-letter ISO currency code
    @objc public var currency: String
    
    /// The front image file ID of the paper check
    @objc public var frontImage: String
    
    /// The back image file ID of the paper check
    @objc public var backImage: String
    
    /// Optional description for the paper check
    @objc public var checkDescription: String?
        
    /// Designated initializer
    /// - Parameters:
    ///   - amount: The amount in cents
    ///   - currency: Three-letter ISO currency code
    ///   - frontImage: The front image file ID
    ///   - backImage: The back image file ID
    ///   - description: Optional description
    @objc public init(
        amount: Int64,
        currency: String,
        frontImage: String,
        backImage: String,
        description: String? = nil
    ) {
        self.amount = amount
        self.currency = currency
        self.frontImage = frontImage
        self.backImage = backImage
        self.checkDescription = description
        super.init()
    }
    
    // MARK: - STPFormEncodable
    @objc
    public class func rootObjectName() -> String? {
        return nil
    }
    
    @objc
    public class func propertyNamesToFormFieldNamesMapping() -> [String: String] {
        return [
            NSStringFromSelector(#selector(getter: amount)): "amount",
            NSStringFromSelector(#selector(getter: currency)): "currency",
            NSStringFromSelector(#selector(getter: frontImage)): "front_image",
            NSStringFromSelector(#selector(getter: backImage)): "back_image",
            NSStringFromSelector(#selector(getter: checkDescription)): "description"
        ]
    }
}
