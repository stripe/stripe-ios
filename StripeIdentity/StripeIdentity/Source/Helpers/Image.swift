//
//  Image.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 11/8/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import CoreGraphics
import Foundation
@_spi(STP) import StripeUICore

/// The canonical set of all image files in the `StripeIdentity` module.
/// This helps us avoid duplicates and automatically test that all images load properly
@_spi(STP) public enum Image: String, CaseIterable, ImageMaker {
    @_spi(STP) public typealias BundleLocator = StripeIdentityBundleLocator

    case iconAdd = "icon_add"
    case iconEllipsis = "icon_ellipsis"
    case iconCheckmark = "icon_checkmark"
    case iconCheckmark92 = "icon_checkmark_92"
    case iconClock = "icon_clock"
    case iconInfo = "icon_info"
    case iconWarning = "icon_warning"
    case iconWarning2 = "icon_warning2"
    case iconWarning92 = "icon_warning_92"
    case iconCamera = "icon_camera"
    case iconSelfieWarmup = "icon_selfie_warmup"
    case iconIdFront = "icon_id_front"
    case iconCloud = "icon_cloud"
    case iconDocument = "icon_document"
    case iconLock = "icon_lock"
    case iconMoved = "icon_moved"
    case iconCreateIdentityVerification = "icon_create_identity_verification"
    case iconWallet = "icon_wallet"
    case iconCameraClassic = "icon_camera_classic"
    case iconDisputeProtection = "icon_dispute_protection"
    case iconPhone = "icon_phone"
    case testModeDocumentFront = "test_mode_document_front"
    case testModeDocumentBack = "test_mode_document_back"
    case testModeSelfie = "test_mode_selfie"
}

enum TestModeImage {
    case documentFront
    case documentBack
    case selfie

    private var resource: Image {
        switch self {
        case .documentFront:
            return .testModeDocumentFront
        case .documentBack:
            return .testModeDocumentBack
        case .selfie:
            return .testModeSelfie
        }
    }

    func makeCGImage() throws -> CGImage {
        guard let cgImage = resource.makeImage().cgImage else {
            throw TestModeImageError.missingResource(resource.rawValue)
        }
        return cgImage
    }
}

private enum TestModeImageError: Error {
    case missingResource(String)
}
