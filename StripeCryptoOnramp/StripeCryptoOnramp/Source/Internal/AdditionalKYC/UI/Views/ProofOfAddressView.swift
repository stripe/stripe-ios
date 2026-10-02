//
//  ProofOfAddressView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// Collects one proof-of-address document using owner-supplied requirements and upload behavior.
struct ProofOfAddressView: View {

    /// The selected document category and uploaded file to submit for proof of address.
    struct Submission: Equatable {

        /// The identifier of the selected document category.
        let subtypeID: String

        /// The Files API identifier of the uploaded document.
        let fileID: String
    }

    /// The accepted documents, file constraints, and upload instructions.
    let configuration: DocumentCollectionConfiguration

    /// The appearance used for the collection screen and its controls.
    let appearance: LinkAppearance

    /// The model that owns the selected document and its upload state.
    @ObservedObject var upload: DocumentUploadModel

    /// Submits the selected category and uploaded file, throwing if submission fails.
    let onSubmit: (Submission) async throws -> Void

    /// The action invoked when the user closes the collection flow.
    let onClose: () -> Void

    @State private var selectedSubtype: DocumentCollectionConfiguration.Subtype?
    @State private var documentSelection = DocumentSelectionState()
    @State private var isSubmitting = false
    @State private var submissionTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var inheritedColorScheme

    /// Creates document collection with the first available subtype selected.
    /// - Parameters:
    ///   - configuration: The document categories, file constraints, and instructions to display.
    ///   - appearance: The styling for the screen and its controls.
    ///   - upload: The model that manages the selected document and its upload.
    ///   - initialErrorMessage: Safe SDK copy for an issue with a previous document, when present.
    ///   - onSubmit: The action that submits the selected category and uploaded file.
    ///   - onClose: The action that dismisses the collection flow.
    init(configuration: DocumentCollectionConfiguration, appearance: LinkAppearance, upload: DocumentUploadModel, initialErrorMessage: String? = nil, onSubmit: @escaping (Submission) async throws -> Void, onClose: @escaping () -> Void) {
        self.configuration = configuration
        self.appearance = appearance
        self.upload = upload
        self.onSubmit = onSubmit
        self.onClose = onClose
        _selectedSubtype = State(initialValue: configuration.acceptedSubtypes.first)
        _documentSelection = State(initialValue: .init(errorMessage: initialErrorMessage))
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(String.Localized.uploadProofOfAddress)
                        .typography(.headingExtraLarge)
                        .foregroundColor(.textPrimary)
                        .accessibilityAddTraits(.isHeader)

                    Text(String.Localized.documentRequirementsExplanation)
                        .typography(.bodyExtraLarge)
                        .foregroundColor(.textTertiary)
                }
                .multilineTextAlignment(.center)

                VStack(spacing: 16) {
                    if let selectedSubtype {
                        DocumentSubtypeButton(title: .Localized.documentType, selection: selectedSubtype.label) {
                            documentSelection.sheet = .subtype
                        }
                        .disabled(isSubmitting)
                    }

                    documentControl

                    if let errorMessage = documentSelection.errorMessage {
                        InlineErrorMessageView(message: errorMessage)
                    } else if documentSelection.rejectedFile == nil && upload.document?.status == .failed {
                        InlineErrorMessageView(message: .Localized.documentUploadFailed)
                    }
                }

