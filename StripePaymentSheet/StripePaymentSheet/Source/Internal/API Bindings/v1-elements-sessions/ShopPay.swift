//
//  STPShopPay.swift
//  StripePaymentSheet
//

import Foundation

@_spi(STP) public struct ShopPay {
    let checkoutUrl: String
    var allResponseFields: [AnyHashable: Any]

    static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard let response,
              let checkoutUrl = response["checkout_url"] as? String else {
            return nil
        }

        return self.init(
            checkoutUrl: checkoutUrl,
            allResponseFields: response
        )
    }
}
