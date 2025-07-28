//
//  String+IDTypes.swift
//  StripeIdentity
//
//  Created by Kenneth Ackerson on 7/24/25.
//

@_spi(STP) import StripeCore

extension String {
    func uiIDType() -> String? {
        if self == "driving_license" {
            return String.Localized.driverLicense
        } else if self == "id_card" {
            return String.Localized.governmentIssuedId
        } else if self == "passport" {
            return String.Localized.passport
        }

        return nil
    }
}
