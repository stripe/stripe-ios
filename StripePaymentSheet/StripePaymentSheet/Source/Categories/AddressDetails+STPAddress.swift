//
//  AddressDetails+STPAddress.swift
//  StripePaymentSheet
//

import Foundation

extension AddressViewController.AddressDetails {
    var stpAddress: STPAddress {
        let stpAddress = STPAddress()
        stpAddress.name = name
        stpAddress.phone = phone
        stpAddress.line1 = address.line1
        stpAddress.line2 = address.line2
        stpAddress.city = address.city
        stpAddress.state = address.state
        stpAddress.postalCode = address.postalCode
        stpAddress.country = address.country
        return stpAddress
    }
}
