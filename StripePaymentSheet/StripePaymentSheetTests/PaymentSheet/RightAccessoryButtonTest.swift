//
//  RightAccessoryButtonTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 5/31/24.
//

import Foundation
import XCTest
@_spi(STP) @testable import StripePaymentSheet

final class RightAccessoryButtonTest: XCTestCase {
    
    // MARK: More than 1 saved payment method
    
    func testViewMore_Returned_When_SavedPaymentsGreaterThanOneRegardlessOfOtherValues() {
        // Regardless of any flags, if we have more than 1 payment method we should show the view more button
        
        // Iterating over all combinations of isFirstCardCoBranded, isCBCEligible, allowsRemovalOfLastSavedPaymentMethod, and paymentMethodRemove
        let booleans = [false, true]
        for isFirstCardCoBranded in booleans {
            for isCBCEligible in booleans {
                for allowsRemovalOfLastSavedPaymentMethod in booleans {
                    for paymentMethodRemove in booleans {
                        let result = RowButton.RightAccessoryButton.getAccessoryButtonType(savedPaymentMethodsCount: 2,
                                                                                           isFirstCardCoBranded: isFirstCardCoBranded,
                                                                                           isCBCEligible: isCBCEligible,
                                                                                           allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                                                           paymentMethodRemove: paymentMethodRemove)
                        XCTAssertEqual(result, .viewMore)
                    }
                }
            }
        }
    }

    // MARK: 1 card
    
    func testSingleCard_Returns_CorrectValue() {
        // Iterating over all combinations of isFirstCardCoBranded, isCBCEligible, allowsRemovalOfLastSavedPaymentMethod, and paymentMethodRemove
        let booleans = [false, true]
        for isFirstCardCoBranded in booleans {
            for isCBCEligible in booleans {
                for allowsRemovalOfLastSavedPaymentMethod in booleans {
                    for paymentMethodRemove in booleans {
                        
                        let canEdit = (isFirstCardCoBranded && isCBCEligible) || (allowsRemovalOfLastSavedPaymentMethod && paymentMethodRemove)
                        let expected: RowButton.RightAccessoryButton.AccessoryType? = canEdit ? .edit : nil
                        let result = RowButton.RightAccessoryButton.getAccessoryButtonType(savedPaymentMethodsCount: 1,
                                                                                           isFirstCardCoBranded: isFirstCardCoBranded,
                                                                                           isCBCEligible: isCBCEligible,
                                                                                           allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                                                           paymentMethodRemove: paymentMethodRemove)
                        XCTAssertEqual(result, expected)
                    }
                }
            }
        }
    }
}
