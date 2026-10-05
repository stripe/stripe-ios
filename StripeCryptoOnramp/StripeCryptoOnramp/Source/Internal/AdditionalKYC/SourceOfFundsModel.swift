//
//  SourceOfFundsModel.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/30/26.
//

import Combine

/// Retains uploaded documents grouped by their backend document category.
@MainActor
final class SourceOfFundsModel: ObservableObject {

    /// A source added to the summary, containing only successfully uploaded files.
    struct Source: Identifiable {

        /// The selected document category, including its backend identifier and display label.
        let subtype: DocumentCollectionConfiguration.Subtype

        /// Uploaded files belonging to this category, in display order.
        let files: [DocumentUploadModel.UploadedFile]

        // MARK: - Identifiable

        var id: String {
            subtype.id
        }
    }

    /// The document constraints returned for this requirement.
    let configuration: DocumentCollectionConfiguration

    /// The sources added by the user, in display order.
    @Published private(set) var sources: [Source] = []

    /// Whether the number of distinct categories satisfies the backend's bounds.
    var canSubmit: Bool {
        sources.count >= configuration.minimumDocumentTypes && sources.count <= configuration.maximumDocumentTypes
    }

    /// Whether another unused document category can be added.
    var canAddSource: Bool {
        sources.count < configuration.maximumDocumentTypes && !availableSubtypes().isEmpty
    }

    /// The uploaded file identifiers grouped by document subtype for fulfillment.
    var documents: [FulfillKYCRequirementsRequest.Document] {
        sources.map { .init(documentSubtype: $0.id, fileIds: $0.files.map(\.fileID)) }
    }

    /// Creates an empty source summary.
    /// - Parameter configuration: The document categories and type-count limits to enforce.
    init(configuration: DocumentCollectionConfiguration) {
        self.configuration = configuration
    }

    /// Returns categories not used by another source.
    /// - Parameter sourceID: The source being edited, whose current category remains available.
    /// - Returns: Selectable categories in their backend display order.
    func availableSubtypes(editing sourceID: String? = nil) -> [DocumentCollectionConfiguration.Subtype] {
        configuration.acceptedSubtypes.filter { subtype in
            !sources.contains { $0.id == subtype.id && $0.id != sourceID }
        }
    }

    /// Adds or replaces a source after all of its selected files have uploaded.
    /// - Parameters:
    ///   - subtype: The category selected in the document editor.
    ///   - files: The uploaded files to retain. An empty list removes the edited source.
    ///   - sourceID: The original source identifier when editing an existing source.
    func save(subtype: DocumentCollectionConfiguration.Subtype, files: [DocumentUploadModel.UploadedFile], replacing sourceID: String? = nil) {
        guard availableSubtypes(editing: sourceID).contains(subtype) else {
            return
        }

        if let sourceID, let index = sources.firstIndex(where: { $0.id == sourceID }) {
            if files.isEmpty {
                sources.remove(at: index)
            } else {
                sources[index] = .init(subtype: subtype, files: files)
            }
        } else if canAddSource && !files.isEmpty {
            sources.append(.init(subtype: subtype, files: files))
        }
    }
}
