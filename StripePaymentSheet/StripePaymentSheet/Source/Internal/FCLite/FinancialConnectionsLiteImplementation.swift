//
//  FinancialConnectionsLiteImplementation.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-13.
//

@_spi(STP) import StripeCore
import UIKit

/// NOTE: If you change the name of this class, make sure to also change it `FinancialConnectionsSDKAvailability` file.
@_spi(STP) public class FinancialConnectionsLiteImplementation: FinancialConnectionsSDKInterface {
    required public init() {}

    public func presentFinancialConnectionsSheet(
        apiClient: STPAPIClient,
        clientSecret: String,
        returnURL: String?,
        style: FinancialConnectionsStyle,
        elementsSessionContext: ElementsSessionContext?,
        onEvent: ((FinancialConnectionsEvent) -> Void)?,
        from presentingViewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    ) {
        guard let returnUrlString = returnURL, let returnUrl = URL(string: returnUrlString) else {
            completion(.failed(error: FCLiteError.missingReturnUrl))
            return
        }

        let fcLite = FinancialConnectionsLite(clientSecret: clientSecret, returnUrl: returnUrl)
        fcLite.present(from: presentingViewController, completion: completion)
    }
}
