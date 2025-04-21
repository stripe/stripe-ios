//
//  FCLiteImplementation.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-25.
//

@_spi(STP) import StripeCore
import UIKit

/// NOTE: If you change the name of this class, make sure to also change it in the `FinancialConnectionsSDKAvailability` file.
@_spi(STP) public class FCLiteImplementation: FinancialConnectionsSDKInterface {
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
        let returnUrl = returnURL.flatMap(URL.init(string:))

        let fcLite = FinancialConnectionsLite(
            clientSecret: clientSecret,
            returnUrl: returnUrl
        )
        fcLite.elementsSessionContext = elementsSessionContext
        fcLite.present(from: presentingViewController, completion: completion)
    }
}
