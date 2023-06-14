//
//  LinkURLGenerator.swift
//  StripeIdentity
//

import Foundation

struct LinkURLParams: Encodable {
    struct MerchantInfo: Encodable {
        var businessName: String?
        var country: String?
    }
    struct CustomerInfo: Encodable {
        var country: String?
        var email: String?
    }
    struct PaymentInfo: Encodable {
        var currency: String?
        var amount: Int?
    }
    enum LinkMode: String, Encodable {
        case pm
        case pass_through
    }
    var path = "mobile_pay"
    var integrationType = "mobile"
    var linkMode: LinkMode
    var publishableKey: String
    var merchantInfo: MerchantInfo
    var customerInfo: CustomerInfo
    var paymentInfo: PaymentInfo
    var returnUrl: URL
    var experiments: [String]
    var flags: [String]
    var loggerMetadata: [String]
    var locale: String
}

class LinkURLGenerator {
    static func url(params: LinkURLParams) throws -> URL {
        var components = URLComponents(string: "https://checkout.link.com/")!
        components.fragment = try params.toURLEncodedBase64()
        guard let url = components.url else {
            throw LinkURLGeneratorError.urlCreationFailed
        }
        return url
    }
}

extension LinkURLParams {
    func toURLEncodedBase64() throws -> String {
        let encodedData = try JSONEncoder().encode(self)
        return encodedData.base64EncodedString()
    }
}

enum LinkURLGeneratorError: Error {
    case urlCreationFailed
}
