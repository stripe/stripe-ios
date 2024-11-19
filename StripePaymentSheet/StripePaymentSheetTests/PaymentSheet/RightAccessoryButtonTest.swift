//
//  RightAccessoryButtonTest.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 5/31/24.
//

import Foundation
@_spi(STP) @testable import StripePaymentSheet
import XCTest

final class RightAccessoryButtonTest: XCTestCase {

    // MARK: No saved payment methods
    func testNil_Returned_When_NoSavedPaymentMethods() {
        // Regardless of any flags, if we have zero payment methods we should return nil

        // Iterating over all combinations of isFirstCardCoBranded, isCBCEligible, allowsRemovalOfLastSavedPaymentMethod, and paymentMethodRemove
        let booleans = [false, true]
        for isFirstCardCoBranded in booleans {
            for isCBCEligible in booleans {
                for allowsRemovalOfLastSavedPaymentMethod in booleans {
                    for allowsPaymentMethodRemoval in booleans {
                        let result = RowButton.RightAccessoryButton.getAccessoryButtonType(savedPaymentMethodsCount: 0,
                                                                                           isFirstCardCoBranded: isFirstCardCoBranded,
                                                                                           isCBCEligible: isCBCEligible,
                                                                                           allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                                                           allowsPaymentMethodRemoval: allowsPaymentMethodRemoval)
                        XCTAssertNil(result)
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
                    for allowsPaymentMethodRemoval in booleans {

                        // We should only show the edit button if it is update-able or removable
                        let canEdit = (isFirstCardCoBranded && isCBCEligible) || (allowsRemovalOfLastSavedPaymentMethod && allowsPaymentMethodRemoval)
                        let expected: RowButton.RightAccessoryButton.AccessoryType? = canEdit ? .edit : nil
                        let result = RowButton.RightAccessoryButton.getAccessoryButtonType(savedPaymentMethodsCount: 1,
                                                                                           isFirstCardCoBranded: isFirstCardCoBranded,
                                                                                           isCBCEligible: isCBCEligible,
                                                                                           allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                                                           allowsPaymentMethodRemoval: allowsPaymentMethodRemoval)
                        XCTAssertEqual(result, expected)
                    }
                }
            }
        }
    }

    // MARK: More than 1 saved payment method

    func testViewMore_Returned_When_SavedPaymentsGreaterThanOneRegardlessOfOtherValues() {
        // Regardless of any flags, if we have more than 1 payment method we should show the view more button

        // Iterating over all combinations of isFirstCardCoBranded, isCBCEligible, allowsRemovalOfLastSavedPaymentMethod, and paymentMethodRemove
        let booleans = [false, true]
        for isFirstCardCoBranded in booleans {
            for isCBCEligible in booleans {
                for allowsRemovalOfLastSavedPaymentMethod in booleans {
                    for allowsPaymentMethodRemoval in booleans {
                        let result = RowButton.RightAccessoryButton.getAccessoryButtonType(savedPaymentMethodsCount: 2,
                                                                                           isFirstCardCoBranded: isFirstCardCoBranded,
                                                                                           isCBCEligible: isCBCEligible,
                                                                                           allowsRemovalOfLastSavedPaymentMethod: allowsRemovalOfLastSavedPaymentMethod,
                                                                                           allowsPaymentMethodRemoval: allowsPaymentMethodRemoval)
                        XCTAssertEqual(result, .viewMoreChevron)
                    }
                }
            }
        }
    }
    
    func testViewMore_Returned_When_SavedPaymentsGreaterThanOne_FlatCheckmarkStyle() {
        let result = RowButton.RightAccessoryButton.getAccessoryButtonType(savedPaymentMethodsCount: 2,
                                                                           isFirstCardCoBranded: true,
                                                                           isCBCEligible: true,
                                                                           allowsRemovalOfLastSavedPaymentMethod: true,
                                                                           allowsPaymentMethodRemoval: true,
                                                                           isFlatCheckmarkStyle: true)
        XCTAssertEqual(result, .viewMore)
    }
}
