//
//  VerificationSheetFlowController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//

import UIKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeCameraCore
import SafariServices

protocol VerificationSheetFlowControllerDelegate: AnyObject {
    /// Invoked when the user has dismissed the navigation controller
    func verificationSheetFlowControllerDidDismissNativeView(_ flowController: VerificationSheetFlowControllerProtocol)

    func verificationSheetFlowControllerDidDismissWebView(_ flowController: VerificationSheetFlowControllerProtocol)
}

protocol VerificationSheetFlowControllerProtocol: AnyObject {
    var delegate: VerificationSheetFlowControllerDelegate? { get set }

    var navigationController: UINavigationController { get }

    func transitionToNextScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping () -> Void
    )

    func replaceCurrentScreen(
        with viewController: UIViewController
    )

    func canPopToScreen(withField field: StripeAPI.VerificationPageFieldType) -> Bool

    func popToScreen(
        withField field: StripeAPI.VerificationPageFieldType,
        shouldResetViewController: Bool
    )

    var uncollectedFields: Set<StripeAPI.VerificationPageFieldType> { get }
    func isFinishedCollectingData(for verificationPage: StripeAPI.VerificationPage) -> Bool

    var analyticsLastScreen: IdentityFlowViewController? { get }
}

@available(iOS 13, *)
@objc(STP_Internal_VerificationSheetFlowController)
final class VerificationSheetFlowController: NSObject {

    let brandLogo: UIImage

    var delegate: VerificationSheetFlowControllerDelegate?

    private(set) var isUsingWebView = false

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
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
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

    func canPopToScreen(withField field: StripeAPI.VerificationPageFieldType) -> Bool {
        return collectedFields.contains(field)
    }

    func popToScreen(
        withField field: StripeAPI.VerificationPageFieldType,
        shouldResetViewController: Bool
    ) {
        popToScreen(
            withField: field,
            shouldResetViewController: shouldResetViewController,
            animated: true
        )
    }

