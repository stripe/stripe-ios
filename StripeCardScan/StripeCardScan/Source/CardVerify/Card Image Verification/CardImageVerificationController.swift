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

    private let intent: CardImageVerificationIntent
    private let apiClient: STPAPIClient

    init(
        intent: CardImageVerificationIntent,
        apiClient: STPAPIClient
    ) {
        self.intent = intent
        self.apiClient = apiClient
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
            let vc = VerifyCardViewController(expectedCard: expectedCard)
            vc.verifyDelegate = self
            presentingViewController.present(vc, animated: true)
        } else {
            /// Create the view controller for card-add-verification
            let vc = VerifyCardAddViewController()
            vc.verifyDelegate = self
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
extension CardImageVerificationController: VerifyViewControllerDelegate {
    /// User scanned a card successfully. Submit verification frames data to complete verification flow
    func verifyViewControllerDidFinish(_ viewController: UIViewController, verificationFramesData: [VerificationFramesData], scannedCard: ScannedCard) {
        apiClient.submitVerificationFrames(
            cardImageVerificationId: intent.id,
            cardImageVerificationSecret: intent.clientSecret,
            verificationFramesData: verificationFramesData
        ).observe { [weak self] result in
            switch result {
            case .success(_):
                self?.dismissWithResult(viewController, result: .completed(scannedCard: scannedCard))
            case .failure(let error):
                self?.dismissWithResult(viewController, result: .failed(error: error))
            }
        }
    }

    /// User canceled the verification flow
    func verifyViewControllerDidCancel(_ viewController: UIViewController, with reason: CancellationReason) {
        dismissWithResult(viewController, result: .canceled(reason: reason))
    }

    /// Verification flow has failed
    func verifyViewControllerDidFail(_ viewController: UIViewController, with error: Error) {
        dismissWithResult(viewController, result: .failed(error: error))
    }
}
