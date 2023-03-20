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
        case cgImage = "cgimage_stripeidentity_test"
        case headerIcon = "header_icon"
    }

    static let mockDeviceWidth: CGFloat = 375

    static func cgImage(image: Image) -> CGImage {
        let uiImage = uiImage(image: image)
        return uiImage.cgImage!
    }

    static func uiImage(image: Image) -> UIImage {
        let bundle = Bundle(for: SnapshotTestClassForBundle.self)
        let uiImage = UIImage(named: image.rawValue, in: bundle, compatibleWith: nil)
        return uiImage!
    }
}
