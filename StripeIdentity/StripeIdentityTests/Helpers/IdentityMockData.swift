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

    func makeWithModifications(
        requireLiveCapture: Bool
    ) throws -> VerificationPage {
        let originalResponse = try self.make()
        return VerificationPage(
            biometricConsent: originalResponse.biometricConsent,
            documentCapture: .init(
                autocaptureTimeout: originalResponse.documentCapture.autocaptureTimeout,
                filePurpose: originalResponse.documentCapture.filePurpose,
                highResImageCompressionQuality: originalResponse.documentCapture.highResImageCompressionQuality,
                highResImageCropPadding: originalResponse.documentCapture.highResImageCropPadding,
                highResImageMaxDimension: originalResponse.documentCapture.highResImageMaxDimension,
                lowResImageCompressionQuality: originalResponse.documentCapture.lowResImageCompressionQuality,
                lowResImageMaxDimension: originalResponse.documentCapture.lowResImageMaxDimension,
                models: originalResponse.documentCapture.models,
                requireLiveCapture: requireLiveCapture,
                _allResponseFieldsStorage: nil
            ),
            documentSelect: originalResponse.documentSelect,
            fallbackUrl: originalResponse.fallbackUrl,
            id: originalResponse.id,
            livemode: originalResponse.livemode,
            requirements: originalResponse.requirements,
            status: originalResponse.status,
            submitted: originalResponse.submitted,
            success: originalResponse.success,
            unsupportedClient: originalResponse.unsupportedClient,
            _allResponseFieldsStorage: nil
        )
    }
}

enum VerificationPageDataMock: String, MockData {
    typealias ResponseType = VerificationPageData
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case response200 = "VerificationPageData_200"

    func makeWithModifications(
        requirements: [VerificationPageFieldType]? = nil,
        errors: [VerificationPageDataRequirementError]? = nil,
        submitted: Bool? = nil
    ) throws -> VerificationPageData {
        let originalResponse = try self.make()
        return VerificationPageData(
            id: originalResponse.id,
            requirements: .init(
                errors: errors ?? originalResponse.requirements.errors,
                missing: requirements ?? originalResponse.requirements.missing,
                _allResponseFieldsStorage: nil
            ),
            status: originalResponse.status,
            submitted: submitted ?? originalResponse.submitted,
            _allResponseFieldsStorage: nil
        )
    }
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
            consent: .init(
                biometric: false,
                _additionalParametersStorage: nil
            ),
            idDocument: .init(
                back: .init(
                    backScore: .init(1),
                    frontCardScore: .init(0),
                    highResImage: "back_user_upload_id",
                    invalidScore: .init(0),
                    lowResImage: "back_full_frame_id",
                    passportScore: .init(0),
                    uploadMethod: .autoCapture,
                    _additionalParametersStorage: nil
                ),
                front: .init(
                    backScore: .init(0),
                    frontCardScore: .init(1),
                    highResImage: "front_user_upload_id",
                    invalidScore: .init(0),
                    lowResImage: "front_full_frame_id",
                    passportScore: .init(0),
                    uploadMethod: .autoCapture,
                    _additionalParametersStorage: nil
                ),
                type: .drivingLicense,
                _additionalParametersStorage: nil
            ),
            _additionalParametersStorage: nil
        ),
        _additionalParametersStorage: nil
    )
}
