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
        case .noCameraAccess:
            return .error("We need permission to use your camera. Please allow camera access in app settings.")
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
                    didTap: {
                        // TODO(mludowise): Switch to upload VC
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

    // MARK: Coordinators
    let scanner: DocumentScannerProtocol
    let permissionsManager: CameraPermissionsManagerProtocol

    // TODO(mludowise|IDPROD-2774): Replace mock camera feed with VideoFeed
    let cameraFeed: MockIdentityDocumentCameraFeed

    let appSettingsHelper: AppSettingsHelperProtocol

    // MARK: Captured Images

    // The captured front document images to be saved to the API when continuing
    // from this screen
    var frontUploadFuture: Future<VerificationPageDataDocumentFileData?> = Promise(value: nil)
    var backUploadFuture: Future<VerificationPageDataDocumentFileData?> = Promise(value: nil)

    // MARK: Init

    convenience init(
        apiConfig: VerificationPageStaticContentDocumentCapturePage,
        documentType: DocumentType,
        sheetController: VerificationSheetControllerProtocol,
        cameraFeed: MockIdentityDocumentCameraFeed,
        cameraPermissionsManager: CameraPermissionsManagerProtocol = CameraPermissionsManager.shared,
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
        documentScanner: DocumentScannerProtocol,
        appSettingsHelper: AppSettingsHelperProtocol
    ) {
        self.apiConfig = apiConfig
        self.documentType = documentType
        self.state = initialState
        self.cameraFeed = cameraFeed
        self.permissionsManager = cameraPermissionsManager
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
        cameraFeed.getCurrentFrame().chained { [weak scanner] pixelBuffer in
            return scanner?.scanImage(
                pixelBuffer: pixelBuffer,
                desiredClassification: classification,
                completeOn: .main
            ) ?? Promise<CVPixelBuffer>()
        }.observe { [weak self] result in
            switch result {
            case .success(let pixelBuffer):
                self?.handleScannedImage(pixelBuffer: pixelBuffer)
            case .failure:
                // TODO(mludowise|IDPROD-2482): Handle error
                break
            }
        }
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

        guard let sheetController = sheetController else {
            return
        }

        // Transform Future to return a `DocumentImage` containing the file ID and UIImage
        let imageUploadFuture: Future<VerificationPageDataDocumentFileData?> = sheetController.uploadDocument(image: uiImage).chained { fileId in
            // TODO(mludowise|IDPROD-2482): Crop image to bounds and add scores returned by ML model
            return Promise(value: .init(
                backScore: nil,
                frontCardScore: nil,
                highResImage: fileId,
                invalidScore: nil,
                lowResImage: nil,
                noDocumentScore: nil,
                passportScore: nil,
                uploadMethod: .autoCapture,
                _additionalParametersStorage: nil
            ))
        }

        if classification.isFront {
            frontUploadFuture = imageUploadFuture
        } else {
            backUploadFuture = imageUploadFuture
        }
    }

    func saveOrFlipDocument(scannedImage image: UIImage, classification: DocumentScanner.Classification) {
        if let nextClassification = classification.nextClassification {
            state = .interstitial(nextClassification)
        } else {
            state = .saving(lastImage: image)
            saveDataAndTransition(lastClassification: classification, lastImage: image)
        }
    }

    func saveDataAndTransition(lastClassification: DocumentScanner.Classification, lastImage: UIImage) {
        frontUploadFuture.chained { [weak self] frontFileData in
            // Front upload is complete, update dataStore
            self?.sheetController?.dataStore.frontDocumentFileData = frontFileData
            return self?.backUploadFuture ?? Promise(value: nil)
        }.chained { [weak sheetController] (backFileData: VerificationPageDataDocumentFileData?) -> Future<()> in
            // Back upload is complete, update dataStore
            sheetController?.dataStore.backDocumentFileData = backFileData
            return Promise(value: ())
        }.observe { [weak self] _ in
            // Both front & back uploads are complete, save data
            guard let sheetController = self?.sheetController else { return }
            sheetController.saveData { apiContent in
                // TODO(IDPROD-2756): Ideally, the state would get set after the
                // VC is done transitioning so the button remains disabled until
                // it's disappeared from view
                self?.state = .scanned(lastClassification, lastImage)
                sheetController.flowController.transitionToNextScreen(
                    apiContent: apiContent,
                    sheetController: sheetController
                )
            }
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
