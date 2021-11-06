//
//  VerificationSheetFlowController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//

import UIKit
@_spi(STP) import StripeCore

final class VerificationSheetFlowController {

    private(set) lazy var navigationController: UINavigationController = {
        return UINavigationController(rootViewController: LoadingViewController())
    }()

    /// Replaces the current view controller stack with the next view controller in the flow.
    func transitionToFirstScreen(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetController
    ) {
        let nextViewController = nextViewController(apiContent: apiContent, sheetController: sheetController)
        navigationController.setViewControllers([nextViewController], animated: true)
    }

    /// Pushes the next view controller in the flow onto the navigation stack.
    func transitionToNextScreen(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetController
    ) {
        let nextScreen = nextViewController(apiContent: apiContent, sheetController: sheetController)
        navigationController.pushViewController(nextScreen, animated: true)
    }

    /// Instantiates and returns the next view controller to display in the flow.
    func nextViewController(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetController
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
        sheetController: VerificationSheetController
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
        // } else if missingRequirements.contains(.idDocumentType) {
            // TODO(IDPROD-2740): Return document selection VC
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
