//
//  VerificationSheetFlowController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//

import UIKit
@_spi(STP) import StripeCore

protocol VerificationSheetFlowControllerProtocol {
    var navigationController: UINavigationController { get }

    func transitionToFirstScreen(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol
    )

    func transitionToNextScreen(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol
    )
}

final class VerificationSheetFlowController: VerificationSheetFlowControllerProtocol {

    private(set) lazy var navigationController: UINavigationController = {
        return UINavigationController(rootViewController: LoadingViewController())
    }()

    /// Replaces the current view controller stack with the next view controller in the flow.
    func transitionToFirstScreen(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol
    ) {
        let nextViewController = self.nextViewController(apiContent: apiContent, sheetController: sheetController)
        navigationController.setViewControllers([nextViewController], animated: true)
    }

    /// Pushes the next view controller in the flow onto the navigation stack.
    func transitionToNextScreen(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol
    ) {
        let nextScreen = nextViewController(apiContent: apiContent, sheetController: sheetController)
        navigationController.pushViewController(nextScreen, animated: true)
    }

    /// Instantiates and returns the next view controller to display in the flow.
    func nextViewController(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        nextViewController(
            missingRequirements: apiContent.missingRequirements,
            staticContent: apiContent.staticContent,
            requiredDataErrors: apiContent.requiredDataErrors,
            lastError: apiContent.lastError,
            sheetController: sheetController
        )
    }

    func nextViewController(
        missingRequirements: Set<VerificationPageRequirements.Missing>?,
        staticContent: VerificationPage?,
        requiredDataErrors: [VerificationSessionDataRequirementError],
        lastError: Error?,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        if let lastError = lastError {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(lastError)
            )
        }

        if let inputError = requiredDataErrors.first {
            return ErrorViewController(
                sheetController: sheetController,
                error: .inputError(inputError)
            )
        }

        guard let missingRequirements = missingRequirements,
              let staticContent = staticContent else {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(NSError.stp_genericConnectionError())
            )
        }

        if missingRequirements.isEmpty {
            // TODO(IDPROD-2759): Return success screen
            return LoadingViewController()
        } else if missingRequirements.contains(.biometricConsent) {
            return BiometricConsentViewController(
                sheetController: sheetController,
                consentContent: staticContent.biometricConsent
            )
         } else if missingRequirements.contains(.idDocumentType) {
             return DocumentTypeSelectViewController(
                sheetController: sheetController,
                staticContent: staticContent.documentSelect
             )
        } else if !missingRequirements.intersection([.address, .dob, .email, .idNumber, .name, .phoneNumber]).isEmpty {
            // TODO(IDPROD-2745): Update VC with API response
            return IndividualViewController(
                sheetController: sheetController
            )
        } else if !missingRequirements.intersection([.idDocumentFront, .idDocumentBack]).isEmpty {
            // TODO(IDPROD-2756): Return document scan VC
        } else if missingRequirements.contains(.face) {
            // TODO(IDPROD-2758): Return selfie VC
        }

        return ErrorViewController(
            sheetController: sheetController,
            error: .error(NSError.stp_genericFailedToParseResponseError())
        )
    }
}
