//
//  VerificationSheetFlowController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore

protocol VerificationSheetFlowControllerDelegate: AnyObject {
    /// Invoked when the user has dismissed the navigation controller
    func verificationSheetFlowControllerDidDismiss(_ flowController: VerificationSheetFlowControllerProtocol)
}

protocol VerificationSheetFlowControllerProtocol: AnyObject {
    var delegate: VerificationSheetFlowControllerDelegate? { get set }

    var navigationController: UINavigationController { get }

    func transitionToNextScreen(
        staticContentResult: Result<VerificationPage, Error>,
        updateDataResult: Result<VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping () -> Void
    )

    func replaceCurrentScreen(
        with viewController: UIViewController
    )

    func canPopToScreen(withField field: VerificationPageFieldType) -> Bool

    func popToScreen(
        withField field: VerificationPageFieldType,
        shouldResetViewController: Bool
    )

    var uncollectedFields: Set<VerificationPageFieldType> { get }
    func isFinishedCollectingData(for verificationPage: VerificationPage) -> Bool
}

enum VerificationSheetFlowControllerError: Error, Equatable, LocalizedError {
    case missingRequiredInput(Set<VerificationPageFieldType>)

    var localizedDescription: String {
        // TODO(mludowise|IDPROD-2816): Display a different error message since this is an unrecoverable state
        return NSError.stp_unexpectedErrorMessage()
    }
}

@available(iOS 13, *)
final class VerificationSheetFlowController {

    let brandLogo: UIImage

    var delegate: VerificationSheetFlowControllerDelegate?

    init(brandLogo: UIImage) {
        self.brandLogo = brandLogo
    }

    private(set) lazy var navigationController: UINavigationController = {
        let navigationController = IdentityFlowNavigationController(rootViewController: LoadingViewController())
        navigationController.identityDelegate = self
        return navigationController
    }()
}

@available(iOS 13, *)
@available(iOSApplicationExtension, unavailable)
extension VerificationSheetFlowController: VerificationSheetFlowControllerProtocol {
    /// Transitions to the next view controller in the flow with a 'push' animation.
    /// - Note: This may replace the navigation stack or push an additional view
    ///   controller onto the stack, depending on whether on where the user is in the flow.
    func transitionToNextScreen(
        staticContentResult: Result<VerificationPage, Error>,
        updateDataResult: Result<VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping () -> Void
    ) {
        nextViewController(
            staticContentResult: staticContentResult,
            updateDataResult: updateDataResult,
            sheetController: sheetController
        ) { [weak self] viewController in
            self?.transition(
                to: viewController,
                shouldAnimate: true,
                completion: completion
            )
        }
    }

    /// Transitions to the given viewController by replacing the currently displayed view controller
    func replaceCurrentScreen(
        with newViewController: UIViewController
    ) {
        var viewControllers = navigationController.viewControllers
        viewControllers.removeLast()
        viewControllers.append(newViewController)
        navigationController.setViewControllers(viewControllers, animated: true)
    }

    func canPopToScreen(withField field: VerificationPageFieldType) -> Bool {
        return collectedFields.contains(field)
    }

    func popToScreen(
        withField field: VerificationPageFieldType,
        shouldResetViewController: Bool
    ) {
        popToScreen(
            withField: field,
            shouldResetViewController: shouldResetViewController,
            animated: true
        )
    }

    func popToScreen(
        withField field: VerificationPageFieldType,
        shouldResetViewController: Bool,
        animated: Bool
    ) {
        guard let index = navigationController.viewControllers.lastIndex(where: { ($0 as? IdentityDataCollecting)?.collectedFields.contains(field) == true }) else {
            return
        }

        let viewControllers = Array(navigationController.viewControllers.dropLast(navigationController.viewControllers.count - index - 1))

        if shouldResetViewController {
            (viewControllers[index] as? IdentityDataCollecting)?.reset()
        }

        navigationController.setViewControllers(viewControllers, animated: animated)
    }

    // MARK: - Helpers

    /// - Note: This method should not be called directly from outside of this class except for tests
    func transition(
        to nextViewController: UIViewController,
        shouldAnimate: Bool,
        completion: @escaping () -> Void
    ) {
        // If the only view in the stack is a loading screen, they should not be
        // able to hit the back button to get back into a loading state.
        let isInitialLoadingState = navigationController.viewControllers.count == 1
            && navigationController.viewControllers.first is LoadingViewController

        // If the user is seeing the success screen, it means their session has
        // been submitted and they can't go back to edit their input.
        let isSuccessState = nextViewController is SuccessViewController

        // Don't display a back button, so replace the navigation stack
        if isInitialLoadingState || isSuccessState {
            navigationController.setViewControllers([nextViewController], animated: shouldAnimate)
        } else {
            navigationController.pushViewController(nextViewController, animated: shouldAnimate)
        }

        // Call completion block after navigation controller animation, if possible
        guard shouldAnimate,
              let coordinator = navigationController.transitionCoordinator
        else {
            DispatchQueue.main.async {
                completion()
            }
            return
        }

        coordinator.animate(alongsideTransition: nil, completion: { _ in completion() })
    }

