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

// MARK: Responses
enum CardImageVerificationDetailsResponseMock: String, MockData {
    var bundle: Bundle { return Bundle(for: ClassForBundle.self) }

    typealias ResponseType = CardImageVerificationDetailsResponse

    case cardImageVerification_cardSet_200 = "CardImageVerification_CardSet_200"
    case cardImageVerification_cardAdd_200 = "CardImageVerification_CardAdd_200"
}

struct CIVIntentMockData {
    static let id = "civ_1234"
    static let clientSecret = "civ_client_secret_1234"

    static var intent: CardImageVerificationIntent = {
        let intent = CardImageVerificationIntent(
            id: id,
            clientSecret: clientSecret
        )
        return intent
    }()
}
