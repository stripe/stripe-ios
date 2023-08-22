//
//  ServerErrorMapper.swift
//  StripeCore
//
//  Created by Nick Porter on 9/13/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

private enum ServerErrorPrefixes: String, CaseIterable {
    case missingPublishableKey = "You did not provide an API key."
    case invalidApiKey = "Invalid API Key provided"
    case mismatchPublishableKey =
        "The client_secret provided does not match the client_secret associated with"
    case noSuchPaymentIntent = "No such payment_intent"
    case noSuchSetupIntent = "No such setup_intent"

    /// Maps the corresponding `ServerErrorMapper` to a `MobileErrorMessage`.
    ///
    /// - Parameters:
    ///   - serverErrorMessage: the raw server error message from the server.
    ///   - httpResponse: the http response for the error.
    /// - Returns: a `MobileErrorMessage` that maps to this `ServerErrorPrefixes`.
    func mobileError(
        from serverErrorMessage: String,
        httpResponse: HTTPURLResponse
    ) -> MobileErrorMessage {
        switch self {
        case .missingPublishableKey:
            return MobileErrorMessage.missingPublishableKey
        case .invalidApiKey:
            if httpResponse.url?.absoluteString.hasPrefix(
                "https://api.stripe.com/v1/payment_methods?customer="
            ) ?? false {
                // User didn't set ephemeral key correctly
                return MobileErrorMessage.invalidCustomerEphKey
            } else {
                // User didn't set publishable key correctly
                return MobileErrorMessage.missingPublishableKey
            }
        case .mismatchPublishableKey:
            return MobileErrorMessage.mismatchPublishableKey
        case .noSuchPaymentIntent:
            return MobileErrorMessage.noSuchPaymentIntent
        case .noSuchSetupIntent:
            return MobileErrorMessage.noSuchSetupIntent
        }
    }
}

/// List of mobile friendly error messages for common upstream server errors.
private enum MobileErrorMessage: String {
    case missingPublishableKey =
        "No valid API key provided. Set `STPAPIClient.shared.publishableKey` to your publishable key, which you can find here: https://stripe.com/docs/keys"

    case invalidCustomerEphKey =
        "Invalid customer ephemeral key secret. You can find more information at https://stripe.com/docs/payments/accept-a-payment?platform=ios#add-server-endpoint"

    case mismatchPublishableKey =
        "The publishable key provided does not match the publishable key associated with the PaymentIntent/SetupIntent. This is most likley caused by using a different publishable key in `STPAPIClient.shared.publishableKey` than what your server is using."

    case noSuchPaymentIntent =
        "No matching PaymentIntent could be found. Ensure you are creating a PaymentIntent server side and using the same publishable key on both client and server. You can find more information at https://stripe.com/docs/api/payment_intents/create"

    case noSuchSetupIntent =
        "No matching SetupIntent could be found. Ensure you are creating a SetupIntent server side and using the same publishable key on both client and server. You can find more information at https://stripe.com/docs/api/setup_intents/create"
}

/// Maps known server error message to mobile friendly versions.
struct ServerErrorMapper {

    /// Maps common server error messages to a mobile friendly equivalent if known,
    /// otherwise defaults to the server error message.
    ///
    /// - Parameters:
    ///   - serverErrorMessage: the error message returned from the server.
    ///   - httpResponse: the http response for this error.
    /// - Returns: a mobile friendly error message if known,
    ///   otherwise defaults the error message from the server.
    static func mobileErrorMessage(
        from serverErrorMessage: String,
        httpResponse: HTTPURLResponse?
    ) -> String? {
        guard let httpResponse = httpResponse else {
            return nil
        }

        let serverError = ServerErrorPrefixes.allCases.first(where: {
            serverErrorMessage.hasPrefix($0.rawValue)
        })
        return serverError?.mobileError(from: serverErrorMessage, httpResponse: httpResponse)
            .rawValue
    }
}
