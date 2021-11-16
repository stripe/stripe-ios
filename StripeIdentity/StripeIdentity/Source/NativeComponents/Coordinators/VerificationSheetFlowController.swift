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

enum VerificationSheetFlowControllerError: Error, Equatable {
    case missingRequiredInput([VerificationPageRequirements.Missing])

    var localizedDescription: String {
        // TODO(mludowise|IDPROD-2816): Display a different error message since this is an unrecoverable state
        return NSError.stp_unexpectedErrorMessage()
    }
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

            // TODO(IDPROD-2745): Uncomment and update VC with API response
            
            // } else if !missingRequirements.intersection([.address, .dob, .email, .idNumber, .name, .phoneNumber]).isEmpty {
            // return IndividualViewController(
            //     sheetController: sheetController
            // )
        } else if !missingRequirements.intersection([.idDocumentFront, .idDocumentBack]).isEmpty {

            // Show error if we haven't collected document type
            guard let documentType = sheetController.dataStore.idDocumentType else {
                // TODO(mludowise|IDPROD-2816): Log an analytic since this is an
                // unrecoverable state that means we've sent a configuration
                // from the server that the client can't handle.
                return ErrorViewController(
                    sheetController: sheetController,
                    error: .error(VerificationSheetFlowControllerError.missingRequiredInput([.idDocumentType]))
                )
            }
            
            // TODO(mludowise|IDPROD-2774): Remove dependency on mockCameraFeed
            guard let cameraFeed = (sheetController as? VerificationSheetController)?.mockCameraFeed else {
                return ErrorViewController(
                    sheetController: sheetController,
                    error: .error(NSError.stp_genericConnectionError())
                )
            }

            return DocumentCaptureViewController(
                sheetController: sheetController,
                cameraFeed: cameraFeed,
                documentType: documentType
            )
        } else if missingRequirements.contains(.face) {
            // TODO(IDPROD-2758): Return selfie VC
        }

        // TODO(mludowise|IDPROD-2816): Display a different error message and
        // log an analytic since this is an unrecoverable state that means we've
        // sent a configuration from the server that the client can't handle.
        return ErrorViewController(
            sheetController: sheetController,
            error: .error(NSError.stp_genericFailedToParseResponseError())
        )
    }
}