    func popToScreen(
        withField field: StripeAPI.VerificationPageFieldType,
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
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping (UIViewController) -> Void
    ) {
        // Check for API Errors
        let staticContent: StripeAPI.VerificationPage
        let updateDataResponse: StripeAPI.VerificationPageData?
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

        // If client is unsupported, fallback to web
        if staticContent.unsupportedClient {
            isUsingWebView = true
            return completion(makeWebViewController(
                staticContent: staticContent,
                sheetController: sheetController
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
        } else if missingRequirements.contains(.face) {
            return sheetController.mlModelLoader.faceModelsFuture.observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                completion(self.makeSelfieCaptureViewController(
                    faceScannerResult: result,
                    staticContent: staticContent,
                    sheetController: sheetController
                ))
            }
        }

        // The client cannot create a screen for the missing requirement
        return completion(ErrorViewController(
            sheetController: sheetController,
            error: .error(
                VerificationSheetFlowControllerError.noScreenForRequirements(missingRequirements)
            )
        ))
    }

    func makeBiometricConsentViewController(
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        do {
            return try BiometricConsentViewController(
                brandLogo: brandLogo,
                consentContent: staticContent.biometricConsent,
                sheetController: sheetController
            )
        } catch {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.unknown(error)
                )
            )
        }
    }

    func makeDocumentTypeSelectViewController(
        sheetController: VerificationSheetControllerProtocol,
        staticContent: StripeAPI.VerificationPage
    ) -> UIViewController {
        do {
            return try DocumentTypeSelectViewController(
                sheetController: sheetController,
                staticContent: staticContent.documentSelect
            )
        } catch let error {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.unknown(error)
                )
            )
        }
    }

    func makeDocumentCaptureViewController(
        documentScannerResult: Result<AnyDocumentScanner, Error>,
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        // Show error if we haven't collected document type
        guard let documentType = sheetController.collectedData.idDocumentType else {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.missingRequiredInput([.idDocumentType])
                )
            )
        }

        let documentUploader = DocumentUploader(
            imageUploader: IdentityImageUploader(
                configuration: .init(from: staticContent.documentCapture),
                apiClient: sheetController.apiClient,
                analyticsClient: sheetController.analyticsClient,
                idDocumentType: documentType
            )
        )

        switch documentScannerResult {
        case .failure(let error):
            sheetController.analyticsClient.logGenericError(error: error)

            // Return document upload screen if we can't load models for auto-capture
            return DocumentFileUploadViewController(
                documentType: documentType,
                requireLiveCapture: staticContent.documentCapture.requireLiveCapture,
                sheetController: sheetController,
                documentUploader: documentUploader
            )

        case .success(let anyDocumentScanner):
            return DocumentCaptureViewController(
                apiConfig: staticContent.documentCapture,
                documentType: documentType,
                sheetController: sheetController,
                cameraSession: makeDocumentCaptureCameraSession(),
                documentUploader: documentUploader,
                anyDocumentScanner: anyDocumentScanner
            )
        }
    }

    func makeSelfieCaptureViewController(
        faceScannerResult: Result<AnyFaceScanner, Error>,
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        guard let selfiePageConfig = staticContent.selfie else {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.missingSelfieConfig
                )
            )
        }

        switch faceScannerResult {

        case .success(let anyFaceScanner):
            return SelfieCaptureViewController(
                apiConfig: selfiePageConfig,
                sheetController: sheetController,
                cameraSession: makeSelfieCaptureCameraSession(),
                selfieUploader: SelfieUploader(
                    imageUploader: IdentityImageUploader(
                        configuration: .init(from: selfiePageConfig),
                        apiClient: sheetController.apiClient,
                        analyticsClient: sheetController.analyticsClient,
                        idDocumentType: nil
                    )
                ),
                anyFaceScanner: anyFaceScanner
            )

        case .failure(let error):
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.unknown(error)
                )
            )
        }
    }

    func makeWebViewController(
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        guard let url = URL(string: staticContent.fallbackUrl) else {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.malformedURL(staticContent.fallbackUrl)
                )
            )
        }
        if #available(iOS 14.3, *) {
            return VerificationFlowWebViewController(
                startUrl: url,
                delegate: self
            )
        }

        let safariVC = SFSafariViewController(url: url)
        safariVC.delegate = self
        return safariVC
    }

    private func makeDocumentCaptureCameraSession() -> CameraSessionProtocol {
        #if targetEnvironment(simulator)
            return MockSimulatorCameraSession(images: IdentityVerificationSheet.simulatorDocumentCameraImages)
        #else
            return CameraSession()
        #endif
    }

    private func makeSelfieCaptureCameraSession() -> CameraSessionProtocol {
        #if targetEnvironment(simulator)
            return MockSimulatorCameraSession(images: IdentityVerificationSheet.simulatorSelfieCameraImages)
        #else
            return CameraSession()
        #endif
    }

    // MARK: - Collected Fields

    /// Set of fields the view controllers in the navigation stack are collecting from the user
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return navigationController.viewControllers.reduce(Set<StripeAPI.VerificationPageFieldType>()) { partialResult, vc in
            guard let dataCollectingVC = vc as? IdentityDataCollecting else {
                return partialResult
            }
            return partialResult.union(dataCollectingVC.collectedFields)
        }
    }

    /// Set of fields not collected by any of the view controllers in the navigation stack
    var uncollectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return Set(StripeAPI.VerificationPageFieldType.allCases).subtracting(collectedFields)
    }

    func missingRequirements(for verificationPage: StripeAPI.VerificationPage) -> Set<StripeAPI.VerificationPageFieldType> {
        verificationPage.requirements.missing.subtracting(collectedFields)
    }

    func isFinishedCollectingData(for verificationPage: StripeAPI.VerificationPage) -> Bool {
        return missingRequirements(for: verificationPage).isEmpty
    }

    var analyticsLastScreen: IdentityFlowViewController? {
        return navigationController.viewControllers.compactMap {
            $0 as? IdentityFlowViewController
        }.last
    }
}

// MARK: - IdentityFlowNavigationControllerDelegate

@available(iOS 13, *)
@available(iOSApplicationExtension, unavailable)
extension VerificationSheetFlowController: IdentityFlowNavigationControllerDelegate {
    func identityFlowNavigationControllerDidDismiss(_ navigationController: IdentityFlowNavigationController) {
        // Only call DidDismissNativeView if the user did not dismiss a web view
        guard !isUsingWebView else {
            return
        }

        delegate?.verificationSheetFlowControllerDidDismissNativeView(self)
    }
}

// MARK: - VerificationFlowWebViewControllerDelegate

@available(iOS 14.3, *)
@available(iOSApplicationExtension, unavailable)
extension VerificationSheetFlowController: VerificationFlowWebViewControllerDelegate {
    func verificationFlowWebViewController(
        _ viewController: VerificationFlowWebViewController,
        didFinish result: IdentityVerificationSheet.VerificationFlowResult
    ) {
        // NOTE: We're intentionally ignoring the result value since it will no
        // longer be returned when native component experience is ready for release.
        delegate?.verificationSheetFlowControllerDidDismissWebView(self)
    }
}

// MARK: - SFSafariViewControllerDelegate

@available(iOS 13, *)
extension VerificationSheetFlowController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        delegate?.verificationSheetFlowControllerDidDismissWebView(self)
    }
}
