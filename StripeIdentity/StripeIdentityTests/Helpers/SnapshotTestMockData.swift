//
//  SnapshotTestMockData.swift
//  StripeIdentityTests
//
//  Created by Jaime Park on 1/26/22.
//

import UIKit

private class SnapshotTestClassForBundle {}

struct SnapshotTestMockData {
    enum Image: String {
        case ciImage = "ciimage_stripeidentity_test"
        case headerIcon = "header_icon"
    }

    static let mockDeviceWidth: CGFloat = 375

    static func ciImage(image: Image) -> CIImage {
        let uiImage = uiImage(image: image)
        return CIImage(cgImage: uiImage.cgImage!)
    }

    static func uiImage(image: Image) -> UIImage {
        let bundle = Bundle(for: SnapshotTestClassForBundle.self)
        let uiImage = UIImage(named: image.rawValue, in: bundle, compatibleWith: nil)
        return uiImage!
    }
}
