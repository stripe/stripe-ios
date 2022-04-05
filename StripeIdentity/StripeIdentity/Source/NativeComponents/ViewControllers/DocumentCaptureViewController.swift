//
//  DocumentCaptureViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/8/21.
//

import UIKit
import AVKit
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCameraCore

@available(iOSApplicationExtension, unavailable)
final class DocumentCaptureViewController: IdentityFlowViewController {
    
    // MARK: State

    /// Possible UI states for this screen
    enum State: Equatable {
        /// The user has not yet granted or denied camera access yet
        case initial
        /// Actively scanning the camera feed for a high quality image of the specified classification
        case scanning(DocumentSide, foundClassification: IDDetectorOutput.Classification?)
        /// Successfully scanned the camera feed for the specified classification
        case scanned(DocumentSide, UIImage)
        /// Saving the captured data
        case saving(lastImage: UIImage)
        /// The app does not have camera access
        case noCameraAccess
        /// There was an error accessing the camera
        case cameraError
        /// Scanning timed out
        case timeout(DocumentSide)
    }

    private(set) var state: State {
        didSet {
            guard state != oldValue else {
                return
            }

            updateUI()
            generateFeedbackIfNeededForStateChange()
        }
    }

    override var warningAlertViewModel: WarningAlertViewModel? {
        switch state {
        case .saving,
             .scanned,
             .scanning(.back, _),
             .timeout(.back):
            return .init(
                titleText: STPLocalizedString(
                    "Unsaved changes",
                    "Title for warning alert"
                ),
                messageText: STPLocalizedString(
                    "The images of your identity document have not been saved. Do you want to leave?",
                    "Text for message of warning alert"
                ),
                acceptButtonText: String.Localized.continue,
                declineButtonText: String.Localized.cancel
            )

        case .initial,
             .scanning(.front, _),
             .timeout(.front),
             .noCameraAccess,
             .cameraError:
          return nil
        }
    }
    // MARK: Views

    let documentCaptureView = DocumentCaptureView()

    // MARK: Computed Properties

    var viewModel: DocumentCaptureView.ViewModel {
        switch state {
        case .initial:
            return .scan(.init(
                scanningViewModel: .blank,
                instructionalText: scanningInstructionText(
                    for: .front,
                    foundClassification: nil
                )
            ))
        case .scanning(let documentSide, let foundClassification):
            return .scan(.init(
                scanningViewModel: .videoPreview(
                    cameraSession,
                    animateBorder: foundClassification?.matchesDocument(
                        type: documentType,
                        side: documentSide
                    ) ?? false
                ),
                instructionalText: scanningInstructionText(
                    for: documentSide,
                    foundClassification: foundClassification
                )
            ))
        case .scanned(_, let image),
             .saving(let image):
            return .scan(.init(
                scanningViewModel: .scanned(image),
                instructionalText: DocumentCaptureViewController.scannedInstructionalText
            ))
        case .noCameraAccess:
            return .error(.init(
                titleText: DocumentCaptureViewController.noCameraAccessErrorTitleText,
                bodyText: noCameraAccessErrorBodyText
            ))
        case .cameraError:
            return .error(.init(
                titleText: DocumentCaptureViewController.cameraUnavailableErrorTitleText,
                bodyText: DocumentCaptureViewController.cameraUnavailableErrorBodyText
            ))
        case .timeout:
            return .error(.init(
                titleText: DocumentCaptureViewController.timeoutErrorTitleText,
                bodyText: timeoutErrorBodyText
            ))
        }
    }

    var flowViewModel: IdentityFlowView.ViewModel {
        return .init(
            headerViewModel: titleText.map { .init(
                backgroundColor: CompatibleColor.systemBackground,
                headerType: .plain,
                titleText: $0
            ) },
            contentView: documentCaptureView,
            buttons: buttonViewModels
        )
    }

