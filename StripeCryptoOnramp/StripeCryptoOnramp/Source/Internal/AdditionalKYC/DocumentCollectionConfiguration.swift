//
//  DocumentCollectionConfiguration.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

/// Presentation and validation inputs for document collection.
struct DocumentCollectionConfiguration {

    /// A selectable document category.
    struct Subtype: Identifiable, Equatable {

        // MARK: - Identifiable

        let id: String

        // MARK: - Subtype

        /// The name displayed for this document category.
        let label: String

        /// Examples or details displayed below the category's label.
        let description: String?
    }

    /// The selectable document categories, in display order.
    let acceptedSubtypes: [Subtype]

    /// The file extensions allowed for selected documents.
    let acceptedFormats: [String]

    /// Document instruction bullets, in display order.
    let instructions: [String]

    /// The maximum allowed size of each individual file, in bytes.
    let maximumFileSize: Int

    /// Guidance describing the accepted formats and file size limit.
    let uploadHint: String
}

#if DEBUG
extension DocumentCollectionConfiguration {

    /// An example proof-of-address configuration with sample text for previews.
    static var preview: Self {
        .init(acceptedSubtypes: [
            .init(id: "id_document", label: "ID document", description: "ID cards, passport, driver’s license"),
            .init(id: "government_document", label: "Government document", description: nil),
            .init(id: "utility_bill", label: "Utility bill", description: "Electricity, gas, water, or internet bills"),
            .init(id: "bank_document", label: "Bank document", description: "Bank statements, credit card statements"),
            .init(id: "lease_agreement", label: "Lease agreement", description: "A current rental or lease agreement"),
        ], acceptedFormats: ["pdf", "jpeg", "png"], instructions: [
            "Documents must have the customer’s full name and address on it",
            "ID documents must be valid and in-date",
            "Other documents must have been issued in the last 12 months",
            "For physical documents, all 4 corners must be visible",
            "For digital documents, we can only accept PDF files - we don’t accept screenshots",
        ], maximumFileSize: 50_000_000, uploadHint: "PDF, JPEG, or PNG up to 50 MB")
    }

    /// An example source-of-funds configuration with sample text for previews.
    static var sourceOfFundsPreview: Self {
        .init(acceptedSubtypes: [.init(id: "payslip", label: "Payslip", description: "Recent payslips from your employer")], acceptedFormats: ["pdf", "jpeg", "png", "docx", "xlsx", "csv", "txt"], instructions: [
            "Documents must include your name and a balance or financial value.",
            "Bank statements must be original PDFs issued through online banking; screenshots aren't accepted.",
        ], maximumFileSize: 5_000_000, uploadHint: "PDF, JPEG/JPG, PNG, DOCX, XLSX, CSV, or TXT, up to 5 MB per file.")
    }
}
#endif
