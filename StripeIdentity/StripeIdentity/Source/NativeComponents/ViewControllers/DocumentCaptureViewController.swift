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

    typealias DocumentType = VerificationPageDataIDDocument.DocumentType

    // MARK: State

    /// Possible UI states for this screen
    enum State: Equatable {
        /// Displays an interstitial image with instruction on how to scan the document
        case interstitial(DesiredDocumentClassification)
        /// Actively scanning the camera feed for the specified classification
        case scanning(DesiredDocumentClassification)
        /// Successfully scanned the camera feed for the specified classification
        case scanned(DesiredDocumentClassification, UIImage)
        /// Saving the captured data
        case saving(lastImage: UIImage)
        /// The app does not have camera access
        case noCameraAccess
        /// There was an error accessing the camera
        case cameraError
        /// Scanning timed out
        case timeout(DesiredDocumentClassification)
    }

    private(set) var state: State {
        didSet {
            guard state != oldValue else {
                return
            }

            if case .scanning = oldValue {
                stopScanning()
            }

            updateUI()
        }
    }

    // MARK: Views

    let documentCaptureView = DocumentCaptureView()

    // MARK: Computed Properties

    var viewModel: DocumentCaptureView.ViewModel {
        // TODO(mludowise|IDPROD-2756): Update and localize text when designs are final
        switch state {
        case .interstitial(.idCardFront),
             .interstitial(.passport):
            return .scan(.init(
                state: .staticImage(
                    Image.illustrationIdCardFront.makeImage(),
                    contentMode: .scaleAspectFit
                ),
                instructionalText: permissionsManager.hasCameraAccess
                    ? "Get ready to scan your identity document"
                    : "When prompted, tap OK to allow"
            ))
        case .interstitial(.idCardBack):
            return .scan(.init(
                state: .staticImage(
                    Image.illustrationIdCardBack.makeImage(),
                    contentMode: .scaleAspectFit
                ),
                instructionalText: "Flip card over to the other side"
            ))
        case .scanning(.idCardFront),
             .scanning(.idCardBack):
            return .scan(.init(
                state: .videoPreview(cameraSession),
                instructionalText: "Position your card in the center of the frame"
            ))
        case .scanning(.passport):
            return .scan(.init(
                state: .videoPreview(cameraSession),
                instructionalText: "Position your passport in the center of the frame"
            ))
        case .scanned(_, let image),
             .saving(let image):
            // TODO(mludowise|IDPROD-2756): Display some sort of loading indicator during "Saving" while we wait for the files to finish uploading
            return .scan(.init(
                state: .staticImage(image, contentMode: .scaleAspectFill),
                instructionalText: "✓ Scanned"
            ))
        case .noCameraAccess where apiConfig.requireLiveCapture:
            return .error("We need permission to use your camera. Please allow camera access in app settings.")
        case .noCameraAccess:
            return .error("We need permission to use your camera. Please allow camera access in app settings.\n\nAlternatively, you may manually upload a photo of your identity document.")
        case .cameraError:
            // TODO: Finalize copy with design
            return .error("There was an error accessing the camera.")
        case .timeout:
            // TODO(IDPROD-2747): Error title should be, "Could not capture image"
            return .error("We could not capture a high-quality image.\n\nYou can either try again or upload an image from your device.")
        }
    }

    var flowViewModel: IdentityFlowView.ViewModel {
        return .init(
            contentView: documentCaptureView,
            buttons: buttonViewModels
        )
    }

    var buttonViewModels: [IdentityFlowView.ViewModel.Button] {
        // TODO(mludowise|IDPROD-2756): Update and localize text when designs are final
        switch state {
        case .interstitial(let classification):
            return [
                .init(
                    text: "Continue",
                    isEnabled: true,
                    configuration: .primary(),
                    didTap: { [weak self] in
                        self?.setupCameraAndStartScanning(for: classification)
                    }
                )
            ]
        case .scanning,
             .saving:
            return [
                .init(
                    text: "Continue",
                    isEnabled: false,
                    configuration: .primary(),
                    didTap: {}
                )
            ]
        case .scanned(let classification, let image):
            return [
                .init(
                    text: "Continue",
                    isEnabled: true,
                    configuration: .primary(),
                    didTap: { [weak self] in
                        self?.saveOrFlipDocument(scannedImage: image, classification: classification)
                    }
                )
            ]
        case .noCameraAccess:
            var models = [IdentityFlowView.ViewModel.Button]()
            if !apiConfig.requireLiveCapture {
                models.append(.init(
                    text: "File Upload",
                    isEnabled: true,
                    configuration: .secondary(),
                    didTap: { [weak self] in
                        self?.transitionToFileUpload()
                    }
                ))
            }

            models.append(
                .init(
                    text: "App Settings",
                    isEnabled: true,
                    configuration: .primary(),
                    didTap: { [weak self] in
                        self?.appSettingsHelper.openAppSettings()
                    }
                )
            )
            return models
        case .cameraError:
            return []
        case .timeout(let classification):
            return [
                .init(
                    text: "Upload a Photo",
                    isEnabled: true,
                    configuration: .secondary(),
                    didTap: { [weak self] in
                        self?.transitionToFileUpload()
                    }
                ),
                .init(
                    text: "Try Again",
                    isEnabled: true,
                    configuration: .primary(),
                    didTap: { [weak self] in
                        self?.startScanning(for: classification)
                    }
                ),
            ]
        }
    }

    var titleText: String {
        // TODO(mludowise|IDPROD-2756): Update and localize text when designs are final
        switch documentType {
        case .passport:
            return "We need to take a photo of your passport"
        case .drivingLicense:
            return "We need to take a photo of your driver's license"
        case .idCard:
            return "We need to take a photo of your identity card"
        }
    }

    // MARK: Instance Properties

    let apiConfig: VerificationPageStaticContentDocumentCapturePage
    let documentType: DocumentType
    var timeoutTimer: Timer?

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
            initialState: .interstitial(documentType.initialScanClassification),
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

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        cameraSession.setVideoOrientation(orientation: UIDevice.current.orientation.videoOrientation)
    }

    // TODO(mludowise|IDPROD-2815): Warn user they will lose saved data when
    // they hit the back button
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
extension DocumentCaptureViewController {

