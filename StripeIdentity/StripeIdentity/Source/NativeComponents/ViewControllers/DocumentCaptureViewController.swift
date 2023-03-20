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

    typealias DocumentImageScanningSession = ImageScanningSession<
        DocumentSide,
        Optional<IDDetectorOutput.Classification>,
        UIImage,
        DocumentScannerOutput?
    >
    typealias State = DocumentImageScanningSession.State

    override var warningAlertViewModel: WarningAlertViewModel? {
        switch imageScanningSession.state {
        case .saving,
             .scanned,
             .scanning(.back, _),
             .timeout(.back):
            return .init(
                titleText: .Localized.unsavedChanges,
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
        switch imageScanningSession.state {
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
                    imageScanningSession.cameraSession,
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
                titleText: .Localized.noCameraAccessErrorTitleText,
                bodyText: noCameraAccessErrorBodyText
            ))
        case .cameraError:
            return .error(.init(
                titleText: .Localized.cameraUnavailableErrorTitleText,
                bodyText: .Localized.cameraUnavailableErrorBodyText
            ))
        case .timeout:
            return .error(.init(
                titleText: .Localized.timeoutErrorTitleText,
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
        switch imageScanningSession.state {
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
                    text: .Localized.file_upload_button,
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
                        self?.imageScanningSession.appSettingsHelper.openAppSettings()
                    }
                )
            )
            return models
        case .cameraError:
            return [
                .init(
                    text: .Localized.file_upload_button,
                    didTap: { [weak self] in
                        self?.transitionToFileUpload()
                    }
                )
            ]
        case .timeout(let documentSide):
            return [
                .init(
                    text: .Localized.file_upload_button,
                    isPrimary: false,
                    didTap: { [weak self] in
                        self?.transitionToFileUpload()
                    }
                ),
                .init(
                    text: .Localized.try_again_button,
                    isPrimary: true,
                    didTap: { [weak self] in
                        self?.imageScanningSession.startScanning(expectedClassification: documentSide)
                    }
                ),
            ]
        }
    }

    var titleText: String? {
        switch imageScanningSession.state {
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

    let apiConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage
    let documentType: DocumentType
    private var feedbackGenerator: UINotificationFeedbackGenerator?

    // MARK: Coordinators
    let documentUploader: DocumentUploaderProtocol
    let imageScanningSession: DocumentImageScanningSession

    // MARK: Init

    init(
        apiConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage,
        documentType: DocumentType,
        documentUploader: DocumentUploaderProtocol,
        imageScanningSession: DocumentImageScanningSession,
        sheetController: VerificationSheetControllerProtocol
    ) {
        self.apiConfig = apiConfig
        self.documentType = documentType
        self.documentUploader = documentUploader
        self.imageScanningSession = imageScanningSession
        super.init(sheetController: sheetController, analyticsScreenName: .documentCapture)
        imageScanningSession.setDelegate(delegate: self)
    }

    convenience init(
        apiConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage,
        documentType: DocumentType,
        initialState: State = .initial,
        sheetController: VerificationSheetControllerProtocol,
        cameraSession: CameraSessionProtocol,
        cameraPermissionsManager: CameraPermissionsManagerProtocol = CameraPermissionsManager.shared,
        documentUploader: DocumentUploaderProtocol,
        anyDocumentScanner: AnyDocumentScanner,
        concurrencyManager: ImageScanningConcurrencyManagerProtocol? = nil,
        appSettingsHelper: AppSettingsHelperProtocol = AppSettingsHelper.shared
    ) {
        self.init(
            apiConfig: apiConfig,
            documentType: documentType,
            documentUploader: documentUploader,
            imageScanningSession: DocumentImageScanningSession(
                initialState: initialState,
                initialCameraPosition: .back,
                autocaptureTimeout: TimeInterval(milliseconds: apiConfig.autocaptureTimeout),
                cameraSession: cameraSession,
                scanner: anyDocumentScanner,
                concurrencyManager: concurrencyManager ?? ImageScanningConcurrencyManager(analyticsClient: sheetController.analyticsClient),
                cameraPermissionsManager: cameraPermissionsManager,
                appSettingsHelper: appSettingsHelper
            ),
            sheetController: sheetController
        )
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        imageScanningSession.startIfNeeded(expectedClassification: .front)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageScanningSession.stopScanning()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        imageScanningSession.cameraSession.setVideoOrientation(orientation: UIDevice.current.orientation.videoOrientation)
    }

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
        generateFeedbackIfNeededForStateChange()
    }

    func generateFeedbackIfNeededForStateChange() {
        guard case .scanned = imageScanningSession.state else {
            return
        }

        feedbackGenerator?.notificationOccurred(.success)
    }

    // MARK: - State Transitions

    func saveOrFlipDocument(scannedImage image: UIImage, documentSide: DocumentSide) {
        if let nextSide = documentSide.nextSide(for: documentType) {
            imageScanningSession.startScanning(expectedClassification: nextSide)
        } else {
            imageScanningSession.setStateSaving(image)
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
            cameraPermissionsManager: imageScanningSession.permissionsManager,
            appSettingsHelper: imageScanningSession.appSettingsHelper
        )
        sheetController.flowController.replaceCurrentScreen(
            with: uploadVC
        )
    }

    func saveDataAndTransitionToNextScreen(
        lastDocumentSide: DocumentSide,
        lastImage: UIImage
    ) {
        sheetController?.saveDocumentFileDataAndTransition(
            from: analyticsScreenName,
            documentUploader: documentUploader
        ) { [weak self] in
            self?.imageScanningSession.setStateScanned(
                expectedClassification: lastDocumentSide,
                capturedData: lastImage
            )
        }
    }
}

