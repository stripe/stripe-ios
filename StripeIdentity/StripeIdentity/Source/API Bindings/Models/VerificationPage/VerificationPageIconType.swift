//
//  VerificationPageIconType.swift
//  StripeIdentity
//
//  Created by Chen Cen on 9/14/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

extension StripeAPI {
    enum VerificationPageIconType: String, Codable, Equatable, CaseIterable {
        case cloud = "cloud"
        case document = "document"
        case createIdentityVerification = "create_identity_verification"
        case lock = "lock"
        case moved = "moved"
        case wallet = "wallet"
        case camera = "camera"
        case disputeProtection = "dispute_protection"
        case phone = "phone"
    }
}

extension StripeAPI.VerificationPageIconType {
    func makeImage() -> UIImage {
        switch self {
        case .cloud:
            return Image.iconCloud.makeImage().withTintColor(IdentityUI.darkIconColor)
        case .document:
            return Image.iconDocument.makeImage().withTintColor(IdentityUI.darkIconColor)
        case .createIdentityVerification:
            return Image.iconCreateIdentityVerification.makeImage().withTintColor(IdentityUI.darkIconColor)
        case .lock:
            return Image.iconLock.makeImage().withTintColor(IdentityUI.darkIconColor)
        case .moved:
            return Image.iconMoved.makeImage().withTintColor(IdentityUI.darkIconColor)
        case .wallet:
            return Image.iconWallet.makeImage().withTintColor(IdentityUI.darkIconColor)
        case .camera:
            return Image.iconCameraClassic.makeImage().withTintColor(IdentityUI.darkIconColor)
        case .disputeProtection:
            return Image.iconDisputeProtection.makeImage().withTintColor(IdentityUI.darkIconColor)
        case .phone:
            return Image.iconPhone.makeImage().withTintColor(IdentityUI.darkIconColor)
        }
    }

    func makeImageView() -> UIImageView {
        return UIImageView(image: self.makeImage())
    }
}
