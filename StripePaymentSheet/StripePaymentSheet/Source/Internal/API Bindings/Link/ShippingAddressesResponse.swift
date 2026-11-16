//
//  ShippingAddressesResponse.swift
//  StripePaymentSheet
//
//  Created by Chris Mays on 5/23/25.
//

struct ShippingAddressesResponse: Decodable {
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

    let shippingAddresses: [ShippingAddress]

    private enum CodingKeys: String, CodingKey {
        case shippingAddresses = "shipping_addresses"
    }
}

struct CreateShippingAddressResponse: Decodable {
    let shippingAddress: ShippingAddressesResponse.ShippingAddress

    private enum CodingKeys: String, CodingKey {
        case shippingAddress = "shipping_address"
    }
}

extension ShippingAddressesResponse.ShippingAddress {
    func toPaymentSheetAddress() -> PaymentSheet.Address {
        .init(
            city: address.locality,
            country: address.countryCode,
            line1: address.line1,
            line2: address.line2,
            postalCode: address.postalCode,
            state: address.administrativeArea
        )
    }

    /// The address on a single line, without the name, e.g. "123 Main St, San Francisco, CA 94111, US".
    var formattedAddress: String {
        let stateAndPostalCode = [address.administrativeArea, address.postalCode]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return [address.line1, address.line2, address.locality, stateAndPostalCode, address.countryCode]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
