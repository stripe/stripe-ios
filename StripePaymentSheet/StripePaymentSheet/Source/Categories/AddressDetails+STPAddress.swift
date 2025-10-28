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

    var paymentIntentShippingDetailsParams: STPPaymentIntentShippingDetailsParams? {
        guard let name = name else {
            return nil
        }

        let addressParams = STPPaymentIntentShippingDetailsAddressParams(line1: address.line1)
        addressParams.line2 = address.line2
        addressParams.city = address.city
        addressParams.state = address.state
        addressParams.postalCode = address.postalCode
        addressParams.country = address.country

        let shippingDetailsParams = STPPaymentIntentShippingDetailsParams(address: addressParams, name: name)
        shippingDetailsParams.phone = phone

        return shippingDetailsParams
    }
}
