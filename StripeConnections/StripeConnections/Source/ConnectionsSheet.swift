//
//  ConnectionsSheet.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/10/21.
//

import UIKit
@_spi(STP) import StripeCore

@available(iOS 12, *)
final public class ConnectionsSheet {

    // MARK: - Types

    @frozen public enum ConnectionsResult {
        // User completed the connections session
        case completed(linkedAccounts: [StripeAPI.LinkedAccount])
        // Failed with error
        case failed(error: Error)
        // User canceled out of the connections session
        case canceled
    }

    // MARK: - Properties

    public let linkAccountSessionClientSecret: String

    /// The APIClient instance used to make requests to Stripe
    public var apiClient: STPAPIClient = STPAPIClient.shared

    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((ConnectionsResult) -> Void)?


    // MARK: - Init

    public init(linkAccountSessionClientSecret: String) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
    }

    // MARK: - Public

    public func present(from presentingViewController: UIViewController,
                        completion: @escaping (ConnectionsResult) -> ()) {
        // Overwrite completion closure to retain self until called
        let completion: (ConnectionsResult) -> Void = { result in
            completion(result)
            self.completion = nil
        }
        self.completion = completion

        // Guard against basic user error
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = ConnectionsSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.failed(error: error))
            return
        }
/**
         [
           {
             "id": "la_1K49RtClCIKljWvsA3RK1cYc",
             "object": "linked_account",
             "accountholder": {
               "customer": "cus_KjcgLnPeBXvcyB",
               "type": "customer"
             },
             "balance": null,
             "balance_refresh": null,
             "category": "cash",
             "created": 1638905737,
             "display_name": "Adv Plus Banking",
             "institution_name": "Bank of America",
             "last4": "8551",
             "livemode": true,
             "permissions": [
               "account_numbers",
               "payment_method"
             ],
             "status": "active",
             "subcategory": "checking",
             "supported_payment_method_types": [
               "us_bank_account",
               "link"
             ]
           }
         ]
         */
//
//        let jsonString = """
//                 {
//                   "id": "la_1K49RtClCIKljWvsA3RK1cYc",
//                   "object": "linked_account",
//                   "accountholder": {
//                     "customer": "cus_KjcgLnPeBXvcyB",
//                     "type": "customer"
//                   },
//                   "balance": null,
//                   "balance_refresh": null,
//                   "category": "cash",
//                   "created": 1638905737,
//                   "display_name": "Adv Plus Banking",
//                   "institution_name": "Bank of America",
//                   "last4": "8551",
//                   "livemode": true,
//                   "permissions": [
//                     "account_numbers",
//                     "payment_method"
//                   ],
//                   "status": "active",
//                   "subcategory": "checking",
//                   "supported_payment_method_types": [
//                     "us_bank_account",
//                     "link"
//                   ]
//                 }
//        """
//        let data = jsonString.data(using: .utf8)!
//       do {
//        let responseJson = try JSONDecoder().decode(LinkedAccountResult.self, from: data)
//        print(responseJson)
//       } catch let error {
//        print("ERR PARSING \(error)")
//        }

        let hostViewController = ConnectionsHostViewController(linkAccountSessionClientSecret: linkAccountSessionClientSecret,
                                                               apiClient: apiClient)
        hostViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: hostViewController)
        presentingViewController.present(navigationController, animated: true)
    }
}

// MARK: - ConnectionsHostViewControllerDelegate

@available(iOS 12, *)
extension ConnectionsSheet: ConnectionsHostViewControllerDelegate {
    func connectionsHostViewController(_ viewController: ConnectionsHostViewController, didFinish result: ConnectionsResult) {
        completion?(result)
    }
}
