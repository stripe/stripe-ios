//
//  PaymentSheetFlowController+Shipping.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 5/27/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import Contacts

@_spi(STP) public extension PaymentSheet {
    /// 🏗 Under construction
    /// Contains Customer information related to shipping address.
    struct ShippingAddressDetails {
        let address: Address
        
        /// A user-facing description of the shipping address details.
        @_spi(STP) public var localizedDescription: String {
            let formatter = CNPostalAddressFormatter()

            let postalAddress = CNMutablePostalAddress()
            if let line1 = address.line1, !line1.isEmpty,
               let line2 = address.line2, !line2.isEmpty {
                postalAddress.street = "\(line1), \(line2)"
            } else {
                postalAddress.street = "\(address.line1 ?? "")\(address.line2 ?? "")"
            }
            postalAddress.postalCode = address.postalCode ?? ""
            postalAddress.city = address.city ?? ""
            postalAddress.state = address.state ?? ""
            postalAddress.country = address.country ?? ""

            return formatter.string(from: postalAddress)
        }
    }
}
