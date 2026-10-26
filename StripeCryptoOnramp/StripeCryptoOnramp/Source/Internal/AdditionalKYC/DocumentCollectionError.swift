//
//  DocumentCollectionError.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/21/26.
//

/// Internal failures while configuring document collection, importing a file, or preparing an upload.
/// These errors are not surfaced directly to the SDK- or end-user.
enum DocumentCollectionError: Error, Equatable {

    /// The requirement cannot be represented by the current document collection flow.
    case unsupportedRequirement

    /// The selected file's format is not accepted.
    case unsupportedFormat

    /// The selected file exceeds the configured per-file size limit.
    case fileTooLarge

    /// The selection did not provide a readable, nonempty regular file.
    case unreadableFile

    /// A Link session key is unavailable for authorizing the upload.
    case missingLinkSessionKey

    /// The supplied view controller cannot present document collection.
    case invalidPresenter
}