                DocumentInstructionsView(instructions: configuration.instructions)
            }
            .padding(20)
        }
        .primaryActionInset(title: .Localized.submit, appearance: appearance, action: submit, isEnabled: canSubmit, isProcessing: isSubmitting)
        .background(Color.surfacePrimary.ignoresSafeArea())
        .environment(\.colorScheme, appearance.colorScheme ?? inheritedColorScheme)
        .preferredColorScheme(appearance.colorScheme)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            CloseToolbarItem(action: close)
        }
        .accessibilityAction(.escape, close)
        .onDisappear { submissionTask?.cancel() }
        .documentSelection(
            state: $documentSelection,
            configuration: configuration,
            subtypes: configuration.acceptedSubtypes,
            selectedSubtype: $selectedSubtype,
            appearance: appearance,
            onSelectSource: beginSelection,
            onSelectFile: upload.select
        )
    }

    // MARK: - ProofOfAddressView

    @ViewBuilder
    private var documentControl: some View {
        if let importingFilename = documentSelection.importingFilename {
            DocumentFileRow(filename: importingFilename.isEmpty ? "File" : importingFilename, status: .uploading(0), onRemove: {})
        } else if let rejectedFile = documentSelection.rejectedFile {
            DocumentFileRow(filename: rejectedFile.filename, status: .failed(message: rejectedFile.message), onRemove: {
                documentSelection.rejectedFile = nil
            })
        } else if let document = upload.document, document.status != .failed {
            DocumentFileRow(filename: document.name, status: rowStatus(for: document.status), onRemove: {
                upload.remove()
                documentSelection.errorMessage = nil
            })
            .disabled(isSubmitting)
        } else {
            UploadDocumentButton(detail: configuration.uploadHint) {
                if configuration.allowsPhotoSelection {
                    documentSelection.showsSourcePicker = true
                } else {
                    beginSelection(.files)
                }
            }
            .disabled(selectedSubtype == nil || configuration.acceptedFormats.isEmpty || isSubmitting)
        }
    }

    private var canSubmit: Bool {
        selectedSubtype != nil && upload.uploadedFileID != nil && documentSelection.importingFilename == nil && documentSelection.rejectedFile == nil && !isSubmitting
    }

    private func rowStatus(for status: DocumentUploadModel.Status) -> DocumentFileRow.Status {
        switch status {
        case .uploading(progress: let progress):
            return .uploading(progress)
        case .uploaded:
            return .uploaded
        case .failed:
            return .failed(message: .Localized.documentUploadFailed)
        }
    }

    private func beginSelection(_ source: DocumentPicker.Source) {
        documentSelection.beginSelection(source)
        if upload.document?.status == .failed {
            upload.remove()
        }
    }

    private func submit() {
        guard canSubmit, let selectedSubtype, let fileID = upload.uploadedFileID else {
            return
        }
        isSubmitting = true
        documentSelection.errorMessage = nil
        submissionTask = Task { @MainActor in
            defer {
                isSubmitting = false
                submissionTask = nil
            }
            do {
                try await onSubmit(.init(subtypeID: selectedSubtype.id, fileID: fileID))
            } catch {
                if !Task.isCancelled {
                    documentSelection.errorMessage = .Localized.tryAgainLater
                }
            }
        }
    }

    private func close() {
        guard !isSubmitting else { return }
        documentSelection.cancelImport()
        submissionTask?.cancel()
        upload.cancel()
        onClose()
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Proof of address - empty") {
    ProofOfAddressPreview(document: nil)
}

@available(iOS 17.0, *)
#Preview("Proof of address - uploading") {
    ProofOfAddressPreview(document: .init(name: "electricity_bill-aug-27.pdf", status: .uploading(progress: 0.6)))
}

@available(iOS 17.0, *)
#Preview("Proof of address - uploaded") {
    ProofOfAddressPreview(document: .init(name: "electricity_bill-aug-27.pdf", status: .uploaded(fileID: "file_preview")))
}

@available(iOS 17.0, *)
#Preview("Proof of address - upload error") {
    ProofOfAddressPreview(document: .init(name: "electricity_bill-aug-27.pdf", status: .failed))
}

private struct ProofOfAddressPreview: View {
    let document: DocumentUploadModel.Document?

    // MARK: - View

    var body: some View {
        Color.clear
            .sheet(isPresented: .constant(true)) {
                NavigationPreview(document: document)
                    .id(document?.status)
            }
            .transaction {
                $0.disablesAnimations = true
            }
    }

    // MARK: - ProofOfAddressPreview

    private struct NavigationPreview: UIViewControllerRepresentable {
        let document: DocumentUploadModel.Document?

        // MARK: - UIViewControllerRepresentable

        func makeUIViewController(context: Context) -> UINavigationController {
            let navigation = UINavigationController()
            let upload = DocumentUploadModel.preview(document: document)
            let collection = ProofOfAddressViewController(configuration: .preview, appearance: .previewLinkAppearance, upload: upload, onSubmit: { _ in }, onClose: {})
            let introduction = UIHostingController(rootView: MessageView(configuration: .proofOfAddress, appearance: .previewLinkAppearance, onPrimaryAction: { [weak navigation] in
                let next = ProofOfAddressViewController(configuration: .preview, appearance: .previewLinkAppearance, upload: .preview(), onSubmit: { _ in }, onClose: {})
                navigation?.pushViewController(next, animated: true)
            }, onClose: {}))
            if !LiquidGlassDetector.isEnabledInMerchantApp {
                introduction.navigationItem.backButtonDisplayMode = .minimal
            }
            navigation.setViewControllers([introduction, collection], animated: false)
            return navigation
        }

        func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        }
    }
}
#endif
