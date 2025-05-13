//
//  PaymentMethodWithLinkDetails.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 4/17/25.
//

import Foundation

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

        let linkDetailsJson = response["link_payment_details"] as? [AnyHashable: Any]

        if isUnsupportedLinkPaymentDetailsType(linkDetailsJson) {
            // This is a Link payment method, but we don't support the type yet. We can't render them, so hide them.
            return nil
        }

        var linkDetails: ConsumerPaymentDetails?

        if let linkDetailsJson {
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

    private static func isUnsupportedLinkPaymentDetailsType(_ json: [AnyHashable: Any]?) -> Bool {
        guard let json else {
            // Not a Link payment method, so we're fine
            return false
        }

        return json["type"] as? String != "CARD"
    }
}
