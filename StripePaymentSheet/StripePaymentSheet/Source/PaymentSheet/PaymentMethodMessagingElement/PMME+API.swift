//
//  PMME+API.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/9/25.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

private let pmmeApiEndpoint = URL(string: "https://ppm.stripe.com/config")!

extension PaymentMethodMessagingElement {
    static func get(configuration: Configuration) async throws -> APIResponse {
        guard let publishableKey = configuration.apiClient.publishableKey else {
            throw PaymentMethodMessagingElementError.missingPublishableKey
        }
        // https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/payment_method_messaging/data/parsed_common_request_params_struct.rb
        var parameters: [String: Encodable] = [
            "amount": configuration.amount,
            "currency": configuration.currency,
            // backend accepts locales in the format ab-CD, not ab_CD
            "locale": configuration.locale.replacingOccurrences(of: "_", with: "-"),
            "key": publishableKey,
        ]
        if let countryCode = configuration.countryCode {
            parameters["country"] = countryCode
        }
        if let paymentMethods = configuration.paymentMethodTypes {
            parameters["payment_methods"] = paymentMethods.map { $0.identifier }
        }
        if let stripeAccount = configuration.apiClient.stripeAccount {
            parameters["stripe_account"] = stripeAccount
        }
        return try await withCheckedThrowingContinuation { continuation in
            configuration.apiClient.get(url: pmmeApiEndpoint, parameters: parameters) { (result: Result<APIResponse, Error>) in
                switch result {
                case .success(let apiResponse):
                    continuation.resume(returning: apiResponse)
                case .failure(let error):
                    if let decodingError = error as? DecodingError,
                        case let .keyNotFound(codingKey, context) = decodingError {
                        stpAssertionFailure(context.debugDescription)
                        let problemKey = codingKey.stringValue
                        let problemPath = context.codingPath
                        let fullPath = problemPath.reduce("") { $0 + $1.stringValue + "." } + problemKey
                        let error = PaymentMethodMessagingElementError.unexpectedResponseFromStripeAPI
                        let errorAnalytic = ErrorAnalytic(event: .unexpectedPMMEError, error: error, additionalNonPIIParams: ["missing_response_key": fullPath])
                        STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic, apiClient: configuration.apiClient)
                    }
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension PaymentMethodMessagingElement {

    // https://git.corp.stripe.com/stripe-internal/pay-server/blob/master/lib/payment_method_messaging/api/content_resource.rb
    struct APIResponse: Decodable {

        let content: Content
        let paymentPlanGroups: [PaymentPlanGroup]

        struct Content: Decodable {
            let images: [Image]
            let promotion: Message?
            let inlinePartnerPromotion: Message?
            let learnMore: Message?
        }

        struct Image: Decodable {
            let lightThemePng: IconInfo
            let darkThemePng: IconInfo
            let flatThemePng: IconInfo
            let role: String
            let text: String

            struct IconInfo: Decodable {
                let height: Int
                let url: URL
                let width: Int
            }
        }

        struct Message: Decodable {
            let message: String
            let url: URL?
        }

        struct PaymentPlanGroup: Decodable {
            let content: Content
        }
    }
}
