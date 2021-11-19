//
//  CardImageVerificationSheet.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

/// The result of an attempt to finish an card image verification flow
public enum CardImageVerificationSheetResult {
    /// User completed the verification flow
    case completed(scannedCard: ScannedCard)
    /// User canceled out of the flow
    case canceled(reason: CancellationReason)
    /// Failed with error
    case failed(error: Error)
}

/**
 A drop-in class that presents a sheet for a user to verify their credit card
 */
@available(iOS 11.2, *)
public class CardImageVerificationSheet {
    private let cardImageVerificationIntentId: String
    private let cardImageVerificationIntentSecret: String

    /**
     Initializes an `CardImageVerificationSheet`
     - Parameters:
       - cardImageVerificationIntentId: The id of a Stripe CardImageVerificationIntent object.
       - cardImageVerificationIntentSecret: The client secret of a Stripe CardImageVerificationIntent object.
     */
    // TODO(jaimepark): Add api analytics client as a param when integrating Stripe analytics
    // TODO(jaimepark): Link public documentation for CIV intent when ready
    public init(
        cardImageVerificationIntentId: String,
        cardImageVerificationIntentSecret: String
    ) {
        self.cardImageVerificationIntentId = cardImageVerificationIntentId
        self.cardImageVerificationIntentSecret = cardImageVerificationIntentSecret
    }

    /**
     Presents a sheet for a customer to verify their card.
     - Parameters:
       - presentingViewController: The view controller to present the card image verification sheet.
       - completion: Called with the result of the card image verification flow after the sheet is dismissed.
     */
    public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (CardImageVerificationSheetResult) -> Void
    ) {
        /// Overwrite completion closure to retain self until called
        let completion: (CardImageVerificationSheetResult) -> Void = { result in
            completion(result)
            self.completion = nil
        }
        self.completion = completion

        /// Configure the card image verification controller after retrieving the CIV details
        CardImageVerificationSheet.load(
            civId: cardImageVerificationIntentId,
            civSecret: cardImageVerificationIntentSecret
        ) { result in
            switch result {
            case .success(let expectedCard):
                let cardImageVerificationController = CardImageVerificationController(delegate: self)
                self.verificationController = cardImageVerificationController

                cardImageVerificationController.present(
                    with: expectedCard,
                    from: presentingViewController
                )
            case .failure(let error):
                self.completion?(.failed(error: error))
            }
        }
    }

    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((CardImageVerificationSheetResult) -> Void)?
    private var verificationController: CardImageVerificationController?
}

@available(iOS 11.2, *)
private extension CardImageVerificationSheet {
    typealias Result = Swift.Result

    /// Fetches the CIV optional card details
    static func load(
        civId: String,
        civSecret: String,
        apiClient: STPAPIClient = STPAPIClient.shared,
        completion: @escaping ((Result<CardImageVerificationExpectedCard?, Error>) -> Void)
    ) {
        apiClient.getCardImageVerificationDetails(
            cardImageVerificationSecret: civSecret,
            cardImageVerificationId: civId
        ).chained { response in
            // Transforms response to expectedCard
            return Promise(value: response.expectedCard)
          }.observe { result in
            completion(result)
          }
    }
}

// MARK: Card Image Verification Controller Delegate
@available(iOS 11.2, *)
extension CardImageVerificationSheet: CardImageVerificationControllerDelegate {
    func cardImageVerificationController(
        _ controller: CardImageVerificationController,
        didFinishWithResult result: CardImageVerificationSheetResult
    ) {
        self.completion?(result)
    }
}
