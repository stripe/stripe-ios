//
//  CardBase.swift
//  CardScan
//
//  Created by Jaime Park on 1/31/20.
//

import Foundation

@objc public class CardBase: NSObject {
    @objc public var last4: String
    @objc public var bin: String?
    @objc public var expMonth: String?
    @objc public var expYear: String?
    public var isNewCard: Bool = false
        
    public init(last4: String, bin: String?, expMonth: String? = nil, expYear: String? = nil) {
        self.last4 = last4
        self.bin = bin
        self.expMonth = expMonth
        self.expYear = expYear
    }
    
    @objc public func expiryForDisplay() -> String? {
        guard let month = self.expMonth, let year = self.expYear else {
            print("Could not unwrap expiration month and/or year")
            return nil
        }
               
        return CreditCardUtils.formatExpirationDate(expMonth: month, expYear: year)
    }
    
    @objc public func toOcrJson() -> [String: Any] {
        var ocrJson: [String: Any] = [:]
        ocrJson["last4"] = self.last4
        ocrJson["bin"] = self.bin
        ocrJson["exp_month"] = self.expMonth
        ocrJson["exp_year"] = self.expYear

        return ocrJson
    }
}
