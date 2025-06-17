//
//  STPElementsECESessionsResponse.swift
//  StripePaymentSheet
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// The response returned by v1/elements/express_checkout_element/sessions/
@_spi(STP) final public class STPElementsECESessions: NSObject {
    let shopPay: ShopPay?
    public let allResponseFields: [AnyHashable: Any]

    internal init(
        allResponseFields: [AnyHashable: Any],
        shopPay: ShopPay?
    ) {
        self.shopPay = shopPay
        self.allResponseFields = allResponseFields
    }
}

extension STPElementsECESessions: STPAPIResponseDecodable {
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response else {
            return nil
        }

        if let typeSpecificDataDict = response["type_specific_data"] as? [AnyHashable: Any],
            // The `shop_pay` key is required to be in the payload if type_specific_data exists, but can have a value of null
            let shopPay = ShopPay.decodedObject(fromAPIResponse: typeSpecificDataDict["shop_pay"] as? [AnyHashable: Any]) {
            return self.init(
                allResponseFields: response,
                shopPay: shopPay
            )
        }
        return self.init(
            allResponseFields: response,
            shopPay: nil)
    }
}
