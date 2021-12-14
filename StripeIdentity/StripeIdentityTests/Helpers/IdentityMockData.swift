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

}

enum VerificationPageDataMock: String, MockData {
    typealias ResponseType = VerificationPageData
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    case response200 = "VerificationPageData_200"

    func makeWithModifications(
        requirements: [VerificationPageRequirements.Missing]? = nil,
        errors: [VerificationPageDataRequirementError]? = nil,
        submitted: Bool? = nil
    ) throws -> VerificationPageData {
        let originalResponse = try self.make()
        return VerificationPageData(
            id: originalResponse.id,
            status: originalResponse.status,
            submitted: submitted ?? originalResponse.submitted,
            requirements: .init(
                missing: requirements ?? originalResponse.requirements.missing,
                errors: errors ?? originalResponse.requirements.errors,
                _allResponseFieldsStorage: nil
            ),
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
        collectedData: .init(
            address: .init(
                city: "city",
                country: "country",
                line1: "line1",
                line2: "line2",
                state: "state",
                postalCode: "postalCode",
                _additionalParametersStorage: nil
            ),
            consent: .init(
                train: true,
                biometric: false,
                _additionalParametersStorage: nil
            ),
            dob: .init(
                day: "day",
                month: "month",
                year: "year",
                _additionalParametersStorage: nil
            ),
            email: "email@address.com",
            face: .init(
                image: "some_image_id",
                _additionalParametersStorage: nil
            ),
            idDocument: .init(
                type: .drivingLicense,
                front: .init(
                    method: .autoCapture,
                    userUpload: "front_user_upload_id",
                    fullFrame: "front_full_frame_id",
                    passportScore: 0,
                    frontCardScore: 1,
                    backScore: 0,
                    invalidScore: 0,
                    noDocumentScore: 0,
                    _additionalParametersStorage: nil
                ),
                back: .init(
                    method: .autoCapture,
                    userUpload: "back_user_upload_id",
                    fullFrame: "back_full_frame_id",
                    passportScore: 0,
                    frontCardScore: 0,
                    backScore: 1,
                    invalidScore: 0,
                    noDocumentScore: 0,
                    _additionalParametersStorage: nil
                ),
                _additionalParametersStorage: nil
            ),
            idNumber: .init(
                country: "country",
                partialValue: "1234",
                value: nil,
                _additionalParametersStorage: nil
            ),
            name: .init(
                firstName: "first",
                lastName: "last",
                _additionalParametersStorage: nil
            ),
            phoneNumber: "1234567890",
            _additionalParametersStorage: nil
        ),
        _additionalParametersStorage: nil
    )
}
