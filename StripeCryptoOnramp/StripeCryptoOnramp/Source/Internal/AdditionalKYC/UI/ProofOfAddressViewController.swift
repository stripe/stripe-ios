//
//  ProofOfAddressViewController.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

@_spi(CryptoOnrampAlpha) import StripePaymentSheet
import SwiftUI

/// Hosts document collection in the owner's navigation flow without retrieving or fulfilling requirements.
final class ProofOfAddressViewController: DocumentCollectionViewController<ProofOfAddressView> {

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
        super.init(
            rootView: ProofOfAddressView(configuration: configuration, appearance: appearance, upload: upload, initialErrorMessage: initialErrorMessage, onSubmit: onSubmit, onClose: onClose),
            appearance: appearance,
            onLeave: {
                upload.cancel()
            }
        )
    }

    // MARK: - NSCoding

    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
