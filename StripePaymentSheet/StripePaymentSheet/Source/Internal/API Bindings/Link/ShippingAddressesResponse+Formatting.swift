//
//  ShippingAddressesResponse+Formatting.swift
//  StripePaymentSheet
//

import Contacts

extension ShippingAddressesResponse.ShippingAddress {
    /// A compact one-line summary suitable for the wallet's shipping row (e.g. "123 Main St, San Francisco, CA").
    var formattedShortSummary: String {
        let addr = address
        var parts: [String] = []
        if let line1 = addr.line1, !line1.isEmpty { parts.append(line1) }

        var cityParts: [String] = []
        if let city = addr.locality, !city.isEmpty { cityParts.append(city) }
        if let state = addr.administrativeArea, !state.isEmpty { cityParts.append(state) }
        if !cityParts.isEmpty { parts.append(cityParts.joined(separator: ", ")) }

        if parts.isEmpty {
            return addr.name ?? ""
        }
        return parts.joined(separator: ", ")
    }

    /// A locale-aware multi-line address string for use in address list cells.
    var formattedCellAddress: String {
        let addr = address
        let postalAddress = CNMutablePostalAddress()

        var streetLines: [String] = []
        if let line1 = addr.line1, !line1.isEmpty { streetLines.append(line1) }
        if let line2 = addr.line2, !line2.isEmpty { streetLines.append(line2) }
        postalAddress.street = streetLines.joined(separator: "\n")

        postalAddress.city = addr.locality ?? ""
        postalAddress.state = addr.administrativeArea ?? ""
        postalAddress.postalCode = addr.postalCode ?? ""
        postalAddress.isoCountryCode = addr.countryCode ?? ""
        postalAddress.subLocality = addr.dependentLocality ?? ""

        return CNPostalAddressFormatter.string(from: postalAddress, style: .mailingAddress)
    }
}
