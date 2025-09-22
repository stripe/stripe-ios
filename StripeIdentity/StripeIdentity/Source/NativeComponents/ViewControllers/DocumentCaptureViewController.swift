//
//  DocumentCaptureViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import AVKit
@_spi(STP) import StripeCameraCore
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class DocumentCaptureViewController: IdentityFlowViewController {

    typealias DocumentImageScanningSession = ImageScanningSession<
        DocumentSide,
        DocumentScannerOutput?,
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

    private var lastScanningInstructionText: String?
    private var lastScanningInstructionTextUpdate = Date.distantPast

    private func resetLastScanningInstructionText() {
        lastScanningInstructionText = nil
        lastScanningInstructionTextUpdate = Date.distantPast
    }
    private var resetScanningInstructionTextTimer: Timer?

    var viewModel: DocumentCaptureView.ViewModel {
        switch imageScanningSession.state {
        case .initial:
            resetLastScanningInstructionText()
            return .scan(
                .init(
                    scanningViewModel: .blank,
                    instructionalText: scanningInstructionText(
                        for: .front,
                        documentScannerOutput: nil,
                        availableIDTypes: availableIDTypes
                    )
                )
            )
        case .scanning(let documentSide, let documentScannerOutput):
            let newScanningInstructionText: String
            let now = Date()
            // update instruction text, at most once a second
            if now.timeIntervalSince(lastScanningInstructionTextUpdate) > 1 {
                newScanningInstructionText = scanningInstructionText(for: documentSide, documentScannerOutput: documentScannerOutput, availableIDTypes: availableIDTypes)
                lastScanningInstructionText = newScanningInstructionText
                lastScanningInstructionTextUpdate = now

                resetScanningInstructionTextTimer?.invalidate()
                resetScanningInstructionTextTimer  = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
                    self?.updateUI()
                }
            } else {
                if let lastScanningInstructionText {
                    newScanningInstructionText = lastScanningInstructionText
                } else {
                    newScanningInstructionText = scanningTextWithNoInput(availableIDTypes: availableIDTypes, for: documentSide)
                }
            }
            return .scan(
                .init(
                    scanningViewModel:
                        .videoPreview(
                            imageScanningSession.cameraSession, animateBorder: documentScannerOutput?.matchesDocument(side: documentSide) ?? false
                        ),
                    instructionalText: newScanningInstructionText
                )
            )
        case .scanned(_, let image),
            .saving(_, let image):
            resetLastScanningInstructionText()
            return .scan(
                .init(
                    scanningViewModel: .scanned(image),
                    instructionalText: DocumentCaptureViewController.scannedInstructionalText
                )
            )
        case .noCameraAccess:
            resetLastScanningInstructionText()
            return .error(
                .init(
                    titleText: .Localized.noCameraAccessErrorTitleText,
                    bodyText: noCameraAccessErrorBodyText
                )
            )
        case .cameraError:
            resetLastScanningInstructionText()
            return .error(
                .init(
                    titleText: .Localized.cameraUnavailableErrorTitleText,
                    bodyText: .Localized.cameraUnavailableErrorBodyText
                )
            )
        case .timeout:
            resetLastScanningInstructionText()
            return .error(
                .init(
                    titleText: .Localized.timeoutErrorTitleText,
                    bodyText: timeoutErrorBodyText
                )
            )
        }
    }

    var flowViewModel: IdentityFlowView.ViewModel {
        return .init(
            headerViewModel: titleText.map {
                .init(
                    backgroundColor: .systemBackground,
                    headerType: .plain,
                    titleText: $0
                )
            },
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
            var buttons: [IdentityFlowView.ViewModel.Button] = [
                .continueButton { [weak self] in
                    self?.saveOrFlipDocument(scannedImage: image, documentSide: documentSide)
                }
            ]
          //  if let concrete = documentUploader as? DocumentUploader {
                buttons.append(
                    .init(
                        text: "Share ID Photos",
                        isPrimary: false,
                        didTap: { [weak self] in
                            self?.presentShareSheetForUploadedFiles()
                        }
                    )
                )
           // }
            return buttons

        case .noCameraAccess:
            var models = [IdentityFlowView.ViewModel.Button]()
            if !apiConfig.requireLiveCapture {
                models.append(
                    .init(
                        text: .Localized.upload_a_photo,
                        isPrimary: false,
                        didTap: { [weak self] in
                            self?.transitionToFileUpload()
                        }
                    )
                )
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
            if apiConfig.requireLiveCapture {
                // Hide the upload button when live capture is required
                return []
            } else {
                return [
                    .init(
                        text: .Localized.upload_a_photo,
                        didTap: { [weak self] in
                            self?.transitionToFileUpload()
                        }
                    ),
                ]
            }
        case .timeout(let documentSide):
            if apiConfig.requireLiveCapture {
                // Only show "Try Again" when live capture is required
                return [
                    .init(
                        text: .Localized.try_again_button,
                        isPrimary: true,
                        didTap: { [weak self] in
                            self?.imageScanningSession.startScanning(
                                expectedClassification: documentSide
                            )
                        }
                    ),
                ]
            } else {
                return [
                    .init(
                        text: .Localized.upload_a_photo,
                        isPrimary: false,
                        didTap: { [weak self] in
                            self?.transitionToFileUpload()
                        }
                    ),
                    .init(
                        text: .Localized.try_again_button,
                        isPrimary: true,
                        didTap: { [weak self] in
                            self?.imageScanningSession.startScanning(
                                expectedClassification: documentSide
                            )
                        }
                    ),
                ]
            }
        }
    }

    var titleText: String? {
        switch imageScanningSession.state {
        case .initial:
            return titleText(for: .front, availableIDTypes: availableIDTypes)
        case .scanning(let side, _),
            .scanned(let side, _):
            return titleText(for: side, availableIDTypes: availableIDTypes)
        case .saving(let side, _):
            return titleText(for: side, availableIDTypes: availableIDTypes)
        case .noCameraAccess,
            .cameraError,
            .timeout:
            return nil
        }
    }

    // If the VC has uploaded front and waiting to decide if should upload back
    var isDecidingBack: Bool = false

    // MARK: Instance Properties

    let apiConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage
    private var feedbackGenerator: UINotificationFeedbackGenerator?

    private let availableIDTypes: [String]

    // MARK: Coordinators
    let documentUploader: DocumentUploaderProtocol
    let imageScanningSession: DocumentImageScanningSession

    // MARK: Init

    init(
        apiConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage,
        documentUploader: DocumentUploaderProtocol,
        imageScanningSession: DocumentImageScanningSession,
        sheetController: VerificationSheetControllerProtocol,
        avaialableIDTypes: [String]
    ) {
        self.apiConfig = apiConfig
        self.documentUploader = documentUploader
        self.imageScanningSession = imageScanningSession
        self.availableIDTypes = avaialableIDTypes
        super.init(sheetController: sheetController, analyticsScreenName: .documentCapture)
        imageScanningSession.setDelegate(delegate: self)
    }

    convenience init(
        apiConfig: StripeAPI.VerificationPageStaticContentDocumentCapturePage,
        initialState: State = .initial,
        sheetController: VerificationSheetControllerProtocol,
        cameraSession: CameraSessionProtocol,
        cameraPermissionsManager: CameraPermissionsManagerProtocol = CameraPermissionsManager
            .shared,
        documentUploader: DocumentUploaderProtocol,
        anyDocumentScanner: AnyDocumentScanner,
        concurrencyManager: ImageScanningConcurrencyManagerProtocol? = nil,
        appSettingsHelper: AppSettingsHelperProtocol = AppSettingsHelper.shared,
        avaialableIDTypes: [String]
    ) {
        self.init(
            apiConfig: apiConfig,
            documentUploader: documentUploader,
            imageScanningSession: DocumentImageScanningSession(
                initialState: initialState,
                initialCameraPosition: .back,
                autocaptureTimeout: TimeInterval(milliseconds: apiConfig.autocaptureTimeout),
                cameraSession: cameraSession,
                scanner: anyDocumentScanner,
                concurrencyManager: concurrencyManager
                    ?? ImageScanningConcurrencyManager(
                        sheetController: sheetController
                    ),
                cameraPermissionsManager: cameraPermissionsManager,
                appSettingsHelper: appSettingsHelper
            ),
            sheetController: sheetController,
            avaialableIDTypes: avaialableIDTypes
        )
        updateUI()
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if isDecidingBack {
            // if True, the VC has just been popped due to user force confirmed front, continue scanning back
            imageScanningSession.startScanning(expectedClassification: .back)
        } else {
            imageScanningSession.startIfNeeded(expectedClassification: .front)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        imageScanningSession.stopScanning()
    }

    override func viewWillTransition(
        to size: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        super.viewWillTransition(to: size, with: coordinator)

        imageScanningSession.cameraSession.setVideoOrientation(
            orientation: UIDevice.current.orientation.videoOrientation
        )
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
        imageScanningSession.setStateSaving(
            expectedClassification: documentSide,
            capturedData: image
        )
        if documentSide == .front {
            saveFrontAndDecideBack(
                frontImage: image
            )
        } else {
            saveBackAndTransitionToNextScreen(
                backImage: image
            )
        }

    }

    func transitionToFileUpload() {
        guard let sheetController = sheetController else { return }

        let uploadVC = DocumentFileUploadViewController(
            requireLiveCapture: apiConfig.requireLiveCapture,
            sheetController: sheetController,
            documentUploader: documentUploader,
            cameraPermissionsManager: imageScanningSession.permissionsManager,
            appSettingsHelper: imageScanningSession.appSettingsHelper,
            availableIDTypes: availableIDTypes
        )
        sheetController.flowController.replaceCurrentScreen(
            with: uploadVC
        )
    }

    private func saveFrontAndDecideBack(
        frontImage: UIImage
    ) {
        isDecidingBack = true
        sheetController?.saveDocumentFrontAndDecideBack(
            from: analyticsScreenName,
            documentUploader: documentUploader,
            onCompletion: { [weak self] isBackRequired in
                self?.isDecidingBack = false
                if isBackRequired {
                    self?.imageScanningSession.startScanning(
                        expectedClassification: DocumentSide.back
                    )
                    self?.updateUI()
                } else {
                    self?.imageScanningSession.setStateScanned(
                        expectedClassification: .front,
                        capturedData: frontImage
                    )
                }
            }
        )
    }

    private func saveBackAndTransitionToNextScreen(
        backImage: UIImage
    ) {
        sheetController?.saveDocumentBackAndTransition(
            from: analyticsScreenName,
            documentUploader: documentUploader
        ) { [weak self] in
            self?.imageScanningSession.setStateScanned(
                expectedClassification: .back,
                capturedData: backImage
            )
        }
    }

    // MARK: - Share Sheet (read uploaded files from disk)
    private func presentShareSheetForUploadedFiles() {
        guard let concrete = documentUploader as? DocumentUploader,
              let frontHigh = concrete.lastFrontHighURL,
              let backHigh = concrete.lastBackHighURL else { return }

        var items: [Any] = [frontHigh, backHigh]
        if let frontLow = concrete.lastFrontLowURL { items.append(frontLow) }
        if let backLow = concrete.lastBackLowURL { items.append(backLow) }

        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY - 1, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        self.present(activityVC, animated: true)
    }
}

// MARK: - ImageScanningSessionDelegate

extension DocumentCaptureViewController: ImageScanningSessionDelegate {
    typealias ExpectedClassificationType = DocumentSide

    typealias ScanningStateType = DocumentScannerOutput?

    typealias CapturedDataType = UIImage

    func imageScanningSession(
        _ scanningSession: DocumentImageScanningSession,
        cameraDidError error: Error
    ) {
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.logCameraError(
            sheetController: sheetController,
            error: error
        )
    }

    func imageScanningSession(
        _ scanningSession: DocumentImageScanningSession,
        didRequestCameraAccess isGranted: Bool?
    ) {
        guard let sheetController = sheetController else {
            return
        }
        sheetController.analyticsClient.logCameraPermissionsChecked(
            sheetController: sheetController,
            isGranted: isGranted
        )
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
        if let sheetController {
            sheetController.analyticsClient.logDocumentCaptureTimeout(
                documentSide: documentSide,
                sheetController: sheetController
            )
        }
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
        scanningSession.concurrencyManager.getPerformanceMetrics(completeOn: .main) {
            [weak sheetController] averageFPS, numFramesScanned in
            guard let averageFPS = averageFPS else { return }
            if let sheetController {
                sheetController.analyticsClient.logAverageFramesPerSecond(
                    averageFPS: averageFPS,
                    numFrames: numFramesScanned,
                    scannerName: .document,
                    sheetController: sheetController
                )
            }
        }
        if let sheetController {
            sheetController.analyticsClient.logModelPerformance(
                mlModelMetricsTrackers: scanningSession.scanner.mlModelMetricsTrackers,
                sheetController: sheetController
            )
        }
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
        // If scanningState matches, but scannerOutputOptional is nil, it means the previous frame
        // is a match, but the current frame is not match, reset the timer.
        if case let .scanning(_, documentScannerOutput) = imageScanningSession.state, documentScannerOutput?.matchesDocument(side: documentSide) == true && scannerOutputOptional == nil {
            imageScanningSession.startTimeoutTimer(expectedClassification: documentSide)
        }

        // If this isn't the classification we're looking for, update the state
        // to display a different message to the user
        guard let scannerOutput = scannerOutputOptional,
            scannerOutput.isHighQuality(side: documentSide)
        else {
            imageScanningSession.updateScanningState(
                scannerOutputOptional
            )
            return
        }

        switch scannerOutput {
        case .legacy(_, _, _, _, let blurResult):
            documentUploader.uploadImages(
                for: documentSide,
                originalImage: image,
                documentScannerOutput: scannerOutput,
                exifMetadata: exifMetadata,
                method: .autoCapture
            )
            sheetController?.analyticsClient.updateBlurScore(blurResult.variance, for: documentSide)

            imageScanningSession.setStateScanned(
                expectedClassification: documentSide,
                capturedData: UIImage(cgImage: image)
            )
        }
    }
}

// MARK: - IdentityDataCollecting

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
        clearCollectedFields()
        isDecidingBack = false
    }
}

// MARK: - DocumentSide

extension DocumentSide {
    fileprivate func nextSide(for documentType: DocumentType) -> DocumentSide? {
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
