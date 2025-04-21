//
//  PaymentDetailsShareResponse.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 8/7/24.
//

import Foundation
@_spi(STP) import StripePayments

final class PaymentDetailsShareResponse: NSObject, STPAPIResponseDecodable {
    static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard
            let response,
            let paymentMethodDict = response["payment_method"] as? [String: Any],
            let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodDict)
        else {
            return nil
        }
        let paymentDetailsShareResponse = PaymentDetailsShareResponse(
            paymentMethod: paymentMethod,
            allResponseFields: response
        )
        return .some(paymentDetailsShareResponse as! Self)
    }

    let allResponseFields: [AnyHashable: Any]
    let paymentMethod: STPPaymentMethod
    init(paymentMethod: STPPaymentMethod, allResponseFields: [AnyHashable: Any]) {
        self.paymentMethod = paymentMethod
        self.allResponseFields = allResponseFields
    }
}
