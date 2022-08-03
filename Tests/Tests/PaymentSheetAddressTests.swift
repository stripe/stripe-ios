//
//  PaymentSheetAddressTests.swift
//  StripeiOS Tests
//
//  Created by Nick Porter on 7/25/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest
@testable import Stripe

class PaymentSheetAddressTests: XCTestCase {
   
    func testEditDistanceEqualAddress() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: address), 0)
    }
    
    func testEditDistanceOneCharDiff() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "Sa Francisco", // One char diff here
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 1)
    }
    
    func testEditDistanceDifferentCity() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "Freemont",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 11)
    }
    
    func testEditDistanceMissingCityOriginal() {
        let address = PaymentSheet.Address(
            city: nil,
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 13)
    }
    
    func testEditDistanceMissingCityOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: nil,
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 13)
    }
    
    func testEditDistanceMissingCountryOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: nil,
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 2)
    }
    
    func testEditDistanceMissingCountryOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: nil,
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 2)
    }
    
    func testEditDistanceMissingLineOneOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: nil,
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 16)
    }
    
    func testEditDistanceMissingLineOneOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: nil,
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 16)
    }
    
    func testEditDistanceMissingLineTwoOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            line2: nil,
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            line2: "Apt. 112",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 8)
    }
    
    func testEditDistanceMissingLineTwoOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            line2: "Apt. 112",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            line2: nil,
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 8)
    }
    
    func testEditDistanceMissingPostalCodeOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: nil,
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 5)
    }
    
    func testEditDistanceMissingPostalCodeOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: nil,
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 5)
    }
    
    func testEditDistanceMissingStateOriginal() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: nil
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 10)
    }
    
    func testEditDistanceMissingStateOther() {
        let address = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: "California"
        )
        
        let otherAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "AT",
            line1: "510 Townsend St.",
            postalCode: "94102",
            state: nil
        )
        
        XCTAssertEqual(address.editDistance(from: otherAddress), 10)
    }


}