    // MARK: - Configure

    func updateUI() {
        // TODO(mludowise|IDPROD-2756): Update and localize text when designs are final
        configure(
            title: titleText,
            backButtonTitle: "Scan",
            viewModel: flowViewModel
        )
        documentCaptureView.configure(with: viewModel)
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
        if case let .scanning(classification) = state {
            startScanning(for: classification)
        }
    }

    // MARK: - State Transitions

    func setupCameraAndStartScanning(
        for classification: DesiredDocumentClassification
    ) {
        permissionsManager.requestCameraAccess(completeOnQueue: .main) { [weak self] granted in
            guard let self = self else { return }

            guard granted == true else {
                self.state = .noCameraAccess
                return
            }

            // Configure camera session
            self.cameraSession.configureSession(
                configuration: .init(
                    initialCameraPosition: .back,
                    initialOrientation: UIDevice.current.orientation.videoOrientation,
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
                    self.startScanning(for: classification)
                case .failed:
                    // TODO(IDPROD-2816): log error from failed result
                    self.state = .cameraError
                }
            }
        }
    }

    func startScanning(for classification: DesiredDocumentClassification) {
        cameraSession.startSession(completeOn: .main) { [weak self] in
            guard let self = self else { return }
            self.timeoutTimer = Timer.scheduledTimer(
                withTimeInterval: TimeInterval(self.apiConfig.autocaptureTimeout) / 1000,
                repeats: false
            ) { [weak self] _ in
                self?.handleTimeout(for: classification)
            }

            // Wait until camera session is started before updating state or PreviewView shows stale image
            self.state = .scanning(classification)
        }
    }

    func stopScanning() {
        timeoutTimer?.invalidate()
        cameraSession.stopSession()
    }

    func handleTimeout(for classification: DesiredDocumentClassification) {
        state = .timeout(classification)
    }

    /// Starts uploading an image as soon as it's been scanned
    func handleScannedImage(
        pixelBuffer: CVPixelBuffer,
        idDetectorOutput: IDDetectorOutput,
        foundClassification: DesiredDocumentClassification
    ) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let uiImage = UIImage(ciImage: ciImage)

        documentUploader.uploadImages(
            for: foundClassification.isFront ? .front : .back,
            originalImage: ciImage,
            documentBounds: idDetectorOutput.documentBounds,
            method: .autoCapture
        )

        state = .scanned(foundClassification, uiImage)
    }

    func saveOrFlipDocument(scannedImage image: UIImage, classification: DesiredDocumentClassification) {
        if let nextClassification = classification.nextClassification {
            state = .interstitial(nextClassification)
        } else {
            state = .saving(lastImage: image)
            saveDataAndTransitionToNextScreen(lastClassification: classification, lastImage: image)
        }
    }

    func transitionToFileUpload() {
        guard let sheetController = sheetController else { return }

        let uploadVC = DocumentFileUploadViewController(
            documentType: documentType,
            requireLiveCapture: apiConfig.requireLiveCapture,
            documentUploader: documentUploader,
            cameraPermissionsManager: permissionsManager,
            appSettingsHelper: appSettingsHelper,
            sheetController: sheetController
        )
        sheetController.flowController.replaceCurrentScreen(with: uploadVC)
    }

    func saveDataAndTransitionToNextScreen(
        lastClassification: DesiredDocumentClassification,
        lastImage: UIImage
    ) {
        sheetController?.saveDocumentFileData(documentUploader: documentUploader) { [weak self] apiContent in
            guard let self = self,
                  let sheetController = self.sheetController else {
                return
            }

            sheetController.flowController.transitionToNextScreen(
                apiContent: apiContent,
                sheetController: sheetController,
                completion: {
                    self.state = .scanned(lastClassification, lastImage)
                }
            )
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
        guard case let .scanning(desiredClassification) = state,
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        scanner.scanImage(
            pixelBuffer: pixelBuffer,
            desiredClassification: desiredClassification,
            completeOn: .main
        ) { [weak self] idDetectorOutput in
            // The completion block could get called after we've already found
            // the desired classification once or timed out, so verify that
            // we're still scanning for the desired classification before
            // handling the image.
            guard let self = self,
                  case let .scanning(classification) = self.state,
                  classification == desiredClassification else {
                return
            }
            self.handleScannedImage(
                pixelBuffer: pixelBuffer,
                idDetectorOutput: idDetectorOutput,
                foundClassification: desiredClassification
            )
        }
    }
}

// MARK: - DocumentType

extension VerificationPageDataIDDocument.DocumentType {
    var initialScanClassification: DesiredDocumentClassification {
        switch self {
        case .passport:
            return .passport
        case .drivingLicense,
             .idCard:
            return .idCardFront
        }
    }
}

// MARK: - Classification

extension DesiredDocumentClassification {
    var isFront: Bool {
        switch self {
        case .idCardFront,
             .passport:
            return true
        case .idCardBack:
            return false
        }
    }

    var nextClassification: DesiredDocumentClassification? {
        switch self {
        case .idCardFront:
            return .idCardBack
        case .idCardBack,
             .passport:
            return nil
        }
    }
}
