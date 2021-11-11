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

final class DocumentCaptureViewController: IdentityFlowViewController {

    typealias DocumentType = VerificationSessionDataIDDocument.DocumentType

    // MARK: State

    /// Possible UI states for this screen
    enum State {
        /// Displays an interstitial image with instruction on how to scan the document
        case interstitial(DocumentScanner.Classification)
        /// Actively scanning the camera feed for the specified classification
        case scanning(DocumentScanner.Classification)
        /// Successfully scanned the camera feed for the specified classification
        case scanned(DocumentScanner.Classification, UIImage)
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

    let scanningView = InstructionalCameraScanningView()

    // MARK: Computed Properties

    var hasCameraPermissions: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    var scanningViewModel: InstructionalCameraScanningView.ViewModel {
        // TODO(mludowise|IDPROD-2756): Update and localize text when designs are final
        switch state {
        case .interstitial(.idCardFront),
             .interstitial(.passport):
            return .init(
                state: .staticImage(
                    Image.illustrationIdCardFront.makeImage(),
                    contentMode: .scaleAspectFit
                ),
                instructionalText: hasCameraPermissions
                    ? "Get ready to scan your identity document"
                    : "When prompted, tap OK to allow"
            )
        case .interstitial(.idCardBack):
            return .init(
                state: .staticImage(
                    Image.illustrationIdCardBack.makeImage(),
                    contentMode: .scaleAspectFit
                ),
                instructionalText: "Flip card over to the other side"
            )
        case .scanning(.idCardFront),
             .scanning(.idCardBack):
            return .init(
                state: .videoPreview,
                instructionalText: "Position your card in the center of the frame"
            )
        case .scanning(.passport):
            return .init(
                state: .videoPreview,
                instructionalText: "Position your passport in the center of the frame"
            )
        case .scanned(_, let image):
            return .init(
                state: .staticImage(image, contentMode: .scaleAspectFill),
                instructionalText: "✓ Scanned"
            )
        }
    }

    var flowViewModel: IdentityFlowView.ViewModel {
        // TODO(mludowise|IDPROD-2756): Update and localize text when designs are final
        return .init(
            contentView: scanningView,
            buttonText: "Continue",
            isButtonDisabled: isButtonDisabled,
            didTapButton: { [weak self] in
                self?.didTapButton()
            }
        )
    }

    var isButtonDisabled: Bool {
        switch state {
        case .interstitial:
            return false
        case .scanning:
            return true
        case .scanned:
            return false
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

    let scanner = DocumentScanner()

    let cameraFeed: MockIdentityDocumentCameraFeed
    let documentType: DocumentType

    // MARK: Captured Images

    // The captured front document images to be saved to the API when continuing
    // from this screen
    private(set) var frontDocument: UIImage?
    private(set) var backDocument: UIImage?

    // MARK: Init

    init(
        sheetController: VerificationSheetControllerProtocol,
        cameraFeed: MockIdentityDocumentCameraFeed,
        documentType: DocumentType
    ) {
        self.cameraFeed = cameraFeed
        self.documentType = documentType
        self.state = .interstitial(documentType.initialScanClassification)
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

extension DocumentCaptureViewController {
    func updateUI() {
        // TODO(mludowise|IDPROD-2756): Update and localize text when designs are final
        configure(
            title: titleText,
            backButtonTitle: "Scan",
            viewModel: flowViewModel
        )
        scanningView.configure(with: scanningViewModel)
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

    func handleScannedImage(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let uiImage = UIImage(ciImage: ciImage)

        switch state {
        case .scanning(let classification):
            if classification.isFront {
                frontDocument = uiImage
            } else {
                backDocument = uiImage
            }
            state = .scanned(classification, uiImage)
        default:
            assertionFailure("state is '\(state)' but expected 'scanning'")
            return
        }
    }

    func didTapButton() {
        switch state {
        case .interstitial(let classification):
            // TODO(mludowise|IDPROD-2775): Check camera permissions
            state = .scanning(classification)
        case .scanning:
            assertionFailure("Button should be disabled in state 'scanning'.")
        case .scanned(let classification, _):
            if let nextClassification = classification.nextClassification {
                state = .interstitial(nextClassification)
            } else {
                saveDataAndTransition()
            }
        }
    }

    func saveDataAndTransition() {
        // TODO: save image to uploads.stripe.com and use returned FileID
        // Blocked by https://github.com/stripe-ios/stripe-ios/pull/479
        sheetController?.dataStore.frontDocumentImage = frontDocument.map { .init(image: $0, fileId: "") }
        sheetController?.dataStore.backDocumentImage = backDocument.map { .init(image: $0, fileId: "") }
        sheetController?.saveData(completion: { [weak sheetController] apiContent in
            guard let sheetController = sheetController else { return }
            sheetController.flowController.transitionToNextScreen(apiContent: apiContent, sheetController: sheetController)
        })
    }
}

// MARK: - DocumentType

extension DocumentCaptureViewController.DocumentType {
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
