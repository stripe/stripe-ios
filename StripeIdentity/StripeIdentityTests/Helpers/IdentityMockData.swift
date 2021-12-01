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
