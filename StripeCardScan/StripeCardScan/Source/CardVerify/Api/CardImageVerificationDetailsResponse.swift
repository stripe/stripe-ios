//
//  CardImageVerificationDetailsResponse.swift
//  StripeCardScan
//
//  Created by Jaime Park on 9/16/21.
//

import Foundation
@_spi(STP) import StripeCore

struct CardImageVerificationExpectedCard: Decodable {
    let last4: String
    let issuer: String
}

struct CardImageVerificationImageSettings: Decodable {
    var compressionRatio: Double? = 0.8
    var imageSize: [Double]? = [1080, 1920]
}

enum CardImageVerificationFormat: String, SafeEnumCodable {
    case heic = "heic"
    case jpeg = "jpeg"
    case webp = "webp"
    case unparsable
}

struct CardImageVerificationAcceptedImageConfigs: Decodable {
    private let defaultSettings: CardImageVerificationImageSettings?
    private let formatSettings: [CardImageVerificationFormat: CardImageVerificationImageSettings?]?
    let preferredFormats: [CardImageVerificationFormat]?

    init(defaultSettings: CardImageVerificationImageSettings? = CardImageVerificationImageSettings(),
         formatSettings: [CardImageVerificationFormat: CardImageVerificationImageSettings?]? = nil,
         preferredFormats: [CardImageVerificationFormat]? = [.heic, .jpeg]) {
        self.defaultSettings = defaultSettings
        self.formatSettings = formatSettings
        self.preferredFormats = preferredFormats
    }
}

struct CardImageVerificationDetailsResponse: Decodable {
    let expectedCard: CardImageVerificationExpectedCard?
    let acceptedImageConfigs: CardImageVerificationAcceptedImageConfigs?
}

extension CardImageVerificationAcceptedImageConfigs {
    func imageSettings(format: CardImageVerificationFormat) -> CardImageVerificationImageSettings {
        var result = defaultSettings ?? CardImageVerificationImageSettings()

        if let formatSpecificSettings = formatSettings?[format] {
            if let compressionRatio = formatSpecificSettings?.compressionRatio {
                result.compressionRatio = compressionRatio
            }

            if let imageSize = formatSpecificSettings?.imageSize {
                result.imageSize = imageSize
            }
        }

        return result
    }
}
