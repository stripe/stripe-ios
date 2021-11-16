//
//  CardScanMockData.swift
//  StripeCardScanTests
//
//  Created by Jaime Park on 11/16/21.
//

import Foundation
@testable import StripeCardScan
import StripeCoreTestUtils

// note: This class is to find the test bundle
private class ClassForBundle {}

enum CardImageVerificationDetailsResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = CardImageVerificationDetailsResponse

    case cardImageVerification_cardSet_200 = "CardImageVerification_CardSet_200"
    case cardImageVerification_cardAdd_200 = "CardImageVerification_CardAdd_200"
}
