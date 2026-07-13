//
//  VerificationSheetFlowController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 10/29/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import SafariServices
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
import UIKit

protocol VerificationSheetFlowControllerDelegate: AnyObject {
    /// Invoked when the user has dismissed the navigation controller
    func verificationSheetFlowControllerDidDismissNativeView(
        _ flowController: VerificationSheetFlowControllerProtocol
    )

    func verificationSheetFlowControllerDidDismissWebView(
        _ flowController: VerificationSheetFlowControllerProtocol
    )
}

protocol VerificationSheetFlowControllerProtocol: AnyObject {
    var delegate: VerificationSheetFlowControllerDelegate? { get set }

    var navigationController: UINavigationController { get }

    var documentUploader: DocumentUploaderProtocol? { get }
    var visitedIndividualWelcomePage: Bool { get }

    @MainActor func transitionToNextScreen(
        skipTestMode: Bool,
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol
    ) async

    func transitionToIndividualScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol
    )

    func transitionToCountryNotListedScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol,
        missingType: IndividualFormElement.MissingType
    )

    func transitionToSelfieCaptureScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol
    )

    func transitionToDocumentCaptureScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol
    )

    @MainActor func transitionToErrorScreen(
        sheetController: VerificationSheetControllerProtocol,
        error: Error
    ) async

    func replaceCurrentScreen(
        with viewController: UIViewController
    )

    func canPopToScreen(withField field: StripeAPI.VerificationPageFieldType) -> Bool

    func popToScreen(
        withField field: StripeAPI.VerificationPageFieldType,
        shouldResetViewController: Bool
    )

    var analyticsLastScreen: IdentityFlowViewController? { get }
}

@objc(STP_Internal_VerificationSheetFlowController)
final class VerificationSheetFlowController: NSObject {

    let brandLogo: UIImage

    weak var delegate: VerificationSheetFlowControllerDelegate?

    var visitedIndividualWelcomePage: Bool = false

    private(set) var isUsingWebView = false

    private(set) var documentUploader: DocumentUploaderProtocol?

    init(
        brandLogo: UIImage
    ) {
        self.brandLogo = brandLogo
    }

    private(set) lazy var navigationController: UINavigationController = {
        let navigationController = IdentityFlowNavigationController(
            rootViewController: LoadingViewController()
        )
        navigationController.identityDelegate = self
        return navigationController
    }()
}

extension VerificationSheetFlowController: VerificationSheetFlowControllerProtocol {
    /// Transitions to the next view controller in the flow with a 'push' animation.
    /// - Note: This may replace the navigation stack or push an additional view
    ///   controller onto the stack, depending on whether on where the user is in the flow.
    @MainActor func transitionToNextScreen(
        skipTestMode: Bool,
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol
    ) async {
        guard let viewController = await nextViewController(
            skipTestMode: skipTestMode,
            staticContentResult: staticContentResult,
            updateDataResult: updateDataResult,
            sheetController: sheetController
        ) else {
            await dismissNavigationController()
            return
        }

        await transition(
            to: viewController,
            shouldAnimate: true
        )
    }

