//
//  CardScanSheet.swift
//  StripeCardScan
//
//  Created by Scott Grant on 6/3/22.
//

import Foundation
import UIKit

/// The result of an attempt to scan a card
@frozen public enum CardScanSheetResult {
    /// The customer completed the scan
    case completed(card: ScannedCard)

    /// The customer canceled the scan
    case canceled

    /// The attempt failed.
    /// - Parameter error: The error encountered by the customer. You can display its `localizedDescription` to the customer.
    case failed(error: Error)
}

/// A drop-in class that presents a sheet for a customer to scan their card
public class CardScanSheet {

    public init() {}

    /// Presents a sheet for a customer to scan their card
    /// - Parameter presentingViewController: The view controller to present a card scan sheet
    /// - Parameter completion: Called with the result of the scan after the card scan sheet is dismissed
            public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (CardScanSheetResult) -> Void,
        animated: Bool = true
    ) {
        // Guard against basic user error
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = CardScanSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.failed(error: error))
            return
        }

        let vc = SimpleScanViewController()
        vc.delegate = self

        // Overwrite completion closure to retain self until called
        let overwrittenCompletion: (CardScanSheetResult) -> Void = { status in
            // Dismiss if necessary
            if vc.presentingViewController != nil {
                vc.dismiss(animated: true) {
                    completion(status)
                }
            } else {
                completion(status)
            }
            self.completion = nil
        }
        self.completion = overwrittenCompletion

        presentingViewController.present(vc, animated: animated)
    }

    // MARK: - Internal Properties

    /// A user-supplied completion block. Nil until `present` is called.
    var completion: ((CardScanSheetResult) -> Void)?
}

extension CardScanSheet: SimpleScanDelegate {
    func userDidCancelSimple(_ scanViewController: SimpleScanViewController) {
        completion?(.canceled)
    }

    func userDidScanCardSimple(
        _ scanViewController: SimpleScanViewController,
        creditCard: CreditCard
    ) {
        let scannedCard = ScannedCard(scannedCard: creditCard)

        completion?(.completed(card: scannedCard))
    }
}
