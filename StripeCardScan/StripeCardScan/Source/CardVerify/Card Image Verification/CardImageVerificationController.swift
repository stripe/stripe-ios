//
//  CardImageVerificationController.swift
//  StripeCardScan
//
//  Created by Jaime Park on 11/17/21.
//

import Foundation
@_spi(STP) import StripeCore
import UIKit

@available(iOS 11.2, *)
protocol CardImageVerificationControllerDelegate: AnyObject {
    func cardImageVerificationController(_ controller: CardImageVerificationController,
                                         didFinishWithResult result: CardImageVerificationSheetResult)
}

@available(iOS 11.2, *)
class CardImageVerificationController {
    weak var delegate: CardImageVerificationControllerDelegate?

    init(delegate: CardImageVerificationControllerDelegate) {
        self.delegate = delegate
    }

    func present(
        with expectedCard: CardImageVerificationExpectedCard?,
        from presentingViewController: UIViewController
    ) {
        /// Guard against basic user error
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = CardImageVerificationSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            self.delegate?.cardImageVerificationController(self, didFinishWithResult: .failed(error: error))
            return
        }

        if let expectedCard = expectedCard {
            /// Create the view controller for card-set-verification with expected card's last4 and issuer
            let vc = VerifyCardViewController(userId: nil, lastFour: expectedCard.last4, bin: nil, cardNetwork: nil)
            vc.verifyCardDelegate = self
            presentingViewController.present(vc, animated: true)
        } else {
            /// Create the view controller for card-add-verification
            let vc = VerifyCardAddViewController(userId: "")
            vc.cardAddDelegate = self
            presentingViewController.present(vc, animated: true)
        }
    }

    func dismissWithResult(
        _ presentingViewController: UIViewController,
        result: CardImageVerificationSheetResult
    ) {
        presentingViewController.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.cardImageVerificationController(self, didFinishWithResult: result)
        }
    }
}

// MARK: Verify Card Add Delegate
@available(iOS 11.2, *)
extension CardImageVerificationController: VerifyCardAddResult {
    /// User pressed back/cancel button to terminate the card-add-verification flow
    func userDidCancelCardAdd(_ viewController: UIViewController) {
        dismissWithResult(viewController, result: .canceled(reason: .back))
    }

    /// User scanned a card successfully
    func userDidScanCardAdd(_ viewController: UIViewController, creditCard: CreditCard) {
        dismissWithResult(viewController, result: .completed(scannedCard: ScannedCard(pan: creditCard.number)))
    }

    /// User pressed `manual entry` button for adding payment without scanning
    func userDidPressManualCardAdd(_ viewController: UIViewController) {
        dismissWithResult(viewController, result: .canceled(reason: .closed))
    }
}

// MARK: Verify Card Delegate
@available(iOS 11.2, *)
extension CardImageVerificationController: VerifyCardResult {
    /// User pressed back/cancel button to terminate the card-set-verification flow
    func userCanceledVerifyCard(viewController: VerifyCardViewController) {
        dismissWithResult(viewController, result: .canceled(reason: .back))
    }

    /// User scanned a card successfully
    func fraudModelResultsVerifyCard(viewController: VerifyCardViewController, creditCard: CreditCard, extraData: [String : Any]) {
        dismissWithResult(viewController, result: .completed(scannedCard: ScannedCard(pan: creditCard.number)))
    }
}
