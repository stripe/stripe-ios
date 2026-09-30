//
//  ProofOfAddressViewController.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// Hosts document collection in the owner's navigation flow without retrieving or fulfilling requirements.
final class ProofOfAddressViewController: UIHostingController<ProofOfAddressView> {
    private let upload: DocumentUploadModel
    private var isLeaving = false

    /// Creates document collection with a new upload model using the supplied uploader.
    /// - Parameters:
    ///   - configuration: The document categories, file constraints, and instructions to display.
    ///   - appearance: The styling for the screen and its controls.
    ///   - uploader: The service used to upload selected documents.
    ///   - initialErrorMessage: Safe SDK copy for an issue with a previous document, when present.
    ///   - onSubmit: The action that submits the selected category and uploaded file.
    ///   - onClose: The action that dismisses the collection flow.
    convenience init(configuration: DocumentCollectionConfiguration, appearance: LinkAppearance, uploader: DocumentUploading, initialErrorMessage: String? = nil, onSubmit: @escaping (ProofOfAddressView.Submission) async throws -> Void, onClose: @escaping () -> Void) {
        self.init(configuration: configuration, appearance: appearance, upload: DocumentUploadModel(uploader: uploader), initialErrorMessage: initialErrorMessage, onSubmit: onSubmit, onClose: onClose)
    }

    /// Creates document collection using an existing upload model.
    /// - Parameters:
    ///   - configuration: The document categories, file constraints, and instructions to display.
    ///   - appearance: The styling for the screen and its controls.
    ///   - upload: The model that manages the selected document and its upload.
    ///   - initialErrorMessage: Safe SDK copy for an issue with a previous document, when present.
    ///   - onSubmit: The action that submits the selected category and uploaded file.
    ///   - onClose: The action that dismisses the collection flow.
    init(configuration: DocumentCollectionConfiguration, appearance: LinkAppearance, upload: DocumentUploadModel, initialErrorMessage: String? = nil, onSubmit: @escaping (ProofOfAddressView.Submission) async throws -> Void, onClose: @escaping () -> Void) {
        self.upload = upload
        super.init(rootView: ProofOfAddressView(configuration: configuration, appearance: appearance, upload: upload, initialErrorMessage: initialErrorMessage, onSubmit: onSubmit, onClose: onClose))
        appearance.applyInterfaceStyle(to: self)
    }

    // MARK: - NSCoding

    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UIViewController

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isLeaving = false

        // Keep the collection sheet's grabber visible after navigation pushes this screen.
        navigationController?.sheetPresentationController?.prefersGrabberVisible = true

        // Without Liquid Glass, omit the introduction screen's title from the back button.
        if !LiquidGlassDetector.isEnabledInMerchantApp,
           let controllers = navigationController?.viewControllers,
           let index = controllers.firstIndex(of: self), index > 0 {
            controllers[index - 1].navigationItem.backButtonDisplayMode = .minimal
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // A picker can cover this screen without ending collection; only a pop or dismissal ends it.
        isLeaving = isMovingFromParent || isBeingDismissed || navigationController?.isBeingDismissed == true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isLeaving {
            // Prevent in-flight uploads and late picker callbacks from changing the closed flow.
            upload.cancel()
        }
    }
}