// MARK: - ImageScanningSessionDelegate

@available(iOSApplicationExtension, unavailable)
extension DocumentCaptureViewController: ImageScanningSessionDelegate {
    typealias ExpectedClassificationType = DocumentSide

    typealias ScanningStateType = IDDetectorOutput.Classification?

    typealias CapturedDataType = UIImage

    func imageScanningSession(_ scanningSession: DocumentImageScanningSession, cameraDidError error: Error) {
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.logCameraError(sheetController: sheetController, error: error)
    }

    func imageScanningSession(_ scanningSession: DocumentImageScanningSession, didRequestCameraAccess isGranted: Bool?) {
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.logCameraPermissionsChecked(sheetController: sheetController, isGranted: isGranted)
    }

    func imageScanningSessionDidUpdate(_ scanningSession: DocumentImageScanningSession) {
        updateUI()
        // Notify accessibility engine that the layout has changed
        UIAccessibility.post(notification: .layoutChanged, argument: nil)
    }

    func imageScanningSessionDidReset(_ scanningSession: DocumentImageScanningSession) {
        documentUploader.reset()
    }

    func imageScanningSession(
        _ scanningSession: DocumentImageScanningSession,
        didTimeoutForClassification documentSide: DocumentSide
    ) {
        sheetController?.analyticsClient.logDocumentCaptureTimeout(
            idDocumentType: documentType,
            documentSide: documentSide
        )
    }

    func imageScanningSession(
        _ scanningSession: DocumentImageScanningSession,
        willStartScanningForClassification documentSide: DocumentSide
    ) {
        // Focus the accessibility VoiceOver back onto the capture view
        UIAccessibility.post(notification: .layoutChanged, argument: self.documentCaptureView)

        // Prepare feedback generators
        self.feedbackGenerator = UINotificationFeedbackGenerator()
        self.feedbackGenerator?.prepare()

        // Increment analytics counter
        sheetController?.analyticsClient.countDidStartDocumentScan(for: documentSide)
    }

    func imageScanningSessionWillStopScanning(_ scanningSession: DocumentImageScanningSession) {
        scanningSession.concurrencyManager.getPerformanceMetrics(completeOn: .main) { [weak sheetController] averageFPS, numFramesScanned in
            guard let averageFPS = averageFPS else { return }
            sheetController?.analyticsClient.logAverageFramesPerSecond(
                averageFPS: averageFPS,
                numFrames: numFramesScanned,
                scannerName: .document
            )
        }
        sheetController?.analyticsClient.logModelPerformance(
            mlModelMetricsTrackers: scanningSession.scanner.mlModelMetricsTrackers
        )
    }

    func imageScanningSessionDidStopScanning(_ scanningSession: DocumentImageScanningSession) {
        feedbackGenerator = nil
    }

    func imageScanningSessionDidScanImage(
        _ scanningSession: DocumentImageScanningSession,
        image: CGImage,
        scannerOutput scannerOutputOptional: DocumentScannerOutput?,
        exifMetadata: CameraExifMetadata?,
        expectedClassification documentSide: DocumentSide
    ) {
        // If this isn't the classification we're looking for, update the state
        // to display a different message to the user
        guard let scannerOutput = scannerOutputOptional,
              scannerOutput.isHighQuality(matchingDocumentType: documentType, side: documentSide)
        else {
            imageScanningSession.updateScanningState(scannerOutputOptional?.idDetectorOutput.classification)
            return
        }

        documentUploader.uploadImages(
            for: documentSide,
            originalImage: image,
            documentScannerOutput: scannerOutput,
            exifMetadata: exifMetadata,
            method: .autoCapture
        )

        imageScanningSession.setStateScanned(
            expectedClassification: documentSide,
            capturedData: UIImage(cgImage: image)
        )
    }
}


// MARK: - IdentityDataCollecting

@available(iOSApplicationExtension, unavailable)
extension DocumentCaptureViewController: IdentityDataCollecting {
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        // Note: Always include the document back, even if the document type
        // doesn't have a back. The initial VerificationPage request is made
        // before the user selects which document type they've selected, so it
        // will always include the back. Including `idDocumentBack` here ensures
        // that the user isn't erroneously prompted to scan their document twice.
        return [.idDocumentFront, .idDocumentBack]
    }

    func reset() {
        imageScanningSession.reset(to: .front)
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
