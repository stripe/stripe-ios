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
@frozen public enum CardImageVerificationSheetResult {
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
final public class CardImageVerificationSheet {
    /**
     Initializes an `CardImageVerificationSheet`
     - Parameters:
       - cardImageVerificationIntentId: The id of a Stripe CardImageVerificationIntent object.
       - cardImageVerificationIntentSecret: The client secret of a Stripe CardImageVerificationIntent object.
     */
    public init(
        cardImageVerificationIntentId: String,
        cardImageVerificationIntentSecret: String,
        configuration: Configuration = Configuration()
    ) {
        // TODO(jaimepark): Add api analytics client as a param when integrating Stripe analytics
        // TODO(jaimepark): Link public documentation for CIV intent when ready
        self.configuration = configuration
        self.intent = CardImageVerificationIntent(id: cardImageVerificationIntentId, clientSecret: cardImageVerificationIntentSecret)
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
        load(
            civId: intent.id,
            civSecret: intent.clientSecret
        ) { result in
            switch result {
            case .success(let expectedCard):
                /// Initialize the civ controller
                let cardImageVerificationController =
                    CardImageVerificationController(
                        intent: self.intent,
                        configuration: self.configuration
                    )
                cardImageVerificationController.delegate = self
                /// Keep reference to the civ controller
                self.verificationController = cardImageVerificationController

                /// Present the verify view controller
                cardImageVerificationController.present(
                    with: expectedCard,
                    from: presentingViewController
                )
            case .failure(let error):
                self.completion?(.failed(error: error))
            }
        }
    }


    private let configuration: Configuration
    private let intent: CardImageVerificationIntent
    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((CardImageVerificationSheetResult) -> Void)?
    private var verificationController: CardImageVerificationController?
}

private extension CardImageVerificationSheet {
    typealias Result = Swift.Result

    /// Fetches the CIV optional card details
    func load(
        civId: String,
        civSecret: String,
        completion: @escaping ((Result<CardImageVerificationExpectedCard?, Error>) -> Void)
    ) {
        configuration.apiClient.fetchCardImageVerificationDetails(
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
extension CardImageVerificationSheet: CardImageVerificationControllerDelegate {
    func cardImageVerificationController(
        _ controller: CardImageVerificationController,
        didFinishWithResult result: CardImageVerificationSheetResult
    ) {
        self.completion?(result)
    }
}