    var buttonViewModels: [IdentityFlowView.ViewModel.Button] {
        switch state {
        case .initial,
             .scanning:
            return [.continueButton(state: .disabled, didTap: {})]

        case .saving:
            return [.continueButton(state: .loading, didTap: {})]

        case .scanned(let documentSide, let image):
            return [.continueButton { [weak self] in
                self?.saveOrFlipDocument(scannedImage: image, documentSide: documentSide)
            }]

        case .noCameraAccess:
            var models = [IdentityFlowView.ViewModel.Button]()
            if !apiConfig.requireLiveCapture {
                models.append(.init(
                    text: STPLocalizedString(
                        "File Upload",
                        "Button that opens file upload screen"
                    ),
                    isPrimary: false,
                    didTap: { [weak self] in
                        self?.transitionToFileUpload()
                    }
                ))
            }

            models.append(
                .init(
                    text: String.Localized.app_settings,
                    didTap: { [weak self] in
                        self?.appSettingsHelper.openAppSettings()
                    }
                )
            )
            return models
        case .cameraError:
            return [
                .init(
                    text: STPLocalizedString(
                        "File Upload",
                        "Button that opens file upload screen"
                    ),
                    isPrimary: false,
                    didTap: { [weak self] in
                        self?.transitionToFileUpload()
                    }
                )
            ]
        case .timeout(let documentSide):
            return [
                .init(
                    text: DocumentCaptureViewController.uploadButtonText,
                    isPrimary: false,
                    didTap: { [weak self] in
                        self?.transitionToFileUpload()
                    }
                ),
                .init(
                    text: STPLocalizedString(
                        "Try Again",
                        "Button to attempt to re-scan identity document image"
                    ),
                    isPrimary: true,
                    didTap: { [weak self] in
                        self?.startScanning(documentSide: documentSide)
                    }
                ),
            ]
        }
    }

    var titleText: String? {
        switch state {
        case .initial:
            return titleText(for: .front)
        case .scanning(let side, _),
             .scanned(let side, _):
            return titleText(for: side)
        case .saving where documentType == .passport:
            return titleText(for: .front)
        case .saving:
            return titleText(for: .back)
        case .noCameraAccess,
             .cameraError,
             .timeout:
            return nil
        }
    }

    // MARK: Instance Properties

    let apiConfig: VerificationPageStaticContentDocumentCapturePage
    let documentType: DocumentType
    var timeoutTimer: Timer?
    private var feedbackGenerator: UINotificationFeedbackGenerator?

    // MARK: Coordinators
    let scanner: DocumentScannerProtocol
    let permissionsManager: CameraPermissionsManagerProtocol
    let cameraSession: CameraSessionProtocol

    let appSettingsHelper: AppSettingsHelperProtocol
    let documentUploader: DocumentUploaderProtocol

    // MARK: Init

    convenience init(
        apiConfig: VerificationPageStaticContentDocumentCapturePage,
        documentType: DocumentType,
        sheetController: VerificationSheetControllerProtocol,
        cameraSession: CameraSessionProtocol,
        cameraPermissionsManager: CameraPermissionsManagerProtocol = CameraPermissionsManager.shared,
        documentUploader: DocumentUploaderProtocol,
        documentScanner: DocumentScannerProtocol,
        appSettingsHelper: AppSettingsHelperProtocol = AppSettingsHelper.shared
    ) {
        self.init(
            apiConfig: apiConfig,
            documentType: documentType,
            initialState: .initial,
            sheetController: sheetController,
            cameraSession: cameraSession,
            cameraPermissionsManager: cameraPermissionsManager,
            documentUploader: documentUploader,
            documentScanner: documentScanner,
            appSettingsHelper: appSettingsHelper
        )
    }

