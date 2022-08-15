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

    let metadata: [Metadata]

    private lazy var metadataByRegion: [String: Metadata] = {
        return .init(uniqueKeysWithValues: metadata.map { ($0.region, $0) })
    }()

    private init() {
        self.metadata = Self.loadMetadata()
    }

    func metadata(for region: String) -> Metadata? {
        return metadataByRegion[region]
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
            return getFallbackMetadata()
        }

        do {
            let data = try Data.fromLZFSEFile(at: url)

            let jsonDecoder = JSONDecoder()
            jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
            return try jsonDecoder.decode([Metadata].self, from: data)
        } catch {
            assertionFailure(error.localizedDescription)
            return getFallbackMetadata()
        }
    }

    static func getFallbackMetadata() -> [Metadata] {
        let codes: [String: UInt16] = [:]

        return codes.map { (region: String, prefix: UInt16) in
            Metadata(region: region, prefix: "+\(`prefix`)")
        }
    }

}
