//
//  VerificationPageStaticContentDocumentCaptureMBSettings.swift
//  StripeIdentity
//
//  Created by Chen Cen on 1/24/24.
//

import Foundation
@_spi(STP) import StripeCore

extension StripeAPI {
    /// Policy to configure capture strategy used to select the best frame.
    enum MBCaptureStrategyType: String, Codable, Equatable, CaseIterable {
        case singleFrame = "single_frame"
        case optimizeForQuality = "optimize_for_quality"
        case optimizeForSpeed = "optimize_for_speed"
        case defaultValue = "default"
    }

    /// Policy used to detect tilted documents.
    enum MBTiltPolicyType: String, Codable, Equatable, CaseIterable {
        case disabled = "disabled"
        case normal = "normal"
        case relaxed = "relaxed"
        case strict = "strict"
    }

    /// Policy used to discard frames with blurred documents.
    enum MBBlurPolicyType: String, Codable, Equatable, CaseIterable {
        case disabled = "disabled"
        case normal = "normal"
        case relaxed = "relaxed"
        case strict = "strict"
    }

    /// Policy used to discard frames with glare detected on the document.
    enum MBGlarePolicyType: String, Codable, Equatable, CaseIterable {
        case disabled = "disabled"
        case normal = "normal"
        case relaxed = "relaxed"
        case strict = "strict"
    }

    struct VerificationPageStaticContentDocumentCaptureMBSettings: Decodable, Equatable {
        /// License key for the specific package
        let licenseKey: String

        /// Defines whether to return an image of a cropped and perspective-corrected document.
        let returnTransformedDocumentImage: Bool

        /// Defines whether to return an image of the transformed document with applied margin used during document framing.
        let keepMarginOnTransformedDocumentImage: Bool

        /// Enables document capture with a margin defined as the percentage of the dimensions of the framed document.
        /// Both margin and document are required to be fully visible on camera frame in order to finish capture.
        /// Allowed values are from 0 to 1.
        let documentFramingMargin: CGFloat

        /// Defines percentage of the document area that is allowed to be occluded by hand.
        /// Allowed values are from 0 to 1.
        let handOcclusionThreshold: CGFloat

        let captureStrategy: MBCaptureStrategyType

        let tooBrightThreshold: CGFloat

        let tooDarkThreshold: CGFloat

        /// Required minimum DPI of the captured document on transformed image.
        /// Affects how close the document needs to be to the camera in order to get captured and meet dpi requirements.
        /// Allowed values are [ 150, 400 ].
        let minimumDocumentDpi: Int

        /// Whether to automatically adjust minimum document dpi.
        /// If it is enabled, minimum dpi is adjusted to optimal value for provided input resolution
        /// to enable capture of all document groups.
        let adjustMinimumDocumentDpi: Bool

        let tiltPolicy: MBTiltPolicyType

        let blurPolicy: MBBlurPolicyType

        let glarePolicy: MBGlarePolicyType

    }
}
