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
    var primaryButtonStyle: IdentityVerificationSheet.Configuration.PrimaryButtonStyle { get }
    var secondaryButtonStyle: IdentityVerificationSheet.Configuration.SecondaryButtonStyle { get }

    func resetNetworkedIdentityForNewPresentation()

    func transitionToNextScreen(
        skipTestMode: Bool,
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping () -> Void
    )

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

    func transitionToErrorScreen(
        sheetController: VerificationSheetControllerProtocol,
        error: Error,
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

    var analyticsLastScreen: IdentityFlowViewController? { get }
}

@objc(STP_Internal_VerificationSheetFlowController)
final class VerificationSheetFlowController: NSObject {

    let brandLogo: UIImage
    let primaryButtonStyle: IdentityVerificationSheet.Configuration.PrimaryButtonStyle
    let secondaryButtonStyle: IdentityVerificationSheet.Configuration.SecondaryButtonStyle
    let biometricConsentConfiguration: IdentityVerificationSheet.Configuration.BiometricConsentConfiguration?

    weak var delegate: VerificationSheetFlowControllerDelegate?

    var visitedIndividualWelcomePage: Bool = false

    private(set) var isUsingWebView = false

    private(set) var documentUploader: DocumentUploaderProtocol?

    private let networkedIdentityAPIClientFactory: (String) -> NetworkedIdentityAPIClient
    private var attemptedNetworkedIdentitySessionID: String?
    private var networkedIdentityPresentationID = UUID()
    private weak var networkedIdentityViewController: NetworkedIdentityFlowViewController?
    private weak var networkedIdentitySheetController: VerificationSheetControllerProtocol?
    private var networkedIdentityFallback: (() -> Void)?