    init(
        apiConfig: VerificationPageStaticContentDocumentCapturePage,
        documentType: DocumentType,
        initialState: State,
        sheetController: VerificationSheetControllerProtocol,
        cameraSession: CameraSessionProtocol,
        cameraPermissionsManager: CameraPermissionsManagerProtocol,
        documentUploader: DocumentUploaderProtocol,
        documentScanner: DocumentScannerProtocol,
        appSettingsHelper: AppSettingsHelperProtocol
    ) {
        self.apiConfig = apiConfig
        self.documentType = documentType
        self.state = initialState
        self.cameraSession = cameraSession
        self.permissionsManager = cameraPermissionsManager
        self.documentUploader = documentUploader
        self.scanner = documentScanner
        self.appSettingsHelper = appSettingsHelper

        super.init(sheetController: sheetController)

        addObservers()
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if state == .initial {
            setupCameraAndStartScanning(documentSide: .front)
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        cameraSession.setVideoOrientation(orientation: UIDevice.current.orientation.videoOrientation)
    }
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
extension DocumentCaptureViewController {

    // MARK: - Configure

    func updateUI() {
        configure(
            backButtonTitle: STPLocalizedString(
                "Scan",
                "Back button title for returning to the document scan screen"
            ),
            viewModel: flowViewModel
        )
        documentCaptureView.configure(with: viewModel)
    }

    func generateFeedbackIfNeededForStateChange() {
        guard case .scanned = state else {
            return
        }

        feedbackGenerator?.notificationOccurred(.success)
    }

    // MARK: - Notifications

    func addObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    // MARK: - App Backgrounding

    @objc func appDidEnterBackground() {
        stopScanning()
    }

    @objc func appDidEnterForeground() {
        if case let .scanning(side, _) = state {
            startScanning(documentSide: side)
        }
    }

    // MARK: - State Transitions

    /// Resets the view controller, clearing the scanned/uploaded images
    func reset() {
        stopScanning()
        documentUploader.reset()
        startScanning(documentSide: .front)
    }

    func setupCameraAndStartScanning(
        documentSide: DocumentSide
    ) {
        permissionsManager.requestCameraAccess(completeOnQueue: .main) { [weak self] granted in
            guard let self = self else { return }

            guard granted == true else {
                self.state = .noCameraAccess
                return
            }

            // Configure camera session
            // Tell the camera to focus on automatically adjust focus on the
            // center of the image.
            self.cameraSession.configureSession(
                configuration: .init(
                    initialCameraPosition: .back,
                    initialOrientation: UIDevice.current.orientation.videoOrientation,
                    focusMode: .continuousAutoFocus,
                    focusPointOfInterest: CGPoint(x: 0.5, y: 0.5),
                    outputSettings: [
                        (kCVPixelBufferPixelFormatTypeKey as String): Int(IDDetectorConstants.requiredPixelFormat)
                    ]
                ),
                delegate: self,
                completeOn: .main
            ) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.startScanning(documentSide: documentSide)
                case .failed:
                    // TODO(IDPROD-2816): log error from failed result
                    self.state = .cameraError
                }
            }
        }
    }

