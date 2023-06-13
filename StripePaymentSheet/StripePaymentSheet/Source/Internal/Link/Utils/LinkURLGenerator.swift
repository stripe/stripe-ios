//
//  LinkURLGenerator.swift
//  StripeIdentity
//

import Foundation

struct LinkURLParams: Encodable {
    struct MerchantInfo: Encodable {
        let businessName: String
        let country: String
    }
    struct CustomerInfo: Encodable {
        let country: String
        let email: String
    }
    struct PaymentInfo: Encodable {
        let currency: String
        let amount: Int
    }
    let path = "mobile_pay"
    let integrationType = "mobile"
    let publishableKey: String
    let merchantInfo: MerchantInfo
    let customerInfo: CustomerInfo
    let paymentInfo: PaymentInfo
    let returnUrl: URL
    let experiments: [String]
    let flags: [String]
    let loggerMetadata: [String]
    let locale = Locale.current.toLanguageTag()
}

class LinkURLGenerator {
    static func url() -> URL {
//      TODO: Create URLs based on params
        return URL(string: "https://checkout.link.com/#")!
    }
}
