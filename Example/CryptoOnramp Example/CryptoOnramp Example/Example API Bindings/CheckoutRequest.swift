import Foundation

typealias QuoteRequest = CheckoutRequest

struct CheckoutRequest: Encodable {
    let cryptoOnrampSessionId: String

    enum CodingKeys: String, CodingKey {
        case cryptoOnrampSessionId = "cos_id"
    }
}

