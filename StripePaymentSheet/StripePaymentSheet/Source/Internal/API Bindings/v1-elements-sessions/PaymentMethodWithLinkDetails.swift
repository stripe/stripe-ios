//
//  PaymentMethodWithLinkDetails.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 4/17/25.
//

import Foundation
@_spi(STP) import StripeCore

class PaymentMethodWithLinkDetails: NSObject, STPAPIResponseDecodable {
    let paymentMethod: STPPaymentMethod
    let linkDetails: ConsumerPaymentDetails?
    var allResponseFields: [AnyHashable: Any]

    // MARK: - STPAPIResponseDecodable

    required init(paymentMethod: STPPaymentMethod, linkDetails: ConsumerPaymentDetails?, allResponseFields: [AnyHashable: Any]) {
        self.paymentMethod = paymentMethod
        self.linkDetails = linkDetails
        self.allResponseFields = allResponseFields
    }

    static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard
            let response,
            let paymentMethodJson = response["payment_method"] as? [AnyHashable: Any],
            let paymentMethod = STPPaymentMethod.decodedObject(fromAPIResponse: paymentMethodJson)
        else {
            return nil
        }

        var linkDetails: ConsumerPaymentDetails?

        if let linkDetailsJson = response["link_payment_details"] as? [AnyHashable: Any] {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let data = try? JSONSerialization.data(withJSONObject: linkDetailsJson) {
                linkDetails = try? decoder.decode(ConsumerPaymentDetails.self, from: data)
            }
        }

        return self.init(
            paymentMethod: paymentMethod,
            linkDetails: linkDetails,
            allResponseFields: response
        )
    }
}
