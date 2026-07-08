//
//  FCLiteImplementation.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-03-25.
//

@_spi(STP) import StripeCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#else
import Foundation
#endif

#if canImport(UIKit)
public typealias FCLitePresentingViewController = UIViewController
#elseif canImport(AppKit)
public typealias FCLitePresentingViewController = NSViewController
#endif

/// NOTE: If you change the name of this class, make sure to also change it in the `FinancialConnectionsSDKAvailability` file.
@_spi(STP) public class FCLiteImplementation: FinancialConnectionsSDKInterface {
    required public init() {}

    public func presentFinancialConnectionsSheet(
        apiClient: STPAPIClient,
        clientSecret: String,
        returnURL: String?,
        existingConsumer: FinancialConnectionsConsumer?,
        style: FinancialConnectionsStyle,
        elementsSessionContext: ElementsSessionContext?,
        linkBrand: LinkBrand?,
        onEvent: ((FinancialConnectionsEvent) -> Void)?,
        from presentingViewController: FCLitePresentingViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    ) {
        let returnUrl = returnURL.flatMap(URL.init(string:))

        let fcLite = FinancialConnectionsLite(
            clientSecret: clientSecret,
            returnUrl: returnUrl
        )
        fcLite.elementsSessionContext = elementsSessionContext
        fcLite.existingConsumer = existingConsumer
        #if canImport(UIKit)
        fcLite.present(from: presentingViewController, completion: completion)
        #else
        let presentingViewController = presentingViewController as? UIViewController ?? UIViewController(nibName: nil, bundle: nil)
        fcLite.present(from: presentingViewController, completion: completion)
        #endif
    }
}
