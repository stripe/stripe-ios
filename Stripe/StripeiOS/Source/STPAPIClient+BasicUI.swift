//
//  STPAPIClient+BasicUI.swift
//  StripeiOS
//
//  Created by David Estes on 6/30/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// A client for making connections to the Stripe API.
extension STPAPIClient {
    /// Initializes an API client with the given configuration.
    /// - Parameter configuration: The configuration to use.
    /// - Returns: An instance of STPAPIClient.
    @available(
        *,
        deprecated,
        message:
            "This initializer previously configured publishableKey and stripeAccount via the STPPaymentConfiguration instance. This behavior is deprecated; set the STPAPIClient configuration, publishableKey, and stripeAccount properties directly on the STPAPIClient instead."
    )
    public convenience init(
        configuration: STPPaymentConfiguration
    ) {
        // For legacy reasons, we'll support this initializer and use the deprecated configuration.{publishableKey, stripeAccount} properties
        self.init()
        publishableKey = configuration.publishableKey
        stripeAccount = configuration.stripeAccount
    }
}

extension STPAPIClient {
    /// The client's configuration.
    /// Defaults to `STPPaymentConfiguration.shared`.
    @objc public var configuration: STPPaymentConfiguration {
        get {
            if let config = _stored_configuration as? STPPaymentConfiguration {
                return config
            } else {
                return .shared
            }
        }
        set {
            _stored_configuration = newValue
        }
    }


    // MARK: FPX
    /// Retrieves the online status of the FPX banks from the Stripe API.
    /// - Parameter completion:  The callback to run with the returned FPX bank list, or an error.
    func retrieveFPXBankStatus(
        withCompletion completion: @escaping STPFPXBankStatusCompletionBlock
    ) {
        APIRequest<STPFPXBankStatusResponse>.getWith(
            self,
            endpoint: APIEndpointFPXStatus,
            parameters: [
                "account_holder_type": "individual"
            ]
        ) { statusResponse, _, error in
            completion(statusResponse, error)
        }
    }

}

private let APIEndpointFPXStatus = "fpx/bank_statuses"