    init(
        configuration: IdentityVerificationSheet.Configuration,
        networkedIdentityAPIClientFactory: @escaping (String) -> NetworkedIdentityAPIClient = { key in
            let apiClient = STPAPIClient(publishableKey: key)
            apiClient.appInfo = STPAPIClient.shared.appInfo
            return NetworkedIdentityAPIClientImpl(apiClient: apiClient, merchantPublishableKey: key)
        }
    ) {
        self.brandLogo = configuration.brandLogo
        self.primaryButtonStyle = configuration.primaryButtonStyle
        self.secondaryButtonStyle = configuration.secondaryButtonStyle
        self.biometricConsentConfiguration = configuration.biometricConsent
        self.networkedIdentityAPIClientFactory = networkedIdentityAPIClientFactory
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
    func resetNetworkedIdentityForNewPresentation() {
        // A canceled presentation is not a persisted skip. Let fresh bootstrap state decide
        // whether a later presentation of the same VerificationSession can offer reuse again.
        attemptedNetworkedIdentitySessionID = nil
        networkedIdentityPresentationID = UUID()
        networkedIdentityViewController = nil
        networkedIdentitySheetController = nil
        networkedIdentityFallback = nil
    }

    /// Transitions to the next view controller in the flow with a 'push' animation.
    /// - Note: This may replace the navigation stack or push an additional view
    ///   controller onto the stack, depending on whether on where the user is in the flow.
    func transitionToNextScreen(
        skipTestMode: Bool,
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        updateDataResult: Result<StripeAPI.VerificationPageData, Error>?,
        sheetController: VerificationSheetControllerProtocol,
        completion: @escaping () -> Void
    ) {
        nextViewController(
            skipTestMode: skipTestMode,
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
            self.transition(
                to: makeIndividualViewController(
                    staticContent: staticContent,
                    sheetController: sheetController
                ),
                shouldAnimate: true,
                completion: {}
            )
        } catch {
            self.transition(
                to: ErrorViewController(
                    sheetController: sheetController,
                    error: .error(error)
                ),
                shouldAnimate: true,
                completion: {}
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
            self.transition(
                to: CountryNotListedViewController(
                    missingType: missingType,
                    countryNotListedContent:
                        staticContent.countryNotListed,
                    sheetController: sheetController
                ),
                shouldAnimate: true,
                completion: {}
            )
        } catch {
            self.transition(
                to: ErrorViewController(
                    sheetController: sheetController,
                    error: .error(error)
                ),
                shouldAnimate: true,
                completion: {}
            )
        }
    }

    func transitionToSelfieCaptureScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol
    ) {
        return sheetController.mlModelLoader.faceModelsFuture.observe(on: .main) {
            [weak self] result in
            guard let self = self else { return }

            let staticContent: StripeAPI.VerificationPage
            do {
                staticContent = try staticContentResult.get()
                self.transition(
                    to: self.makeSelfieCaptureViewController(
                        faceScannerResult: result,
                        staticContent: staticContent,
                        sheetController: sheetController
                    ),
                    shouldAnimate: true,
                    completion: {}
                )
            } catch {
                self.transition(
                    to: ErrorViewController(
                        sheetController: sheetController,
                        error: .error(error)
                    ),
                    shouldAnimate: true,
                    completion: {}
                )
            }
        }
    }

    func transitionToDocumentCaptureScreen(
        staticContentResult: Result<StripeAPI.VerificationPage, Error>,
        sheetController: VerificationSheetControllerProtocol
    ) {
        return sheetController.mlModelLoader.documentModelsFuture.observe(on: .main) {
            [weak self] result in
            guard let self = self else { return }

            let staticContent: StripeAPI.VerificationPage
            do {
                staticContent = try staticContentResult.get()
                self.transition(
                    to: self.makeDocumentCaptureViewController(
                        documentScannerResult: result,
                        staticContent: staticContent,
                        sheetController: sheetController
                    ),
                    shouldAnimate: true,
                    completion: {}
                )
            } catch {
                self.transition(
                    to: ErrorViewController(
                        sheetController: sheetController,
                        error: .error(error)
                    ),
                    shouldAnimate: true,
                    completion: {}
                )
            }
        }
    }

    func transitionToErrorScreen(
        sheetController: VerificationSheetControllerProtocol,
        error: Error,
        completion: @escaping () -> Void
    ) {
        self.transition(
            to: ErrorViewController(
                sheetController: sheetController,
                error: .error(error)
            ),
            shouldAnimate: true,
            completion: completion
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
    func transition(
        to nextViewController: UIViewController,
        shouldAnimate: Bool,
        completion: @escaping () -> Void
    ) {
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
        let entersOrLeavesNetworkedIdentity = nextViewController is NetworkedIdentityFlowViewController
            || navigationController.topViewController is NetworkedIdentityFlowViewController

        // Don't display a back button, so replace the navigation stack
        if isTransitioningFromLoading || isTransitioningFromDebug || isSuccessState || isBiometricConsent || entersOrLeavesNetworkedIdentity {
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
        skipTestMode: Bool,
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
            return completion(
                ErrorViewController(
                    sheetController: sheetController,
                    error: .error(error)
                )
            )
        }

        // Check for validation errors
        if let inputError = updateDataResponse?.requirements.errors.first {
            return completion(
                ErrorViewController(
                    sheetController: sheetController,
                    error: .inputError(inputError)
                )
            )
        }

        // If client is unsupported, fallback to web
        if staticContent.unsupportedClient {
            isUsingWebView = true
            return completion(
                makeWebViewController(
                    staticContent: staticContent,
                    sheetController: sheetController
                )
            )
        }

        if !skipTestMode && !staticContent.livemode {
            return completion(
                makeDebugViewModeController(sheetController: sheetController)
            )
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
                navigationController.dismiss(animated: true)
                return
            }
            return completion(
                SuccessViewController(
                    successContent: staticContent.success,
                    sheetController: sheetController
                )
            )
        }

        let sessionStatus = updateDataResponse?.status ?? staticContent.status
        let sessionSubmitted = updateDataResponse?.submitted ?? staticContent.submitted
        let sessionClosed = updateDataResponse?.closed ?? false
        if sheetController.apiClient.supportsNetworkedIdentity,
           sessionStatus == .requiresInput,
           !sessionClosed,
           !sessionSubmitted || updateDataResponse?.needsFallback() == true,
           attemptedNetworkedIdentitySessionID != staticContent.id {
            let presentationID = networkedIdentityPresentationID
            let route = staticContent.networkedIdentityRoute
            if route == .resumeReuse || route == .resumeSave,
               updateDataResponse == nil, missingRequirements.isEmpty {
                attemptedNetworkedIdentitySessionID = staticContent.id
                // A prepared/attached session still needs ordinary submit; empty requirements
                // alone do not mean verification succeeded.
                completion(LoadingViewController())
                DispatchQueue.main.async { [weak self, weak sheetController] in
                    guard self?.networkedIdentityPresentationID == presentationID else { return }
                    sheetController?.continueAfterNetworkedIdentity(
                        with: .success(.init(
                            id: staticContent.id,
                            requirements: .init(errors: [], missing: missingRequirements),
                            status: staticContent.status,
                            submitted: false,
                            closed: false
                        )),
                        completion: {}
                    )
                }
                return
            }
            if route == .reuse,
               !missingRequirements.contains(.biometricConsent),
               !missingRequirements.isDisjoint(with: [.idDocumentFront, .idDocumentBack]),
               let merchantKey = staticContent.merchantPublishableKey,
               !merchantKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                attemptedNetworkedIdentitySessionID = staticContent.id
                networkedIdentitySheetController = sheetController
                networkedIdentityFallback = { [weak self, weak sheetController] in
                    guard let self, let sheetController else { return }
                    self.transitionToNextScreen(
                        skipTestMode: true,
                        staticContentResult: .success(staticContent),
                        updateDataResult: updateDataResult,
                        sheetController: sheetController,
                        completion: {}
                    )
                }
                DispatchQueue.main.async { [weak self, weak sheetController] in
                    guard let self, let sheetController,
                          self.networkedIdentityPresentationID == presentationID else { return }
                    let coordinator = NetworkedIdentityCoordinator(
                        apiClient: self.networkedIdentityAPIClientFactory(merchantKey),
                        documentRequirements: .init(verificationPage: staticContent),
                        identityAPIClient: sheetController.apiClient
                    )
                    let viewController = NetworkedIdentityFlowViewController(
                        coordinator: coordinator,
                        providedEmailAddress: staticContent.networkedIdentity?.email
                    )
                    self.networkedIdentityViewController = viewController
                    viewController.delegate = self
                    completion(viewController)
                }
                return
            }
            // #TODO - Networked Identity: Add the save offer after design resolves whether
            // opt-in happens before or after capture. Resumed save/reuse follows requirements.
        }

        switch missingRequirements.nextDestination(collectedData: sheetController.collectedData) {
        case .consentDestination:
            return completion(
                makeBiometricConsentViewController(
                    staticContent: staticContent,
                    sheetController: sheetController
                )
            )
        case .documentWarmupDestination:
            return completion(
                makeDocumentWarmupViewController(
                    sheetController: sheetController,
                    staticContent: staticContent
                )
            )
        case .documentCaptureDestination:
            return sheetController.mlModelLoader.documentModelsFuture.observe(on: .main) {
                [weak self] result in
                guard let self = self else { return }
                completion(
                    self.makeDocumentCaptureViewController(
                        documentScannerResult: result,
                        staticContent: staticContent,
                        sheetController: sheetController
                    )
                )
            }
        case .selfieCaptureDestination:
            completion(makeSelfieWarmupViewController(sheetController: sheetController))
        case .individualWelcomeDestination:
            visitedIndividualWelcomePage = true
            // if missing .name or .dob, then verification type is not document.
            // Transition to IndividualWelcomeViewController.
            return completion(
                makeIndividualWelcomeViewController(
                    staticContent: staticContent,
                    sheetController: sheetController
                )
            )
        case .individualDestination:
            // if missing .address or .idNumber but not missing .name or .dob, then verification type is document.
            // IndividualViewController is the screen after document collection.
            return completion(
                makeIndividualViewController(
                    staticContent: staticContent,
                    sheetController: sheetController
                )
            )
        case .phoneOtpDestination:
            return completion(
                makePhoneOtpViewController(
                    staticContent: staticContent,
                    sheetController: sheetController
                )
            )
        case .confirmationDestination:
            if staticContent.skipSuccessPage {
                navigationController.dismiss(animated: true)
                return
            }
            return completion(
                SuccessViewController(
                    successContent: staticContent.success,
                    sheetController: sheetController
                )
            )
        case .errorDestination:
            return completion(
                ErrorViewController(
                    sheetController: sheetController,
                    error: .error(
                        VerificationSheetFlowControllerError.noScreenForRequirements(
                            missingRequirements
                        )
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
                configuration: biometricConsentConfiguration,
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

    func makeDocumentCaptureViewController(
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

    private func makeDocumentCaptureCameraSession() -> CameraSessionProtocol {
        #if targetEnvironment(simulator)
        return MockSimulatorCameraSession(
            images: IdentityVerificationSheet.simulatorDocumentCameraImages
        )
        #else
        return CameraSession()
        #endif
    }

    private func makeSelfieCaptureCameraSession() -> CameraSessionProtocol {
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

extension VerificationSheetFlowController: NetworkedIdentityFlowViewControllerDelegate {
    func networkedIdentityFlowViewControllerDidCancel(
        _ viewController: NetworkedIdentityFlowViewController
    ) {
        guard networkedIdentityViewController === viewController else { return }
        networkedIdentityViewController = nil
        networkedIdentityFallback = nil
        networkedIdentitySheetController = nil
        navigationController.dismiss(animated: true)
    }

    func networkedIdentityFlowViewController(
        _ viewController: NetworkedIdentityFlowViewController,
        didRequestFullCapture reason: NetworkedIdentityFallbackReason
    ) {
        guard networkedIdentityViewController === viewController else { return }
        networkedIdentityViewController = nil
        let fallback = networkedIdentityFallback
        networkedIdentityFallback = nil
        networkedIdentitySheetController = nil
        fallback?()
    }

    func networkedIdentityFlowViewController(
        _ viewController: NetworkedIdentityFlowViewController,
        didCompleteWith result: Result<StripeAPI.VerificationPageData, Error>
    ) {
        guard networkedIdentityViewController === viewController else { return }
        networkedIdentityViewController = nil
        let sheetController = networkedIdentitySheetController
        networkedIdentityFallback = nil
        networkedIdentitySheetController = nil
        sheetController?.continueAfterNetworkedIdentity(with: result, completion: {})
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
