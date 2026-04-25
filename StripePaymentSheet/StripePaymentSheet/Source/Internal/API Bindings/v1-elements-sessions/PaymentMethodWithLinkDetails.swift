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
    let isLinkOrigin: Bool
    let linkDetails: ConsumerPaymentDetails?
    var allResponseFields: [AnyHashable: Any]

    // MARK: - STPAPIResponseDecodable

    required init(
        paymentMethod: STPPaymentMethod,
        isLinkOrigin: Bool,
        linkDetails: ConsumerPaymentDetails?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.paymentMethod = paymentMethod
        self.isLinkOrigin = isLinkOrigin
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

        let isLinkOrigin = response["is_link_origin"] as? Bool ?? false

        var linkDetails: ConsumerPaymentDetails?

        if let linkDetailsJson = response["link_payment_details"] as? [AnyHashable: Any] {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase

            if let data = try? JSONSerialization.data(withJSONObject: linkDetailsJson) {
                linkDetails = try? decoder.decode(ConsumerPaymentDetails.self, from: data)
            }
        }

        if let linkDetails, linkDetails.type.isUnparsed, linkDetails.display == nil {
            // This is a Link payment method with an unknown type and no display metadata. We can't render it.
            return nil
        }

        return self.init(
            paymentMethod: paymentMethod,
            isLinkOrigin: isLinkOrigin,
            linkDetails: linkDetails,
            allResponseFields: response
        )
    }
}
