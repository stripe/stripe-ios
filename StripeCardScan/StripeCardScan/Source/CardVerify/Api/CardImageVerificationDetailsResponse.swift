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
    internal let defaultSettings: CardImageVerificationImageSettings?
    internal let formatSettings: [CardImageVerificationFormat: CardImageVerificationImageSettings?]?
    let preferredFormats: [CardImageVerificationFormat]?

    init(defaultSettings: CardImageVerificationImageSettings? = CardImageVerificationImageSettings(),
         formatSettings: [CardImageVerificationFormat: CardImageVerificationImageSettings?]? = nil,
         preferredFormats: [CardImageVerificationFormat]? = [.jpeg]) {
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
        var result = CardImageVerificationImageSettings()

        if let defaultSettings = defaultSettings {
            result.compressionRatio = defaultSettings.compressionRatio ?? result.compressionRatio
            result.imageSize = defaultSettings.imageSize ?? result.imageSize
        }

        if let formatSpecificSettings = formatSettings?[format], let formatSpecificSettings = formatSpecificSettings {
            result.compressionRatio = formatSpecificSettings.compressionRatio ?? result.compressionRatio
            result.imageSize = formatSpecificSettings.imageSize ?? result.imageSize
        }

        return result
    }
}
