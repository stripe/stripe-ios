//
//  ShippingAddressResponse.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 7/22/25.
//

struct ShippingAddressResponse: Decodable {
    struct ShippingAddress: Decodable {
        let id: String
        let address: Address
        let isDefault: Bool?
        let nickname: String?

        private enum CodingKeys: String, CodingKey {
            case id
            case address
            case isDefault = "is_default"
            case nickname
        }

        struct Address: Decodable {
            let administrativeArea: String?
            let countryCode: String?
            let dependentLocality: String?
            let line1: String?
            let line2: String?
            let locality: String?
            let name: String?
            let postalCode: String?
            let sortingCode: String?

            private enum CodingKeys: String, CodingKey {
                case administrativeArea = "administrative_area"
                case countryCode = "country_code"
                case dependentLocality = "dependent_locality"
                case line1 = "line_1"
                case line2 = "line_2"
                case locality
                case name
                case postalCode = "postal_code"
                case sortingCode = "sorting_code"
            }
        }
    }

    let shippingAddress: ShippingAddress

    private enum CodingKeys: String, CodingKey {
        case shippingAddress = "shipping_address"
    }
}
