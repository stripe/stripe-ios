//
//  CardBase.swift
//  CardScan
//
//  Created by Jaime Park on 1/31/20.
//

import Foundation

class CardBase: NSObject {
    var last4: String
    var bin: String?
    var expMonth: String?
    var expYear: String?
    var isNewCard: Bool = false

    init(last4: String, bin: String?, expMonth: String? = nil, expYear: String? = nil) {
        self.last4 = last4
        self.bin = bin
        self.expMonth = expMonth
        self.expYear = expYear
    }

    func expiryForDisplay() -> String? {
        guard let month = self.expMonth, let year = self.expYear else {
            return nil
        }

        return CreditCardUtils.formatExpirationDate(expMonth: month, expYear: year)
    }

    func toOcrJson() -> [String: Any] {
        var ocrJson: [String: Any] = [:]
        ocrJson["last4"] = self.last4
        ocrJson["bin"] = self.bin
        ocrJson["exp_month"] = self.expMonth
        ocrJson["exp_year"] = self.expYear

        return ocrJson
    }
}
