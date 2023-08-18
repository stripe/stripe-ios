//
//  LinkURLGenerator.swift
//  StripeIdentity
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

struct LinkURLParams: Encodable {
    struct MerchantInfo: Encodable {
        var businessName: String
        var country: String
    }
    struct CustomerInfo: Encodable {
        var country: String
        var email: String?
    }
    struct PaymentInfo: Encodable {
        var currency: String
        var amount: Int
    }
    enum PaymentObjectMode: String, Encodable {
        case link_payment_method
        case card_payment_method
    }
    var path = "mobile_pay"
    var integrationType = "mobile"
    var paymentObject: PaymentObjectMode
    var publishableKey: String
    var stripeAccount: String?
    var paymentUserAgent: String
    var merchantInfo: MerchantInfo
    var customerInfo: CustomerInfo
    var paymentInfo: PaymentInfo?
    var experiments: [String: Bool]
    var flags: [String: Bool]
    var loggerMetadata: [String: Bool]
    var locale: String
}

class LinkURLGenerator {
    static func linkParams(configuration: PaymentSheet.Configuration, intent: Intent) throws -> LinkURLParams {
        guard let publishableKey = configuration.apiClient.publishableKey ?? STPAPIClient.shared.publishableKey else {
            throw LinkURLGeneratorError.noPublishableKey
        }

        // We only expect regionCode to be nil in rare situations with a buggy simulator. Use a default value we can detect server-side.
        let customerCountryCode = intent.countryCode ?? configuration.defaultBillingDetails.address.country ?? Locale.current.regionCode ?? "US"

        let merchantCountryCode = intent.merchantCountryCode ?? customerCountryCode

        // Get email from the previously fetched account in the Link button, or the billing details, or the Customer object
        var customerEmail = LinkAccountContext.shared.account?.email

        if customerEmail == nil,
           let defaultBillingEmail = configuration.defaultBillingDetails.email {
            customerEmail = defaultBillingEmail
        }

        let merchantInfo = LinkURLParams.MerchantInfo(businessName: configuration.merchantDisplayName, country: merchantCountryCode)
        let customerInfo = LinkURLParams.CustomerInfo(country: customerCountryCode, email: customerEmail)

        let paymentInfo: LinkURLParams.PaymentInfo? = {
            if let currency = intent.currency, let amount = intent.amount {
                return LinkURLParams.PaymentInfo(currency: currency, amount: amount)
            }
            return nil
        }()

        return LinkURLParams(paymentObject: .link_payment_method,
                             publishableKey: publishableKey,
                             paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                             merchantInfo: merchantInfo,
                             customerInfo: customerInfo,
                             paymentInfo: paymentInfo,
                             experiments: [:], flags: [:], loggerMetadata: [:],
                             locale: Locale.current.toLanguageTag())
    }

    static func url(params: LinkURLParams) throws -> URL {
        var components = URLComponents(string: "https://checkout.link.com/")!
        components.fragment = try params.toURLEncodedBase64()
        guard let url = components.url else {
            throw LinkURLGeneratorError.urlCreationFailed
        }
        return url
    }

    static func url(configuration: PaymentSheet.Configuration, intent: Intent) async throws -> URL {
        let params = try Self.linkParams(configuration: configuration, intent: intent)
        return try url(params: params)
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
    case noPublishableKey
}
