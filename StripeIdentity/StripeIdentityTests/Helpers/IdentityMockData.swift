//
//  IdentityMockData.swift
//  StripeIdentityTests
//
//  Created by Mel Ludowise on 10/27/21.
//

import Foundation
import UIKit
import StripeCoreTestUtils
@testable import StripeIdentity

// Dummy class to determine this bundle
private class ClassForBundle { }

enum VerificationPageMock: String, MockData {
    typealias ResponseType = VerificationPage
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case response200 = "VerificationPage_200"
    case requireLiveCapture = "VerificationPage_require_live_capture"
}

enum VerificationPageDataMock: String, MockData {
    typealias ResponseType = VerificationPageData
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case response200 = "VerificationPageData_200"
    case noErrors = "VerificationPageData_no_errors"
    case submitted = "VerificationPageData_submitted"
}

enum CapturedImageMock: String {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case frontDriversLicense = "front_drivers_license"
    case backDriversLicense = "back_drivers_license"

    var url: URL {
        return bundle.url(forResource: rawValue, withExtension: "jpg")!
    }

    var image: UIImage {
        return UIImage(named: "\(rawValue).jpg", in: bundle, compatibleWith: nil)!
    }
}

enum VerificationPageDataUpdateMock {
    static let `default` = VerificationPageDataUpdate(
        clearData: nil,
        collectedData: .init(
            biometricConsent: false,
            idDocumentBack: .init(
                backScore: .init(1),
                brightnessValue: nil,
                cameraLensModel: nil,
                exposureDuration: nil,
                exposureIso: nil,
                focalLength: nil,
                frontCardScore: .init(0),
                highResImage: "back_user_upload_id",
                invalidScore: .init(0),
                iosBarcodeDecoded: nil,
                iosBarcodeSymbology: nil,
                iosTimeToFindBarcode: nil,
                isVirtualCamera: nil,
                lowResImage: "back_full_frame_id",
                passportScore: .init(0),
                uploadMethod: .autoCapture,
                _additionalParametersStorage: nil
            ),
            idDocumentFront: .init(
                backScore: .init(0),
                brightnessValue: nil,
                cameraLensModel: nil,
                exposureDuration: nil,
                exposureIso: nil,
                focalLength: nil,
                frontCardScore: .init(1),
                highResImage: "front_user_upload_id",
                invalidScore: .init(0),
                iosBarcodeDecoded: nil,
                iosBarcodeSymbology: nil,
                iosTimeToFindBarcode: nil,
                isVirtualCamera: nil,
                lowResImage: "front_full_frame_id",
                passportScore: .init(0),
                uploadMethod: .autoCapture,
                _additionalParametersStorage: nil
            ),
            idDocumentType: .drivingLicense
        ),
        _additionalParametersStorage: nil
    )
}
