//
//  PhoneMetadataProvider.swift
//  StripeUICore
//
//  Created by Ramon Torres on 8/10/22.
//

import Foundation
@_spi(STP) import StripeCore

final class PhoneMetadataProvider {

    static let shared: PhoneMetadataProvider = .init()

    let allMetadata: [Metadata]

    private let metadata: [String: Metadata]

    private let metadataByPrefix: [String: [Metadata]]

    private init() {
        let metadata = Self.loadMetadata()
        self.allMetadata = metadata
        self.metadata = .init(uniqueKeysWithValues: metadata.map { ($0.region, $0) })
        self.metadataByPrefix = .init(grouping: metadata, by: { $0.prefix })
    }

    func metadata(for countryCode: String) -> Metadata? {
        return metadata[countryCode]
    }

    func metadata(prefix: String) -> [Metadata] {
        return metadataByPrefix[prefix] ?? []
    }

}

// MARK: - Loading

private extension PhoneMetadataProvider {

    static func loadMetadata() -> [Metadata] {
        let resourcesBundle = StripeUICoreBundleLocator.resourcesBundle

        guard
            let url = resourcesBundle.url(
                forResource: "phone_metadata",
                withExtension: "json.lzfse"
            )
        else {
            assertionFailure("phone_metadata.json.lzfse is missing")
            return []
        }

        do {
            let data = try Data.fromLZFSEFile(at: url)

            let jsonDecoder = JSONDecoder()
            return try jsonDecoder.decode([Metadata].self, from: data)
        } catch {
            assertionFailure(error.localizedDescription)
            return []
        }
    }

}
