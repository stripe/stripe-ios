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
        transition(
            apiContent: apiContent,
            sheetController: sheetController
        ) { [weak navigationController] nextViewController in
            navigationController?.setViewControllers([nextViewController], animated: true)
        }
    }

    /// Pushes the next view controller in the flow onto the navigation stack.
    func transitionToNextScreen(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol
    ) {
        transition(
            apiContent: apiContent,
            sheetController: sheetController
        ) { [weak navigationController] nextViewController in
            navigationController?.pushViewController(nextViewController, animated: true)
        }
    }

    /// Checks if the verification session should be submitted and submits before
    /// transitioning to the next screen with the given closure
    func transition(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol,
        transitionNextScreen: @escaping (UIViewController) -> Void
    ) {
        let transition = { [weak self] (updatedAPIContent: VerificationSheetAPIContent) in
            guard let self = self else { return }
            let nextViewController = self.nextViewController(apiContent: apiContent, sheetController: sheetController)
            transitionNextScreen(nextViewController)
        }

        // Check if the user is done entering all the missing fields and we tell
        // the server they're done entering data.
        if VerificationSheetFlowController.shouldSubmit(apiContent: apiContent) {
            // Wait until we're done submitting to see if there's an error response
            sheetController.submit { updatedApiContent in
                transition(updatedApiContent)
            }
        } else {
            transition(apiContent)
        }
    }

    /// Instantiates and returns the next view controller to display in the flow.
    func nextViewController(
        apiContent: VerificationSheetAPIContent,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        nextViewController(
            missingRequirements: apiContent.missingRequirements ?? [],
            staticContent: apiContent.staticContent,
            requiredDataErrors: apiContent.requiredDataErrors,
            isSubmitted: apiContent.submitted ?? false,
            lastError: apiContent.lastError,
            sheetController: sheetController
        )
    }

    func nextViewController(
        missingRequirements: Set<VerificationPageRequirements.Missing>,
        staticContent: VerificationPage?,
        requiredDataErrors: [VerificationSessionDataRequirementError],
        isSubmitted: Bool,
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

        guard let staticContent = staticContent else {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(NSError.stp_genericConnectionError())
            )
        }

        if isSubmitted {
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
            guard let cameraFeed = sheetController.mockCameraFeed else {
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
        }

        // TODO(mludowise|IDPROD-2816): Display a different error message and
        // log an analytic since this is an unrecoverable state that means we've
        // sent a configuration from the server that the client can't handle.
        return ErrorViewController(
            sheetController: sheetController,
            error: .error(NSError.stp_genericConnectionError())
        )
    }

    /// Returns true if the user has finished filling out the required fields and the VerificationSession is ready to be submitted
    static func shouldSubmit(apiContent: VerificationSheetAPIContent) -> Bool {
        guard let missingRequirements = apiContent.missingRequirements,
              let isSubmitted = apiContent.submitted,
              apiContent.lastError == nil && apiContent.requiredDataErrors.isEmpty else {
            return false
        }
        return missingRequirements.isEmpty && !isSubmitted
    }
}
