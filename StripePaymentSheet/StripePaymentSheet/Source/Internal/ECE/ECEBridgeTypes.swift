//
//  ECEBridgeTypes.swift
//  StripePaymentSheet
//

import Foundation
import StripePayments

// MARK: - Shipping Address Types

/// Shipping address from the shippingaddresschange event
struct ECEShippingAddressChangeEvent: Codable {
    /// The name of the recipient
    let name: String?

    /// The shipping address of the recipient
    /// Note: To maintain privacy, browsers might anonymize the shipping address
    let address: ECEPartialAddress
}

/// Partial address used during shipping address selection
/// May have missing or partially redacted fields for privacy
struct ECEPartialAddress: Codable {
    /// City name
    let city: String?

    /// Two-letter country code
    let country: String?

    /// Postal or ZIP code
    let postalCode: String?

    /// State
    let state: String?

    private enum CodingKeys: String, CodingKey {
        case city
        case country
        case postalCode = "postal_code"
        case state
    }
}

/// Full address used in billing/shipping confirmation
struct ECEFullAddress: Codable {
    let line1: String?
    let line2: String?
    let city: String?
    let state: String?
    let postalCode: String?
    let country: String?

    private enum CodingKeys: String, CodingKey {
        case line1
        case line2
        case city
        case state
        case postalCode = "postal_code"
        case country
    }

    var stpPaymentMethodAddress: STPPaymentMethodAddress {
        let address = STPPaymentMethodAddress()
        address.line1 = line1
        address.line2 = line2
        address.city = city
        address.state = state
        address.postalCode = postalCode
        address.country = country
        return address
    }
}

// MARK: - Shipping Rate Types

/// Shipping rate object used throughout the ECE flow
struct ECEShippingRate: Codable {
    /// Unique identifier for the object
    let id: String

    /// The amount to charge for shipping
    let amount: Int

    /// The name of the shipping rate, displayed to the customer
    let displayName: String

    /// The estimated range for how long shipping takes
    /// Can be either a string or a structured object
    let deliveryEstimate: ECEDeliveryEstimate?
}

/// Delivery estimate can be a string or structured estimate
enum ECEDeliveryEstimate: Codable {
    case string(String)
    case structured(ECEStructuredDeliveryEstimate)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let structuredValue = try? container.decode(ECEStructuredDeliveryEstimate.self) {
            self = .structured(structuredValue)
        } else {
            throw DecodingError.typeMismatch(
                ECEDeliveryEstimate.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or ECEStructuredDeliveryEstimate")
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .structured(let value):
            try container.encode(value)
        }
    }
}

/// Structured delivery estimate with time ranges
struct ECEStructuredDeliveryEstimate: Codable {
    /// The upper bound of the estimated range
    /// If nil, represents no upper bound (infinite)
    let maximum: ECEDeliveryEstimateUnit?

    /// The lower bound of the estimated range
    /// If nil, represents no lower bound
    let minimum: ECEDeliveryEstimateUnit?
}

/// A unit of time for delivery estimates
struct ECEDeliveryEstimateUnit: Codable {
    /// The unit of time
    let unit: DeliveryTimeUnit

    /// Must be greater than 0
    let value: Int

    enum DeliveryTimeUnit: String, Codable {
        case hour
        case day
        case businessDay = "business_day"
        case week
        case month
    }
}

struct ECEPaymentMethodOptions: Codable {
    struct ShopPay: Codable {
        let externalSourceId: String
    }
    let shopPay: ShopPay?
}

// MARK: - Line Item Types

/// Line item shown in the payment interface
struct ECELineItem: Codable {
    /// The name of the line item surfaced to the customer
    let name: String

    /// The amount in the currency's subunit (e.g., cents, yen, etc.)
    let amount: Int
}

// MARK: - Billing Details Types

/// Billing details from the confirm event
struct ECEBillingDetails: Codable {
    /// The name of the customer
    let name: String?

    /// The email address of the customer
    let email: String?

    /// The phone number of the customer
    let phone: String?

    /// The billing address of the customer
    /// Note: When using PayPal, only country code may be available
    let address: ECEFullAddress?
}

// MARK: - Click Event Types

/// Configuration for the payment interface from the click event
struct ECEClickConfiguration: Codable {
    /// Line items to display in the payment interface
    let lineItems: [ECELineItem]

    /// Available shipping rates
    let shippingRates: [ECEShippingRate]?

    /// Apple Pay specific options
    let applePay: ECEApplePayOptions?
}

/// Apple Pay specific options
struct ECEApplePayOptions: Codable {
    // Add Apple Pay specific fields as needed
}

// MARK: - Event Response Types

/// Response for shipping address/rate change events
struct ECEShippingUpdateResponse: Codable {
    /// Updated line items
    let lineItems: [ECELineItem]?

    /// Updated shipping rates
    let shippingRates: [ECEShippingRate]?

    /// Apple Pay specific options
    let applePay: ECEApplePayOptions?

    /// Updated total amount (optional, used to update the payment sheet)
    let totalAmount: Int?
}

/// Response for payment confirmation
struct ECEPaymentConfirmationResponse: Codable {
    // Define based on your payment confirmation needs
}

// MARK: - Confirm Event Types

/// Data from the confirm event
struct ECEConfirmEventData: Codable {
    /// Billing details of the customer
    let billingDetails: ECEBillingDetails?

    /// Shipping address information
    let shippingAddress: ECEShippingAddressData?

    /// Selected shipping rate
    let shippingRate: ECEShippingRate?

    /// Payment method options
    let paymentMethodOptions: ECEPaymentMethodOptions?
}

/// Shipping address data from confirm event
struct ECEShippingAddressData: Codable {
    /// The name of the recipient
    let name: String?

    /// The full shipping address
    let address: ECEFullAddress?
}
extension ECEShippingAddressData {
    func toSTPAddress() -> STPAddress {
        let stpAddress = STPAddress()
        stpAddress.name = name
        stpAddress.line1 = address?.line1
        stpAddress.line2 = address?.line2
        stpAddress.city = address?.city
        stpAddress.state = address?.state
        stpAddress.postalCode = address?.postalCode
        stpAddress.country = address?.country
        return stpAddress
    }
}

// MARK: - Express Payment Type

/// The payment method the customer checks out with
enum ECEExpressPaymentType: String, Codable {
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    case amazonPay = "amazon_pay"
    case paypal
    case link
    case klarna
}

// MARK: - Bridge Error

enum ECEBridgeError: LocalizedError {
    case decodingError(String)
    case encodingError(String)
    case invalidMessageFormat

    var errorDescription: String? {
        switch self {
        case .decodingError(let details):
            return "Failed to decode bridge message: \(details)"
        case .encodingError(let details):
            return "Failed to encode bridge response: \(details)"
        case .invalidMessageFormat:
            return "Invalid message format received from bridge"
        }
    }
}

// MARK: - Conversion Helpers

extension ECEBridgeTypes {
    /// Safely decode a dictionary into a Codable type
    static func decode<T: Codable>(_ type: T.Type, from dictionary: [String: Any]) throws -> T {
        do {
            let data = try JSONSerialization.data(withJSONObject: dictionary)
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            throw ECEBridgeError.decodingError(error.localizedDescription)
        }
    }

    /// Safely encode a Codable type into a dictionary
    static func encode<T: Codable>(_ value: T) throws -> [String: Any] {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(value)
            guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw ECEBridgeError.encodingError("Result was not a dictionary")
            }
            return dictionary
        } catch {
            throw ECEBridgeError.encodingError(error.localizedDescription)
        }
    }
}

// Type alias for the helper methods
typealias ECEBridgeTypes = Never