    func makeDocumentUploader(
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> DocumentUploader {
        let documentUploader = DocumentUploader(
            imageUploader: IdentityImageUploader(
                configuration: .init(from: staticContent.documentCapture),
                sheetController: sheetController
            )
        )
        self.documentUploader = documentUploader
        return documentUploader
    }

    func makeDocumentFileUploadViewController(
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol,
        documentUploader: DocumentUploaderProtocol? = nil
    ) -> DocumentFileUploadViewController {
        let documentUploader = documentUploader
            ?? makeDocumentUploader(
                staticContent: staticContent,
                sheetController: sheetController
            )

        return DocumentFileUploadViewController(
            requireLiveCapture: staticContent.documentCapture.requireLiveCapture,
            sheetController: sheetController,
            documentUploader: documentUploader,
            availableIDTypes: staticContent.documentSelect.idDocumentTypeAllowlistKeys
        )
    }

    /// Transitions to the IndividualViewController in the flow with a 'push' animation.
    func transitionToIndividualScreen(
        staticContentResult: Result<StripeCore.StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol
    ) {
        let staticContent: StripeAPI.VerificationPage
        do {
            staticContent = try staticContentResult.get()
            self.transitionWithoutWaiting(
                to: makeIndividualViewController(
                    staticContent: staticContent,
                    sheetController: sheetController
                ),
                shouldAnimate: true
            )
        } catch {
            self.transitionWithoutWaiting(
                to: ErrorViewController(
                    sheetController: sheetController,
                    error: .error(error)
                ),
                shouldAnimate: true
            )
        }
    }

    /// Transitions to the CountryNotListedViewController in the flow with a 'push' animation.
    func transitionToCountryNotListedScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol,
        missingType: IndividualFormElement.MissingType
    ) {
        let staticContent: StripeAPI.VerificationPage
        do {
            staticContent = try staticContentResult.get()
            self.transitionWithoutWaiting(
                to: CountryNotListedViewController(
                    missingType: missingType,
                    countryNotListedContent:
                        staticContent.countryNotListed,
                    sheetController: sheetController
                ),
                shouldAnimate: true
            )
        } catch {
            self.transitionWithoutWaiting(
                to: ErrorViewController(
                    sheetController: sheetController,
                    error: .error(error)
                ),
                shouldAnimate: true
            )
        }
    }

    func transitionToSelfieCaptureScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            let faceScannerResult = await sheetController.mlModelLoader.faceModels()
            do {
                let staticContent = try staticContentResult.get()
                self.transitionWithoutWaiting(
                    to: self.makeSelfieCaptureViewController(
                        faceScannerResult: faceScannerResult,
                        staticContent: staticContent,
                        sheetController: sheetController
                    ),
                    shouldAnimate: true
                )
            } catch {
                self.transitionWithoutWaiting(
                    to: ErrorViewController(
                        sheetController: sheetController,
                        error: .error(error)
                    ),
                    shouldAnimate: true
                )
            }
        }
    }

    func transitionToDocumentCaptureScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }

            let documentScannerResult = await sheetController.mlModelLoader.documentModels()
            do {
                let staticContent = try staticContentResult.get()
                self.transitionWithoutWaiting(
                    to: self.makeDocumentCaptureViewController(
                        documentScannerResult: documentScannerResult,
                        staticContent: staticContent,
                        sheetController: sheetController
                    ),
                    shouldAnimate: true
                )
            } catch {
                self.transitionWithoutWaiting(
                    to: ErrorViewController(
                        sheetController: sheetController,
                        error: .error(error)
                    ),
                    shouldAnimate: true
                )
            }
        }
    }

    @MainActor func transitionToErrorScreen(
        sheetController: VerificationSheetControllerProtocol,
        error: Error
    ) async {
        await transition(
            to: ErrorViewController(
                sheetController: sheetController,
                error: .error(error)
            ),
            shouldAnimate: true
        )
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
        guard
            let index = navigationController.viewControllers.lastIndex(where: {
                ($0 as? IdentityDataCollecting)?.collectedFields.contains(field) == true
            })
        else {
            return
        }

        let viewControllers = Array(
            navigationController.viewControllers.dropLast(
                navigationController.viewControllers.count - index - 1
            )
        )

        // Reset all ViewControllers to be popped
        if shouldResetViewController {
            for i in index..<navigationController.viewControllers.count {
                (navigationController.viewControllers[i] as? IdentityDataCollecting)?.reset()
            }
        }

        navigationController.setViewControllers(viewControllers, animated: animated)
    }

    // MARK: - Helpers

    /// - Note: This method should not be called directly from outside of this class except for tests
    @MainActor func transition(
        to nextViewController: UIViewController,
        shouldAnimate: Bool
    ) async {
        let transitionCoordinator = beginTransition(
            to: nextViewController,
            shouldAnimate: shouldAnimate
        )

        await withCheckedContinuation { continuation in
            guard let transitionCoordinator else {
                DispatchQueue.main.async {
                    continuation.resume()
                }
                return
            }

            let didRegisterCompletion = transitionCoordinator.animate(
                alongsideTransition: nil,
                completion: { _ in continuation.resume() }
            )
            if !didRegisterCompletion {
                DispatchQueue.main.async {
                    continuation.resume()
                }
            }
        }
    }

    @MainActor private func dismissNavigationController() async {
        guard navigationController.presentingViewController != nil else {
            return
        }

        await withCheckedContinuation { continuation in
            navigationController.dismiss(animated: true) {
                continuation.resume()
            }
        }
    }

    private func transitionWithoutWaiting(
        to nextViewController: UIViewController,
        shouldAnimate: Bool
    ) {
        beginTransition(
            to: nextViewController,
            shouldAnimate: shouldAnimate
        )
    }

    @discardableResult
    private func beginTransition(
        to nextViewController: UIViewController,
        shouldAnimate: Bool
    ) -> UIViewControllerTransitionCoordinator? {
        // If the only view in the stack is a loading screen, they should not be
        // able to hit the back button to get back into a loading state.
        let isTransitioningFromLoading =
            navigationController.viewControllers.count == 1
            && navigationController.viewControllers.first is LoadingViewController

        // If the only view in the stack is a debug screen, they just clicked
        // "Preview" and should not be able to hit the back button to get back
        // into a debug state.
        let isTransitioningFromDebug =
            navigationController.viewControllers.count == 1
            && navigationController.viewControllers.first is DebugViewController

        // If the user is seeing the success screen, it means their session has
        // been submitted and they can't go back to edit their input.
        let isSuccessState = nextViewController is SuccessViewController

        // If it's biometric consent, it's either the first screen of a doc type verification, or the first doc-fallback screen of phone type verification, don't show go back.
        let isBiometricConsent = nextViewController is BiometricConsentViewController

        // Don't display a back button, so replace the navigation stack
        if isTransitioningFromLoading || isTransitioningFromDebug || isSuccessState || isBiometricConsent {
            navigationController.setViewControllers([nextViewController], animated: shouldAnimate)
        } else {
            navigationController.pushViewController(nextViewController, animated: shouldAnimate)
        }

        return shouldAnimate ? navigationController.transitionCoordinator : nil
    }

    /// Instantiates and returns the next view controller to display in the flow.
    /// - Note: This method should not be called directly from outside of this class except for tests
    @MainActor func nextViewController(
        skipTestMode: Bool,
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol
    ) async -> UIViewController? {
        // Check for API Errors
        let staticContent: StripeAPI.VerificationPage
        let updateDataResponse: StripeAPI.VerificationPageData?
        do {
            staticContent = try staticContentResult.get()
            updateDataResponse = try updateDataResult?.get()
        } catch {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(error)
            )
        }

        // Check for validation errors
        if let inputError = updateDataResponse?.requirements.errors.first {
            return ErrorViewController(
                sheetController: sheetController,
                error: .inputError(inputError)
            )
        }

        // If client is unsupported, fallback to web
        if staticContent.unsupportedClient {
            isUsingWebView = true
            return makeWebViewController(
                staticContent: staticContent,
                sheetController: sheetController
            )
        }

        if !skipTestMode && !staticContent.livemode {
            return makeDebugViewModeController(sheetController: sheetController)
        }

        // If updateDataResponse is not nil, then this transition is triggered by a
        // VerificationPageDataUpdate request, get missing requirements from the response.
        // Otherwise, this is the transition to initial page, nothing is collected yet,
        // return missing requirement from staticContent.
        let missingRequirements =
            updateDataResponse?.requirements.missing ?? staticContent.requirements.missing

        // Show success screen if submitted and closed
        if updateDataResponse?.submittedAndClosed() == true {
            if staticContent.skipSuccessPage {
                return nil
            }
            return SuccessViewController(
                successContent: staticContent.success,
                sheetController: sheetController
            )
        }

        switch missingRequirements.nextDestination(collectedData: sheetController.collectedData) {
        case .consentDestination:
            return makeBiometricConsentViewController(
                staticContent: staticContent,
                sheetController: sheetController
            )
        case .documentWarmupDestination:
            return makeDocumentWarmupViewController(
                sheetController: sheetController,
                staticContent: staticContent
            )
        case .documentCaptureDestination:
            let documentScannerResult = await sheetController.mlModelLoader.documentModels()
            return makeDocumentCaptureViewController(
                documentScannerResult: documentScannerResult,
                staticContent: staticContent,
                sheetController: sheetController
            )
        case .selfieCaptureDestination:
            return makeSelfieWarmupViewController(sheetController: sheetController)
        case .individualWelcomeDestination:
            visitedIndividualWelcomePage = true
            // if missing .name or .dob, then verification type is not document.
            // Transition to IndividualWelcomeViewController.
            return makeIndividualWelcomeViewController(
                staticContent: staticContent,
                sheetController: sheetController
            )
        case .individualDestination:
            // if missing .address or .idNumber but not missing .name or .dob, then verification type is document.
            // IndividualViewController is the screen after document collection.
            return makeIndividualViewController(
                staticContent: staticContent,
                sheetController: sheetController
            )
        case .phoneOtpDestination:
            return makePhoneOtpViewController(
                staticContent: staticContent,
                sheetController: sheetController
            )
        case .confirmationDestination:
            if staticContent.skipSuccessPage {
                return nil
            }
            return SuccessViewController(
                successContent: staticContent.success,
                sheetController: sheetController
            )
        case .errorDestination:
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.noScreenForRequirements(
                        missingRequirements
                    )
                )
            )
        }
    }

    func makeIndividualWelcomeViewController(
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        do {
            return try IndividualWelcomeViewController(
                brandLogo: brandLogo,
                welcomeContent: staticContent.individualWelcome,
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

    func makeSelfieWarmupViewController(
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        do {
            return try SelfieWarmupViewController(sheetController: sheetController)
        } catch {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.unknown(error)
                )
            )
        }
    }

    func makeIndividualViewController(
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        return IndividualViewController(
            individualContent: staticContent.individual,
            missing: staticContent.requirements.missing,
            sheetController: sheetController
        )
    }

    func makePhoneOtpViewController(
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        guard let phoneOtpContent = staticContent.phoneOtp
        else {
            return ErrorViewController(
                sheetController: sheetController,
                error: .error(
                    VerificationSheetFlowControllerError.missingPhoneOtpContent
                )
            )
        }
        return PhoneOtpViewController(
            phoneOtpContent: phoneOtpContent,
            sheetController: sheetController
        )
    }

    func makeBiometricConsentViewController(
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        do {
            return try BiometricConsentViewController(
                brandLogo: brandLogo,
                showsStripeLogo: !staticContent.isStripe,
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

    func makeDocumentWarmupViewController(
        sheetController: VerificationSheetControllerProtocol,
        staticContent: StripeAPI.VerificationPage
    ) -> UIViewController {
        do {
            return try DocumentWarmupViewController(
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

    @MainActor func makeDocumentCaptureViewController(
        documentScannerResult: Result<AnyDocumentScanner, Error>,
        staticContent: StripeAPI.VerificationPage,
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        // reinitalize documentUploader with new idDocumentType each time
        let documentUploader = makeDocumentUploader(
            staticContent: staticContent,
            sheetController: sheetController
        )

        let availableTypes = staticContent.documentSelect.idDocumentTypeAllowlistKeys

        switch documentScannerResult {
        case .failure(let error):
            sheetController.analyticsClient.logGenericError(
                error: error,
                additionalMetadata: [
                    "error_context": "document_scanner_load",
                    "fallback_screen": IdentityAnalyticsClient.ScreenName.documentFileUpload.rawValue,
                    "require_live_capture": staticContent.documentCapture.requireLiveCapture,
                    "screen_name": IdentityAnalyticsClient.ScreenName.documentCapture.rawValue,
                ],
                sheetController: sheetController
            )

            // Return document upload screen if we can't load models for auto-capture
            return makeDocumentFileUploadViewController(
                staticContent: staticContent,
                sheetController: sheetController,
                documentUploader: documentUploader,
            )

        case .success(let anyDocumentScanner):

            return DocumentCaptureViewController(
                apiConfig: staticContent.documentCapture,
                sheetController: sheetController,
                cameraSession: makeDocumentCaptureCameraSession(),
                documentUploader: documentUploader,
                anyDocumentScanner: anyDocumentScanner,
                avaialableIDTypes: availableTypes
            )
        }
    }

    @MainActor func makeSelfieCaptureViewController(
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
                        sheetController: sheetController
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
        return VerificationFlowWebViewController(
            startUrl: url,
            delegate: self
        )
    }

    func makeDebugViewModeController(
        sheetController: VerificationSheetControllerProtocol
    ) -> UIViewController {
        return DebugViewController(
            sheetController: sheetController)
    }

    @MainActor private func makeDocumentCaptureCameraSession() -> CameraSessionProtocol {
        #if targetEnvironment(simulator)
        return MockSimulatorCameraSession(
            images: IdentityVerificationSheet.simulatorDocumentCameraImages
        )
        #else
        return CameraSession()
        #endif
    }

    @MainActor private func makeSelfieCaptureCameraSession() -> CameraSessionProtocol {
        #if targetEnvironment(simulator)
        return MockSimulatorCameraSession(
            images: IdentityVerificationSheet.simulatorSelfieCameraImages
        )
        #else
        return CameraSession()
        #endif
    }

    // MARK: - Collected Fields

    /// Set of fields the view controllers in the navigation stack are collecting from the user
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return navigationController.viewControllers.reduce(
            Set<StripeAPI.VerificationPageFieldType>()
        ) { partialResult, vc in
            guard let dataCollectingVC = vc as? IdentityDataCollecting else {
                return partialResult
            }
            return partialResult.union(dataCollectingVC.collectedFields)
        }
    }

    var analyticsLastScreen: IdentityFlowViewController? {
        return navigationController.viewControllers.compactMap {
            $0 as? IdentityFlowViewController
        }.last
    }
}

// MARK: - IdentityFlowNavigationControllerDelegate

extension VerificationSheetFlowController: IdentityFlowNavigationControllerDelegate {
    func identityFlowNavigationControllerDidDismiss(
        _ navigationController: IdentityFlowNavigationController
    ) {
        // Only call DidDismissNativeView if the user did not dismiss a web view
        guard !isUsingWebView else {
            return
        }

        delegate?.verificationSheetFlowControllerDidDismissNativeView(self)
    }
}

// MARK: - VerificationFlowWebViewControllerDelegate

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

extension VerificationSheetFlowController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        delegate?.verificationSheetFlowControllerDidDismissWebView(self)
    }
}

extension Set<StripeAPI.VerificationPageFieldType> {
    func nextDestination(collectedData: StripeAPI.VerificationPageCollectedData) -> IdentityTopLevelDestination {
        if self.contains(.biometricConsent) {
            return .consentDestination
        } else if !self.isDisjoint(with: [.idDocumentFront, .idDocumentBack]) {
            return .documentWarmupDestination
        } else if self.contains(.face) {
            return .selfieCaptureDestination
        } else if !self.isDisjoint(with: [.name, .dob]) {
            return .individualWelcomeDestination
        } else if !self.isDisjoint(with: [.idNumber, .address, .phoneNumber]) {
            return .individualDestination
        } else if self.contains(.phoneOtp) {
            return .phoneOtpDestination
        } else if self.isEmpty {
            return .confirmationDestination
        } else {
            return .errorDestination
        }
    }
}