    func startScanning(documentSide: DocumentSide) {
        // Update the state of the PreviewView before starting the camera session,
        // otherwise the PreviewView may not update due to the DocumentScanner
        // hogging the CameraSession's sessionQueue.
        self.state = .scanning(documentSide, foundClassification: nil)

        // Focus the accessibility VoiceOver back onto the capture view
        UIAccessibility.post(notification: .layoutChanged, argument: self.documentCaptureView)

        // Prepare feedback generators
        self.feedbackGenerator = UINotificationFeedbackGenerator()
        self.feedbackGenerator?.prepare()

        cameraSession.startSession(completeOn: .main) { [weak self] in
            guard let self = self else { return }
            self.timeoutTimer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(self.apiConfig.autocaptureTimeout) / 1000,
                repeats: false
            ) { [weak self] _ in
                self?.handleTimeout(documentSide: documentSide)
            }
        }

    }

    func stopScanning() {
        timeoutTimer?.invalidate()
        cameraSession.stopSession()
        scanner.reset()
        feedbackGenerator = nil
    }

    func handleTimeout(documentSide: DocumentSide) {
        stopScanning()
        state = .timeout(documentSide)
    }

    /// Starts uploading an image as soon as it's been scanned
    func handleScannedImage(
        image: CGImage,
        scannerOutput scannerOutputOptional: DocumentScannerOutput?,
        documentSide: DocumentSide
    ) {
        // If this isn't the classification we're looking for, update the state
        // to display a different message to the user
        guard let scannerOutput = scannerOutputOptional,
              scannerOutput.isHighQuality(matchingDocumentType: documentType, side: documentSide)
        else {
            self.state = .scanning(
                documentSide,
                foundClassification: scannerOutputOptional?.idDetectorOutput.classification
            )
            return
        }

        documentUploader.uploadImages(
            for: documentSide,
            originalImage: image,
            documentScannerOutput: scannerOutput,
            method: .autoCapture
        )

        state = .scanned(documentSide, UIImage(cgImage: image))
        stopScanning()
    }

    func saveOrFlipDocument(scannedImage image: UIImage, documentSide: DocumentSide) {
        if let nextSide = documentSide.nextSide(for: documentType) {
            startScanning(documentSide: nextSide)
        } else {
            state = .saving(lastImage: image)
            saveDataAndTransitionToNextScreen(
                lastDocumentSide: documentSide,
                lastImage: image
            )
        }
    }

    func transitionToFileUpload() {
        guard let sheetController = sheetController else { return }

        let uploadVC = DocumentFileUploadViewController(
            documentType: documentType,
            requireLiveCapture: apiConfig.requireLiveCapture,
            sheetController: sheetController,
            documentUploader: documentUploader,
            cameraPermissionsManager: permissionsManager,
            appSettingsHelper: appSettingsHelper
        )
        sheetController.flowController.replaceCurrentScreen(with: uploadVC)
    }

    func saveDataAndTransitionToNextScreen(
        lastDocumentSide: DocumentSide,
        lastImage: UIImage
    ) {
        sheetController?.saveDocumentFileDataAndTransition(
            documentUploader: documentUploader
        ) { [weak self] in
            self?.state = .scanned(lastDocumentSide, lastImage)
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

@available(iOSApplicationExtension, unavailable)
extension DocumentCaptureViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard case let .scanning(documentSide, _) = state,
              let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let cgImage = pixelBuffer.cgImage()
        else {
            return
        }

        scanner.scanImage(
            pixelBuffer: pixelBuffer,
            cameraSession: cameraSession,
            completeOn: .main
        ) { [weak self] scannerOutput in
            // The completion block could get called after we've already found
            // a high quality image for this document side or timed out, so
            // verify that we're still scanning for the same document side
            // before handling the image.
            guard let self = self,
                  case .scanning(documentSide, _) = self.state
            else {
                return
            }
            self.handleScannedImage(
                image: cgImage,
                scannerOutput: scannerOutput,
                documentSide: documentSide
            )
        }
    }
}

// MARK: - IdentityDataCollecting

@available(iOSApplicationExtension, unavailable)
extension DocumentCaptureViewController: IdentityDataCollecting {
    var collectedFields: Set<VerificationPageFieldType> {
        // Note: Always include the document back, even if the document type
        // doesn't have a back. The initial VerificationPage request is made
        // before the user selects which document type they've selected, so it
        // will always include the back. Including `idDocumentBack` here ensures
        // that the user isn't erroneously prompted to scan their document twice.
        return [.idDocumentFront, .idDocumentBack]
    }
}

// MARK: - DocumentSide

private extension DocumentSide {
    func nextSide(for documentType: DocumentType) -> DocumentSide? {
        switch (documentType, self) {
        case (.drivingLicense, .front),
            (.idCard, .front):
            return .back
        case (.passport, _),
            (.drivingLicense, .back),
            (.idCard, .back):
            return nil
        }
    }
}
