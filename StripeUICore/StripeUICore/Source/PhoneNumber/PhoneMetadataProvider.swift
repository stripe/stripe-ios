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

    private let metadata: [String: Metadata]

    private init() {
        self.metadata = Self.loadMetadata()
    }

    func metadata(for countryCode: String) -> Metadata? {
        return metadata[countryCode]
    }

}

// MARK: - Loading

private extension PhoneMetadataProvider {

    static func loadMetadata() -> [String: Metadata] {
        let resourcesBundle = StripeUICoreBundleLocator.resourcesBundle

        guard
            let url = resourcesBundle.url(
                forResource: "phone_metadata",
                withExtension: "json.lzfse"
            )
        else {
            assertionFailure("phone_metadata.json.lzfse is missing")
            return [:]
        }

        do {
            let data = try Data.fromLZFSEFile(at: url)

            let jsonDecoder = JSONDecoder()
            let metadata = try jsonDecoder.decode([Metadata].self, from: data)
            return .init(uniqueKeysWithValues: metadata.map({ item in
                (item.region, item)
            }))
        } catch {
            assertionFailure(error.localizedDescription)
            return [:]
        }
    }

}

extension PhoneMetadataProvider {
    final class Metadata: Decodable {
        let region: String
        let prefix: String
        let validLengths: Set<Int>
    }

    final class Format: Decodable {
        let pattern: String
        let leadingDigits: String
    }
}
