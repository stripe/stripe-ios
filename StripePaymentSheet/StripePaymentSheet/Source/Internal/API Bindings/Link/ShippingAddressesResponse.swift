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
        var isDefault: Bool?
        let nickname: String?

        private enum CodingKeys: String, CodingKey {
            case id
            case address
            case isDefault = "is_default"
            case nickname
        }

        struct Address: Codable {
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

            var description: String {
                var description = ""
                if let line1 {
                    description += line1 + "\n"
                }
                if let line2 {
                    description += line2 + "\n"
                }

                if let locality, let administrativeArea, let postalCode {
                    description += locality + ", " + administrativeArea + " " + postalCode
                }

                return description
            }
        }
    }

    let shippingAddresses: [ShippingAddress]

    private enum CodingKeys: String, CodingKey {
        case shippingAddresses = "shipping_addresses"
    }
}

struct ShippingAddressUpdateResponse: Decodable {

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
}

extension ShippingAddressesResponse.ShippingAddress.Address {
    func convertToDictionary() -> [String: Any?]? {
        let encoder = JSONEncoder()
        do {
            // Encode to JSON data
            let jsonData = try encoder.encode(self)

            // Decode JSON data to dictionary
            if let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                return jsonDictionary
            }
        } catch {
            print("Error during JSON conversion: \(error.localizedDescription)")
        }
        return nil
    }
}
