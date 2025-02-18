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
    enum IntentMode: String, Encodable {
        case payment
        case setup
    }
    struct CardBrandChoiceInfo: Encodable {
        var isMerchantEligibleForCBC: Bool
        var stripePreferredNetworks: [String]
        var supportedCobrandedNetworks: [String: Bool]
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
    var loggerMetadata: [String: String]
    var locale: String
    var intentMode: IntentMode
    var setupFutureUsage: Bool
    var cardBrandChoice: CardBrandChoiceInfo?
    var linkFundingSources: [LinkSettings.FundingSource]
}

class LinkURLGenerator {
    static func linkParams(configuration: PaymentElementConfiguration, intent: Intent, elementsSession: STPElementsSession) throws -> LinkURLParams {
        guard let publishableKey = configuration.apiClient.publishableKey ?? STPAPIClient.shared.publishableKey else {
            throw LinkURLGeneratorError.noPublishableKey
        }

        // We only expect regionCode to be nil in rare situations with a buggy simulator. Use a default value we can detect server-side.
        let customerCountryCode = configuration.defaultBillingDetails.address.country ?? Locale.current.stp_regionCode ?? elementsSession.countryCode(overrideCountry: configuration.userOverrideCountry) ?? "US"

        let merchantCountryCode = elementsSession.merchantCountryCode ?? customerCountryCode

        // Get email from the previously fetched account in the Link button, or the billing details
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

        var loggerMetadata: [String: String] = [:]
        if let sessionID = AnalyticsHelper.shared.sessionID {
            loggerMetadata = ["mobile_session_id": sessionID]
        }

        let paymentObjectType: LinkURLParams.PaymentObjectMode = elementsSession.linkPassthroughModeEnabled ? .card_payment_method : .link_payment_method

        let intentMode: LinkURLParams.IntentMode = intent.isPaymentIntent ? .payment : .setup

        let cardBrandChoiceInfo: LinkURLParams.CardBrandChoiceInfo? = {
            guard let cardBrandChoice = elementsSession.cardBrandChoice else { return nil }
            return LinkURLParams.CardBrandChoiceInfo(isMerchantEligibleForCBC: cardBrandChoice.eligible,
                                                     stripePreferredNetworks: cardBrandChoice.preferredNetworks,
                                                     supportedCobrandedNetworks: cardBrandChoice.supportedCobrandedNetworks)
        }()

        let flags = elementsSession.linkFlags.merging(elementsSession.flags) { (current, _) in current }
        let linkFundingSources = elementsSession.linkFundingSources?.toSortedArray() ?? []

        return LinkURLParams(paymentObject: paymentObjectType,
                             publishableKey: publishableKey,
                             stripeAccount: configuration.apiClient.stripeAccount,
                             paymentUserAgent: PaymentsSDKVariant.paymentUserAgent,
                             merchantInfo: merchantInfo,
                             customerInfo: customerInfo,
                             paymentInfo: paymentInfo,
                             experiments: [:],
                             flags: flags,
                             loggerMetadata: loggerMetadata,
                             locale: Locale.current.toLanguageTag(),
                             intentMode: intentMode,
                             setupFutureUsage: intent.isSettingUp,
                             cardBrandChoice: cardBrandChoiceInfo,
                             linkFundingSources: linkFundingSources)
    }

    static func url(params: LinkURLParams) throws -> URL {
        var components = URLComponents(string: "https://checkout.link.com/")!
        components.fragment = try params.toURLEncodedBase64()
        guard let url = components.url else {
            throw LinkURLGeneratorError.urlCreationFailed
        }
        return url
    }

    static func url(configuration: PaymentSheet.Configuration, intent: Intent, elementsSession: STPElementsSession) throws -> URL {
        let params = try Self.linkParams(configuration: configuration, intent: intent, elementsSession: elementsSession)
        return try url(params: params)
    }
}

// Used to get deterministic ordering for FundingSource tests
extension Set where Element == LinkSettings.FundingSource {
    func toSortedArray() -> [LinkSettings.FundingSource] {
        return self.sorted { a, b in
            a.rawValue.localizedCaseInsensitiveCompare(b.rawValue) == .orderedAscending
        }
    }
}

extension LinkURLParams {
    func toURLEncodedBase64() throws -> String {
        let encoder = JSONEncoder()
        // Sorting makes this a little easier to debug
        encoder.outputFormatting = .sortedKeys
        let encodedData = try encoder.encode(self)
        return encodedData.base64EncodedString()
    }
}

enum LinkURLGeneratorError: Error {
    case urlCreationFailed
    case noPublishableKey
}
