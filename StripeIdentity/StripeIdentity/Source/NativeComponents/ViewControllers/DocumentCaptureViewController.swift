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
    enum State {
        /// Displays an interstitial image with instruction on how to scan the document
        case interstitial(DocumentScanner.Classification)
        /// Actively scanning the camera feed for the specified classification
        case scanning(DocumentScanner.Classification)
        /// Successfully scanned the camera feed for the specified classification
        case scanned(DocumentScanner.Classification, UIImage)
        /// Saving the captured data
        case saving(lastImage: UIImage)
        /// The app does not have camera access
        case noCameraAccess
        /// Scanning timed out
        case timeout(DocumentScanner.Classification)
    }

    private(set) var state: State {
        didSet {
            if case let .scanning(classification) = state {
                startScanning(for: classification)
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
                state: .videoPreview,
                instructionalText: "Position your card in the center of the frame"
            ))
        case .scanning(.passport):
            return .scan(.init(
                state: .videoPreview,
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
        case .timeout:
            return .error("We could not capture a high-quality image.")
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
                        self?.requestPermissionsAndStartScanning(for: classification)
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
                        self?.state = .scanning(classification)
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
    private(set) var timeoutTimer: Timer?

    // MARK: Coordinators
    let scanner: DocumentScannerProtocol
    let permissionsManager: CameraPermissionsManagerProtocol

    // TODO(mludowise|IDPROD-2774): Replace mock camera feed with VideoFeed
    let cameraFeed: MockIdentityDocumentCameraFeed

    let appSettingsHelper: AppSettingsHelperProtocol
    let documentUploader: DocumentUploaderProtocol

    // MARK: Init

    convenience init(
        apiConfig: VerificationPageStaticContentDocumentCapturePage,
        documentType: DocumentType,
        sheetController: VerificationSheetControllerProtocol,
        cameraFeed: MockIdentityDocumentCameraFeed,
        cameraPermissionsManager: CameraPermissionsManagerProtocol = CameraPermissionsManager.shared,
        documentUploader: DocumentUploaderProtocol,
        documentScanner: DocumentScannerProtocol = DocumentScanner(),
        appSettingsHelper: AppSettingsHelperProtocol = AppSettingsHelper.shared
    ) {
        self.init(
            apiConfig: apiConfig,
            documentType: documentType,
            initialState: .interstitial(documentType.initialScanClassification),
            sheetController: sheetController,
            cameraFeed: cameraFeed,
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
        cameraFeed: MockIdentityDocumentCameraFeed,
        cameraPermissionsManager: CameraPermissionsManagerProtocol,
        documentUploader: DocumentUploaderProtocol,
        documentScanner: DocumentScannerProtocol,
        appSettingsHelper: AppSettingsHelperProtocol
    ) {
        self.apiConfig = apiConfig
        self.documentType = documentType
        self.state = initialState
        self.cameraFeed = cameraFeed
        self.permissionsManager = cameraPermissionsManager
        self.documentUploader = documentUploader
        self.scanner = documentScanner
        self.appSettingsHelper = appSettingsHelper
        super.init(sheetController: sheetController)
        updateUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // TODO(mludowise|IDPROD-2815): Warn user they will lose saved data when
    // they hit the back button
}

// MARK: - Helpers

@available(iOSApplicationExtension, unavailable)
extension DocumentCaptureViewController {
    func updateUI() {
        // TODO(mludowise|IDPROD-2756): Update and localize text when designs are final
        configure(
            title: titleText,
            backButtonTitle: "Scan",
            viewModel: flowViewModel
        )
        documentCaptureView.configure(with: viewModel)
    }

    func requestPermissionsAndStartScanning(
        for classification: DocumentScanner.Classification
    ) {
        permissionsManager.requestCameraAccess(completeOnQueue: .main) { [weak self] granted in
            self?.state = (granted == true)
                ? .scanning(classification)
                : .noCameraAccess
        }
    }

    func startScanning(for classification: DocumentScanner.Classification) {
        timeoutTimer?.invalidate()
        timeoutTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(apiConfig.autocaptureTimeout) / 1000,
            repeats: false
        ) { [weak self] _ in
            self?.handleTimeout(for: classification)
        }
        cameraFeed.getCurrentFrame().chained { [weak scanner] pixelBuffer in
            return scanner?.scanImage(
                pixelBuffer: pixelBuffer,
                desiredClassification: classification,
                completeOn: .main
            ) ?? Promise<CVPixelBuffer>()
        }.observe { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let pixelBuffer):
                self.handleScannedImage(pixelBuffer: pixelBuffer)
                self.timeoutTimer?.invalidate()
            case .failure:
                // TODO(mludowise|IDPROD-2482): Handle error
                break
            }
        }
    }

    func handleTimeout(for classification: DocumentScanner.Classification) {
        scanner.cancelScan()
        state = .timeout(classification)
    }

    /// Starts uploading an image as soon as it's been scanned
    func handleScannedImage(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let uiImage = UIImage(ciImage: ciImage)

        guard case let .scanning(classification) = state else {
            assertionFailure("state is '\(state)' but expected 'scanning'")
            return
        }

        // Set state back to scanned when we're done
        defer {
            state = .scanned(classification, uiImage)
        }

        // TODO(mludowise|IDPROD-2482): Get document bounds from ML model
        documentUploader.uploadImages(
            for: classification.isFront ? .front : .back,
            originalImage: ciImage,
            documentBounds: nil,
            method: .autoCapture
        )
    }

    func saveOrFlipDocument(scannedImage image: UIImage, classification: DocumentScanner.Classification) {
        if let nextClassification = classification.nextClassification {
            state = .interstitial(nextClassification)
        } else {
            state = .saving(lastImage: image)
            saveDataAndTransition(lastClassification: classification, lastImage: image)
        }
    }

    func transitionToFileUpload() {
        // TODO(mludowise): Switch to upload VC
        print("Transition to File Upload")
    }

    func saveDataAndTransition(lastClassification: DocumentScanner.Classification, lastImage: UIImage) {
        sheetController?.saveDocumentFileData(documentUploader: documentUploader) { [weak self] apiContent in
            guard let self = self,
                  let sheetController = self.sheetController else {
                return
            }

            self.state = .scanned(lastClassification, lastImage)
            sheetController.flowController.transitionToNextScreen(
                apiContent: apiContent,
                sheetController: sheetController
            )
        }
    }
}

// MARK: - DocumentType

extension VerificationPageDataIDDocument.DocumentType {
    var initialScanClassification: DocumentScanner.Classification {
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

extension DocumentScanner.Classification {
    var isFront: Bool {
        switch self {
        case .idCardFront,
             .passport:
            return true
        case .idCardBack:
            return false
        }
    }

    var nextClassification: DocumentScanner.Classification? {
        switch self {
        case .idCardFront:
            return .idCardBack
        case .idCardBack,
             .passport:
            return nil
        }
    }
}