    /// Instantiates and returns the next view controller to display in the flow.
    /// - Note: This method should not be called directly from outside of this class except for tests
    func nextViewController(
        staticContentResult: Result<VerificationPage, Error>,
        updateDataResult: Result<VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping (UIViewController) -> Void
    ) {
        // Check for API Errors
        let staticContent: VerificationPage
        let updateDataResponse: VerificationPageData?
        do {
            staticContent = try staticContentResult.get()
            updateDataResponse = try updateDataResult?.get()
        } catch {
            return completion(ErrorViewController(
                sheetController: sheetController,
                error: .error(error)
            ))
        }

        // Check for validation errors
        if let inputError = updateDataResponse?.requirements.errors.first {
            return completion(ErrorViewController(
                sheetController: sheetController,
                error: .inputError(inputError)
            ))
        }

        // Determine which required fields we haven't collected data for yet
        let missingRequirements = self.missingRequirements(for: staticContent)

        // Show success screen if submitted
        if updateDataResponse?.submitted == true {
            return completion(SuccessViewController(
                successContent: staticContent.success,
                sheetController: sheetController
            ))
        } else if missingRequirements.contains(.biometricConsent) {
            return completion(makeBiometricConsentViewController(
                staticContent: staticContent,
                sheetController: sheetController
            ))
        } else if missingRequirements.contains(.idDocumentType) {
            return completion(makeDocumentTypeSelectViewController(
                sheetController: sheetController,
                staticContent: staticContent
            ))
        } else if !missingRequirements.intersection([.idDocumentFront, .idDocumentBack]).isEmpty {
            return sheetController.mlModelLoader.documentModelsFuture.observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                completion(self.makeDocumentCaptureViewController(
                    documentScannerResult: result,
                    staticContent: staticContent,
                    sheetController: sheetController
                ))
            }
        }

        // TODO(mludowise|IDPROD-2816): Display a different error message and
        // log an analytic since this is an unrecoverable state that means we've
        // sent a configuration from the server that the client can't handle.
        return completion(ErrorViewController(
            sheetController: sheetController,
            error: .error(NSError.stp_genericConnectionError())
        ))
    }

    func makeBiometricConsentViewController(
        staticContent: VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        do {
            return try BiometricConsentViewController(
                brandLogo: brandLogo,
                consentContent: staticContent.biometricConsent,
                sheetController: sheetController
            )
        } catch {
            // TODO(mludowise|IDPROD-2816): Display a different error message and
            // log an analytic since this is an unrecoverable state that means we've
            // sent a configuration from the server that the client can't handle.
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(NSError.stp_genericConnectionError())
            )
        }
    }

    func makeDocumentTypeSelectViewController(
        sheetController: VerificationSheetControllerProtocol,
        staticContent: VerificationPage
    ) -> UIViewController {
        do {
            return try DocumentTypeSelectViewController(
                sheetController: sheetController,
                staticContent: staticContent.documentSelect
            )
        } catch {
            // TODO(mludowise|IDPROD-2816): Display a different error message and
            // log an analytic since this is an unrecoverable state that means we've
            // sent a configuration from the server that the client can't handle.
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(NSError.stp_genericFailedToParseResponseError())
            )
        }
    }

    func makeDocumentCaptureViewController(
        documentScannerResult: Result<DocumentScannerProtocol, Error>,
        staticContent: VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        // Show error if we haven't collected document type
        guard let documentType = sheetController.collectedData.idDocumentType else {
            // TODO(mludowise|IDPROD-2816): Log an analytic since this is an
            // unrecoverable state that means we've sent a configuration
            // from the server that the client can't handle.
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(VerificationSheetFlowControllerError.missingRequiredInput([.idDocumentType]))
            )
        }

        let documentUploader = DocumentUploader(
            configuration: .init(from: staticContent.documentCapture),
            apiClient: sheetController.apiClient
        )

        switch documentScannerResult {
        case .failure:
            // TODO(mludowise|IDPROD-2816): Log an analytic since this means the
            // ML models cannot be loaded.

            // Return document upload screen if we can't load models for auto-capture
            return DocumentFileUploadViewController(
                documentType: documentType,
                requireLiveCapture: staticContent.documentCapture.requireLiveCapture,
                sheetController: sheetController,
                documentUploader: documentUploader
            )

        case .success(let documentScanner):
            return DocumentCaptureViewController(
                apiConfig: staticContent.documentCapture,
                documentType: documentType,
                sheetController: sheetController,
                cameraSession: makeDocumentCaptureCameraSession(),
                documentUploader: documentUploader,
                documentScanner: documentScanner
            )
        }
    }

    private func makeDocumentCaptureCameraSession() -> CameraSessionProtocol {
        #if targetEnvironment(simulator)
            return MockSimulatorCameraSession(images: IdentityVerificationSheet.simulatorDocumentCameraImages)
        #else
            return CameraSession()
        #endif
    }

    // MARK: - Collected Fields

    /// Set of fields the view controllers in the navigation stack are collecting from the user
    var collectedFields: Set<VerificationPageFieldType> {
        return navigationController.viewControllers.reduce(Set<VerificationPageFieldType>()) { partialResult, vc in
            guard let dataCollectingVC = vc as? IdentityDataCollecting else {
                return partialResult
            }
            return partialResult.union(dataCollectingVC.collectedFields)
        }
    }

    /// Set of fields not collected by any of the view controllers in the navigation stack
    var uncollectedFields: Set<VerificationPageFieldType> {
        return Set(VerificationPageFieldType.allCases).subtracting(collectedFields)
    }

    func missingRequirements(for verificationPage: VerificationPage) -> Set<VerificationPageFieldType> {
        verificationPage.requirements.missing.subtracting(collectedFields)
    }

    func isFinishedCollectingData(for verificationPage: VerificationPage) -> Bool {
        return missingRequirements(for: verificationPage).isEmpty
    }
}

// MARK: - IdentityFlowNavigationControllerDelegate

@available(iOS 13, *)
extension VerificationSheetFlowController: IdentityFlowNavigationControllerDelegate {
    func identityFlowNavigationControllerDidDismiss(_ navigationController: IdentityFlowNavigationController) {
        delegate?.verificationSheetFlowControllerDidDismiss(self)
    }
}
